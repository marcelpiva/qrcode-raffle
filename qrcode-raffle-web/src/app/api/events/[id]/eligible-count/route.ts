import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: eventId } = await params
    const { searchParams } = new URL(request.url)

    // Filters
    const minDurationPerTalk = parseInt(searchParams.get('minDuration') || '0') // min minutes per talk
    const minTalksCount = parseInt(searchParams.get('minTalks') || '1') // min number of talks attended
    const allowedDomain = searchParams.get('domain') || null // domain filter (e.g., "nava.com.br")

    // Get all attendances for this event
    const attendances = await prisma.talkAttendance.findMany({
      where: {
        talk: {
          track: {
            eventId
          }
        }
      },
      select: {
        email: true,
        talkId: true,
        duration: true
      }
    })

    if (attendances.length === 0) {
      return NextResponse.json({
        eventId,
        minDurationPerTalk,
        minTalksCount,
        eligibleCount: 0,
        totalCount: 0,
        totalTalksWithAttendance: 0
      })
    }

    // Group by email -> talkId -> duration
    // Each email should have one entry per talk (constraint in DB)
    // But we'll aggregate just in case there are duplicates
    const emailTalkDurations: Map<string, Map<string, number>> = new Map()

    for (const attendance of attendances) {
      const email = attendance.email.toLowerCase()

      if (!emailTalkDurations.has(email)) {
        emailTalkDurations.set(email, new Map())
      }

      const talkMap = emailTalkDurations.get(email)!
      const currentDuration = talkMap.get(attendance.talkId) || 0
      talkMap.set(attendance.talkId, currentDuration + (attendance.duration || 0))
    }

    // Calculate eligibility
    // A person is eligible if they attended at least minTalksCount talks,
    // each with at least minDurationPerTalk minutes
    let eligibleCount = 0
    const totalCount = emailTalkDurations.size

    for (const [email, talkMap] of emailTalkDurations) {
      // Apply domain filter first if set
      if (allowedDomain) {
        const emailDomain = email.split('@')[1]?.toLowerCase()
        if (emailDomain !== allowedDomain.toLowerCase()) {
          continue
        }
      }

      // Count talks where person stayed >= minDurationPerTalk
      let qualifyingTalks = 0

      for (const [, duration] of talkMap) {
        if (duration >= minDurationPerTalk) {
          qualifyingTalks++
        }
      }

      // Person is eligible if they have enough qualifying talks
      if (qualifyingTalks >= minTalksCount) {
        eligibleCount++
      }
    }

    // Count unique talks with attendance
    const uniqueTalks = new Set(attendances.map(a => a.talkId))

    return NextResponse.json({
      eventId,
      minDurationPerTalk,
      minTalksCount,
      allowedDomain,
      eligibleCount,
      totalCount,
      totalTalksWithAttendance: uniqueTalks.size
    })
  } catch (error) {
    console.error('Error calculating eligible count:', error)
    return NextResponse.json({ error: 'Failed to calculate eligible count' }, { status: 500 })
  }
}
