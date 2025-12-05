import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { parseCsv } from '@/lib/csv'

// GET: List attendances for a talk
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const talk = await prisma.talk.findUnique({
      where: { id },
      include: {
        attendances: {
          orderBy: { name: 'asc' }
        },
        _count: {
          select: { attendances: true }
        }
      }
    })

    if (!talk) {
      return NextResponse.json({ error: 'Talk not found' }, { status: 404 })
    }

    return NextResponse.json({
      talkId: talk.id,
      talkTitle: talk.title,
      attendanceCount: talk._count.attendances,
      attendances: talk.attendances.map(a => ({
        id: a.id,
        name: a.name,
        email: a.email,
        entryTime: a.entryTime?.toISOString() || null,
        exitTime: a.exitTime?.toISOString() || null,
        duration: a.duration,
        createdAt: a.createdAt.toISOString()
      }))
    })
  } catch (error) {
    console.error('Error fetching attendances:', error)
    return NextResponse.json({ error: 'Failed to fetch attendances' }, { status: 500 })
  }
}

// POST: Import CSV attendances for a talk
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    // Verify talk exists
    const talk = await prisma.talk.findUnique({ where: { id } })
    if (!talk) {
      return NextResponse.json({ error: 'Talk not found' }, { status: 404 })
    }

    const formData = await request.formData()
    const file = formData.get('file') as File

    if (!file) {
      return NextResponse.json(
        { error: 'Arquivo CSV é obrigatório' },
        { status: 400 }
      )
    }

    // Read and parse CSV
    const csvContent = await file.text()
    const { attendees, errors, skippedRows } = parseCsv(csvContent)

    if (attendees.length === 0) {
      return NextResponse.json(
        { error: 'Nenhum participante válido encontrado no CSV', details: errors },
        { status: 400 }
      )
    }

    // Import attendances with all fields
    const result = await prisma.talkAttendance.createMany({
      data: attendees.map(a => ({
        talkId: id,
        name: a.name,
        email: a.email,
        entryTime: a.entryTime,
        exitTime: a.exitTime,
        duration: a.duration
      })),
      skipDuplicates: true
    })

    // Get updated count
    const updatedTalk = await prisma.talk.findUnique({
      where: { id },
      include: {
        _count: { select: { attendances: true } }
      }
    })

    return NextResponse.json({
      talkId: id,
      attendeesImported: result.count,
      totalAttendees: updatedTalk?._count.attendances || result.count,
      skippedRows,
      errors: errors.slice(0, 5),
      message: `${result.count} presenças importadas com sucesso`
    }, { status: 201 })
  } catch (error) {
    console.error('Error importing attendances:', error)
    return NextResponse.json({ error: 'Failed to import attendances' }, { status: 500 })
  }
}

// DELETE: Clear all attendances for a talk
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params

    const talk = await prisma.talk.findUnique({ where: { id } })
    if (!talk) {
      return NextResponse.json({ error: 'Talk not found' }, { status: 404 })
    }

    const result = await prisma.talkAttendance.deleteMany({
      where: { talkId: id }
    })

    return NextResponse.json({
      success: true,
      deletedCount: result.count
    })
  } catch (error) {
    console.error('Error deleting attendances:', error)
    return NextResponse.json({ error: 'Failed to delete attendances' }, { status: 500 })
  }
}
