import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

export async function GET() {
  try {
    const raffles = await prisma.raffle.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: { participants: true }
        },
        winner: true
      }
    })
    return NextResponse.json(raffles)
  } catch (error) {
    console.error('Error fetching raffles:', error)
    return NextResponse.json({ error: 'Failed to fetch raffles' }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, description, prize, allowedDomain, timeboxMinutes, requireConfirmation, confirmationTimeoutMinutes } = body

    if (!name || !prize) {
      return NextResponse.json(
        { error: 'Name and prize are required' },
        { status: 400 }
      )
    }

    // Calculate endsAt if timeboxMinutes is provided
    let endsAt: Date | null = null
    if (timeboxMinutes && timeboxMinutes > 0) {
      endsAt = new Date(Date.now() + timeboxMinutes * 60 * 1000)
    }

    const raffle = await prisma.raffle.create({
      data: {
        name,
        description: description || null,
        prize,
        allowedDomain: allowedDomain || null,
        timeboxMinutes: timeboxMinutes || null,
        endsAt,
        requireConfirmation: requireConfirmation || false,
        confirmationTimeoutMinutes: confirmationTimeoutMinutes || null
      }
    })

    return NextResponse.json(raffle, { status: 201 })
  } catch (error) {
    console.error('Error creating raffle:', error)
    return NextResponse.json({ error: 'Failed to create raffle' }, { status: 500 })
  }
}
