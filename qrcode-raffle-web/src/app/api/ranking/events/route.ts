import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { normalizeEmail } from '@/lib/email'

// GET: Calculate ranking by selected events (aggregating all tracks via talks)
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const eventIds = searchParams.get('eventIds')?.split(',').filter(Boolean) || []

    // Get all available events with track counts
    const allEvents = await prisma.event.findMany({
      orderBy: { startDate: 'desc' },
      include: {
        tracks: {
          include: {
            talks: {
              select: { id: true }
            }
          }
        },
        _count: { select: { tracks: true } }
      }
    })

    // Get all talk IDs to fetch attendances for unique email counting
    const allTalkIds = allEvents.flatMap(e =>
      e.tracks.flatMap(t => t.talks.map(talk => talk.id))
    )

    // Fetch all attendances
    const allAttendances = await prisma.talkAttendance.findMany({
      where: { talkId: { in: allTalkIds } },
      select: { email: true, talkId: true }
    })

    // Create a map from talkId to eventId
    const talkToEventMap = new Map<string, string>()
    for (const event of allEvents) {
      for (const track of event.tracks) {
        for (const talk of track.talks) {
          talkToEventMap.set(talk.id, event.id)
        }
      }
    }

    // Count unique emails per event
    const eventUniqueEmails = new Map<string, Set<string>>()
    for (const a of allAttendances) {
      const eventId = talkToEventMap.get(a.talkId)
      if (!eventId) continue

      const normalizedEmail = normalizeEmail(a.email)
      if (!eventUniqueEmails.has(eventId)) {
        eventUniqueEmails.set(eventId, new Set())
      }
      eventUniqueEmails.get(eventId)!.add(normalizedEmail)
    }

    if (eventIds.length === 0) {
      return NextResponse.json({
        events: allEvents.map(e => ({
          id: e.id,
          name: e.name,
          startDate: e.startDate.toISOString(),
          endDate: e.endDate.toISOString(),
          trackCount: e._count.tracks,
          totalAttendances: eventUniqueEmails.get(e.id)?.size || 0
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
              select: { id: true }
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
        totalAttendances: eventUniqueEmails.get(e.id)?.size || 0
      })),
      selectedEvents: selectedEvents.map(e => ({
        id: e.id,
        name: e.name,
        trackCount: e._count.tracks,
        totalAttendances: eventUniqueEmails.get(e.id)?.size || 0
      })),
      ranking
    })
  } catch (error) {
    console.error('Error fetching event ranking:', error)
    return NextResponse.json({ error: 'Failed to fetch ranking' }, { status: 500 })
  }
}
