import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const raffle = await prisma.raffle.findUnique({
      where: { id },
      include: {
        participants: {
          orderBy: { createdAt: 'desc' }
        },
        winner: true,
        drawHistory: {
          include: { participant: true },
          orderBy: { drawNumber: 'asc' }
        },
        _count: {
          select: { participants: true }
        }
      }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Raffle not found' }, { status: 404 })
    }

    return NextResponse.json(raffle)
  } catch (error) {
    console.error('Error fetching raffle:', error)
    return NextResponse.json({ error: 'Failed to fetch raffle' }, { status: 500 })
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const body = await request.json()
    const { status } = body

    // If reopening (setting to active), also clear any pending winner
    const updateData: Record<string, unknown> = {
      status,
      closedAt: status === 'closed' ? new Date() : undefined
    }

    if (status === 'active') {
      // Clear pending winner and endsAt when reopening
      updateData.winnerId = null
      updateData.endsAt = null
    }

    const raffle = await prisma.raffle.update({
      where: { id },
      data: updateData
    })

    return NextResponse.json(raffle)
  } catch (error) {
    console.error('Error updating raffle:', error)
    return NextResponse.json({ error: 'Failed to update raffle' }, { status: 500 })
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    await prisma.raffle.delete({
      where: { id }
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting raffle:', error)
    return NextResponse.json({ error: 'Failed to delete raffle' }, { status: 500 })
  }
}
