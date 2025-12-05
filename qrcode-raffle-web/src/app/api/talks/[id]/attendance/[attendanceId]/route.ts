import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

// DELETE: Remove a single attendance
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string; attendanceId: string }> }
) {
  try {
    const { id: talkId, attendanceId } = await params

    // Verify talk exists
    const talk = await prisma.talk.findUnique({ where: { id: talkId } })
    if (!talk) {
      return NextResponse.json({ error: 'Talk not found' }, { status: 404 })
    }

    // Verify attendance exists and belongs to this talk
    const attendance = await prisma.talkAttendance.findFirst({
      where: { id: attendanceId, talkId }
    })

    if (!attendance) {
      return NextResponse.json({ error: 'Attendance not found' }, { status: 404 })
    }

    await prisma.talkAttendance.delete({
      where: { id: attendanceId }
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting attendance:', error)
    return NextResponse.json({ error: 'Failed to delete attendance' }, { status: 500 })
  }
}
