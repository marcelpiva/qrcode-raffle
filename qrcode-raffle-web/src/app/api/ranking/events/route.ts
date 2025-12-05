import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { normalizeEmail } from '@/lib/email'

// GET: Calculate ranking by selected events (aggregating all tracks via talks)
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const eventIds = searchParams.get('eventIds')?.split(',').filter(Boolean) || []

    // Get all available events with track counts (attendance via talks)
    const allEvents = await prisma.event.findMany({
      orderBy: { startDate: 'desc' },
      include: {
        tracks: {
          include: {
            talks: {
              include: {
                _count: { select: { attendances: true } }
              }
            }
          }
        },
        _count: { select: { tracks: true } }
      }
    })

    // Helper to calculate total attendances for an event
    const calcEventAttendances = (event: typeof allEvents[0]) =>
      event.tracks.reduce((sum, t) =>
        sum + t.talks.reduce((talkSum, talk) => talkSum + talk._count.attendances, 0), 0)

    if (eventIds.length === 0) {
      return NextResponse.json({
        events: allEvents.map(e => ({
          id: e.id,
          name: e.name,
          startDate: e.startDate.toISOString(),
          endDate: e.endDate.toISOString(),
          trackCount: e._count.tracks,
          totalAttendances: calcEventAttendances(e)
        })),
        selectedEvents: [],
        ranking: []
      })
    }

    // Get selected events with tracks and talks
    const selectedEvents = await prisma.event.findMany({
      where: { id: { in: eventIds } },
      orderBy: { startDate: 'desc' },
      include: {
        tracks: {
          include: {
            talks: {
              include: {
                _count: { select: { attendances: true } }
              }
            }
          }
        },
        _count: { select: { tracks: true } }
      }
    })

    // Get all talk IDs from selected events
    const talkIds = selectedEvents.flatMap(e =>
      e.tracks.flatMap(t => t.talks.map(talk => talk.id))
    )

    // Create maps for talk -> track -> event
    const talkToTrackEvent = new Map<string, { trackId: string; eventId: string }>()
    for (const event of selectedEvents) {
      for (const track of event.tracks) {
        for (const talk of track.talks) {
          talkToTrackEvent.set(talk.id, { trackId: track.id, eventId: event.id })
        }
      }
    }

    // Get all attendances from talks of selected events
    const attendances = await prisma.talkAttendance.findMany({
      where: { talkId: { in: talkIds } },
      select: { email: true, name: true, talkId: true }
    })

    // Group by normalized email, counting unique events and tracks participated
    const emailMap = new Map<string, {
      name: string
      originalEmail: string
      eventIds: Set<string>
      trackIds: Set<string>
    }>()

    for (const a of attendances) {
      const normalizedEmail = normalizeEmail(a.email)
      const mapping = talkToTrackEvent.get(a.talkId)
      if (!mapping) continue

      const existing = emailMap.get(normalizedEmail)
      if (existing) {
        existing.eventIds.add(mapping.eventId)
        existing.trackIds.add(mapping.trackId)
        existing.name = a.name
      } else {
        emailMap.set(normalizedEmail, {
          name: a.name,
          originalEmail: a.email,
          eventIds: new Set([mapping.eventId]),
          trackIds: new Set([mapping.trackId])
        })
      }
    }

    // Get total track count across selected events
    const totalTrackCount = selectedEvents.reduce((sum, e) => sum + e.tracks.length, 0)

    // Create ranking sorted by event participation
    const ranking = Array.from(emailMap.entries())
      .map(([normalizedEmail, data]) => ({
        email: data.originalEmail,
        normalizedEmail,
        name: data.name,
        eventsParticipated: data.eventIds.size,
        tracksParticipated: data.trackIds.size,
        totalEvents: selectedEvents.length,
        totalTracks: totalTrackCount,
        eventPercentage: Math.round((data.eventIds.size / selectedEvents.length) * 100),
        eventIds: Array.from(data.eventIds),
        trackIds: Array.from(data.trackIds)
      }))
      .sort((a, b) =>
        b.eventsParticipated - a.eventsParticipated ||
        b.tracksParticipated - a.tracksParticipated ||
        a.normalizedEmail.localeCompare(b.normalizedEmail)
      )

    return NextResponse.json({
      events: allEvents.map(e => ({
        id: e.id,
        name: e.name,
        startDate: e.startDate.toISOString(),
        endDate: e.endDate.toISOString(),
        trackCount: e._count.tracks,
        totalAttendances: calcEventAttendances(e)
      })),
      selectedEvents: selectedEvents.map(e => ({
        id: e.id,
        name: e.name,
        trackCount: e._count.tracks,
        totalAttendances: calcEventAttendances(e)
      })),
      ranking
    })
  } catch (error) {
    console.error('Error fetching event ranking:', error)
    return NextResponse.json({ error: 'Failed to fetch ranking' }, { status: 500 })
  }
}
