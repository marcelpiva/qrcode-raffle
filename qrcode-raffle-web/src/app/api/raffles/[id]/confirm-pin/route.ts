import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { verifyPin, isValidPin } from '@/lib/pin'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    const body = await request.json()
    const { pin } = body

    if (!pin || !isValidPin(pin)) {
      return NextResponse.json(
        { error: 'Codigo invalido. Deve ter 5 digitos numericos.' },
        { status: 400 }
      )
    }

    // Get the raffle with current winner and latest draw
    const raffle = await prisma.raffle.findUnique({
      where: { id },
      include: {
        winner: true,
        drawHistory: {
          orderBy: { drawNumber: 'desc' },
          take: 1,
          include: { participant: true }
        }
      }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Sorteio nao encontrado' }, { status: 404 })
    }

    if (!raffle.requireConfirmation) {
      return NextResponse.json(
        { error: 'Este sorteio nao requer confirmacao por codigo' },
        { status: 400 }
      )
    }

    if (raffle.status === 'drawn') {
      return NextResponse.json(
        { error: 'Este sorteio ja foi finalizado' },
        { status: 400 }
      )
    }

    if (!raffle.winner || raffle.drawHistory.length === 0) {
      return NextResponse.json(
        { error: 'Nenhum sorteio foi realizado ainda' },
        { status: 400 }
      )
    }

    const winner = raffle.winner
    const lastDraw = raffle.drawHistory[0]

    // Verify the PIN belongs to the current winner
    if (!winner.pinHash) {
      return NextResponse.json(
        { error: 'Participante sem codigo de confirmacao' },
        { status: 400 }
      )
    }

    if (!verifyPin(pin, winner.pinHash)) {
      return NextResponse.json(
        { error: 'Codigo incorreto. Tente novamente.' },
        { status: 400 }
      )
    }

    // PIN matches! Confirm the winner
    const [updatedDrawHistory, updatedRaffle] = await prisma.$transaction([
      prisma.drawHistory.update({
        where: { id: lastDraw.id },
        data: { wasPresent: true },
        include: { participant: true }
      }),
      prisma.raffle.update({
        where: { id },
        data: { status: 'drawn' },
        include: {
          winner: true,
          participants: true,
          drawHistory: {
            include: { participant: true },
            orderBy: { drawNumber: 'asc' }
          }
        }
      })
    ])

    return NextResponse.json({
      success: true,
      message: 'Parabens! Sua presenca foi confirmada.',
      raffle: updatedRaffle,
      confirmedWinner: updatedDrawHistory.participant
    })
  } catch (error) {
    console.error('Error confirming winner by PIN:', error)
    return NextResponse.json({ error: 'Erro ao confirmar presenca' }, { status: 500 })
  }
}
