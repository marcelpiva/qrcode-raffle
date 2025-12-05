import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { normalizeEmail } from '@/lib/email'

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const raffleIds = searchParams.get('raffleIds')?.split(',').filter(Boolean) || []

    if (raffleIds.length === 0) {
      // Se nenhum sorteio selecionado, retornar lista de sorteios finalizados disponíveis
      const availableRaffles = await prisma.raffle.findMany({
        where: { status: 'drawn' },
        orderBy: { createdAt: 'desc' },
        include: {
          _count: { select: { participants: true } }
        }
      })

      return NextResponse.json({
        availableRaffles: availableRaffles.map(r => ({
          id: r.id,
          name: r.name,
          prize: r.prize,
          participantCount: r._count.participants,
          createdAt: r.createdAt
        })),
        selectedRaffles: [],
        ranking: []
      })
    }

    // Buscar sorteios selecionados (apenas finalizados)
    const raffles = await prisma.raffle.findMany({
      where: {
        id: { in: raffleIds },
        status: 'drawn'
      },
      orderBy: { createdAt: 'desc' },
      include: {
        _count: { select: { participants: true } }
      }
    })

    // Buscar todos sorteios finalizados disponíveis
    const availableRaffles = await prisma.raffle.findMany({
      where: { status: 'drawn' },
      orderBy: { createdAt: 'desc' },
      include: {
        _count: { select: { participants: true } }
      }
    })

    // Buscar todos participantes dos sorteios selecionados
    const participants = await prisma.participant.findMany({
      where: { raffleId: { in: raffleIds } },
      select: { email: true, name: true, raffleId: true }
    })

    // Agrupar por email normalizado
    // fulano.algo@nava.com.br e fulano_algo@nava.com.br contam como a mesma pessoa
    const emailMap = new Map<string, {
      name: string
      originalEmail: string  // Guarda um dos e-mails originais para exibicao
      raffleIds: Set<string>
    }>()

    for (const p of participants) {
      const normalizedEmail = normalizeEmail(p.email)
      const existing = emailMap.get(normalizedEmail)
      if (existing) {
        existing.raffleIds.add(p.raffleId)
        existing.name = p.name // Usa nome mais recente
      } else {
        emailMap.set(normalizedEmail, {
          name: p.name,
          originalEmail: p.email,
          raffleIds: new Set([p.raffleId])
        })
      }
    }

    // Criar ranking ordenado
    const ranking = Array.from(emailMap.entries())
      .map(([normalizedEmail, data]) => ({
        email: data.originalEmail,  // Exibe e-mail original
        normalizedEmail,            // E-mail normalizado para referencia
        name: data.name,
        participatedIn: data.raffleIds.size,
        totalSelected: raffles.length,
        percentage: Math.round((data.raffleIds.size / raffles.length) * 100),
        raffleIds: Array.from(data.raffleIds)
      }))
      .sort((a, b) => b.participatedIn - a.participatedIn || a.normalizedEmail.localeCompare(b.normalizedEmail))

    return NextResponse.json({
      availableRaffles: availableRaffles.map(r => ({
        id: r.id,
        name: r.name,
        prize: r.prize,
        participantCount: r._count.participants,
        createdAt: r.createdAt
      })),
      selectedRaffles: raffles.map(r => ({
        id: r.id,
        name: r.name,
        participantCount: r._count.participants
      })),
      ranking
    })
  } catch (error) {
    console.error('Error fetching ranking:', error)
    return NextResponse.json({ error: 'Failed to fetch ranking' }, { status: 500 })
  }
}
