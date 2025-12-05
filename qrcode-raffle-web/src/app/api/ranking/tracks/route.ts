import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { normalizeEmail } from '@/lib/email'

// GET: Calculate ranking by selected tracks (uses Talk attendance)
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const trackIds = searchParams.get('trackIds')?.split(',').filter(Boolean) || []

    // Get all available events with tracks and their talk attendance counts
    const allEvents = await prisma.event.findMany({
      orderBy: { startDate: 'desc' },
      include: {
        tracks: {
          orderBy: { startDate: 'asc' },
          include: {
            talks: {
              include: {
                _count: { select: { attendances: true } }
              }
            }
          }
        }
      }
    })

    // Calculate attendance count per track (sum of all talk attendances)
    const eventsWithCounts = allEvents.map(e => ({
      id: e.id,
      name: e.name,
      startDate: e.startDate.toISOString(),
      endDate: e.endDate.toISOString(),
      tracks: e.tracks.map(t => ({
        id: t.id,
        title: t.title,
        startDate: t.startDate.toISOString(),
        endDate: t.endDate.toISOString(),
        attendanceCount: t.talks.reduce((sum, talk) => sum + talk._count.attendances, 0)
      }))
    }))

    if (trackIds.length === 0) {
      return NextResponse.json({
        events: eventsWithCounts,
        selectedTracks: [],
        ranking: []
      })
    }

    // Get selected tracks info with their talks
    const selectedTracks = await prisma.track.findMany({
      where: { id: { in: trackIds } },
      orderBy: { startDate: 'asc' },
      include: {
        event: { select: { id: true, name: true } },
        talks: {
          include: {
            _count: { select: { attendances: true } }
          }
        }
      }
    })

    // Get talk IDs from selected tracks
    const talkIds = selectedTracks.flatMap(t => t.talks.map(talk => talk.id))

    // Get all attendances from talks in selected tracks
    const attendances = await prisma.talkAttendance.findMany({
      where: { talkId: { in: talkIds } },
      select: { email: true, name: true, talkId: true }
    })

    // Create a map from talkId to trackId for grouping
    const talkToTrack = new Map<string, string>()
    for (const track of selectedTracks) {
      for (const talk of track.talks) {
        talkToTrack.set(talk.id, track.id)
      }
    }

    // Group by normalized email, counting unique tracks participated
    const emailMap = new Map<string, {
      name: string
      originalEmail: string
      trackIds: Set<string>
    }>()

    for (const a of attendances) {
      const normalizedEmail = normalizeEmail(a.email)
      const trackId = talkToTrack.get(a.talkId)
      if (!trackId) continue

      const existing = emailMap.get(normalizedEmail)
      if (existing) {
        existing.trackIds.add(trackId)
        existing.name = a.name
      } else {
        emailMap.set(normalizedEmail, {
          name: a.name,
          originalEmail: a.email,
          trackIds: new Set([trackId])
        })
      }
    }

    // Create ranking sorted by participation
    const ranking = Array.from(emailMap.entries())
      .map(([normalizedEmail, data]) => ({
        email: data.originalEmail,
        normalizedEmail,
        name: data.name,
        participatedIn: data.trackIds.size,
        totalSelected: selectedTracks.length,
        percentage: Math.round((data.trackIds.size / selectedTracks.length) * 100),
        trackIds: Array.from(data.trackIds)
      }))
      .sort((a, b) => b.participatedIn - a.participatedIn || a.normalizedEmail.localeCompare(b.normalizedEmail))

    return NextResponse.json({
      events: eventsWithCounts,
      selectedTracks: selectedTracks.map(t => ({
        id: t.id,
        title: t.title,
        eventId: t.event.id,
        eventName: t.event.name,
        attendanceCount: t.talks.reduce((sum, talk) => sum + talk._count.attendances, 0)
      })),
      ranking
    })
  } catch (error) {
    console.error('Error fetching track ranking:', error)
    return NextResponse.json({ error: 'Failed to fetch ranking' }, { status: 500 })
  }
}
