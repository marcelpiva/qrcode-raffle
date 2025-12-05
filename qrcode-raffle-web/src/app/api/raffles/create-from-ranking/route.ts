import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { normalizeEmail } from '@/lib/email'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, prize, description, sourceRaffleIds, minParticipation, requireAll } = body

    // Validações
    if (!name || !prize || !sourceRaffleIds?.length) {
      return NextResponse.json(
        { error: 'Nome, prêmio e sorteios fonte são obrigatórios' },
        { status: 400 }
      )
    }

    // Verificar que sorteios fonte estão finalizados
    const sourceRaffles = await prisma.raffle.findMany({
      where: {
        id: { in: sourceRaffleIds },
        status: 'drawn'
      }
    })

    if (sourceRaffles.length !== sourceRaffleIds.length) {
      return NextResponse.json(
        { error: 'Todos os sorteios fonte devem estar finalizados' },
        { status: 400 }
      )
    }

    // Buscar participantes dos sorteios fonte
    const participants = await prisma.participant.findMany({
      where: { raffleId: { in: sourceRaffleIds } },
      select: { email: true, name: true, raffleId: true }
    })

    // Agrupar por email normalizado e contar participações
    // fulano.algo@nava.com.br e fulano_algo@nava.com.br contam como a mesma pessoa
    const emailMap = new Map<string, { name: string; originalEmail: string; raffleIds: Set<string> }>()
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

    // Filtrar por critério de participação (usando contagem de sorteios únicos)
    const minRequired = requireAll ? sourceRaffleIds.length : (minParticipation || 1)
    const eligible = Array.from(emailMap.entries())
      .filter(([_, data]) => data.raffleIds.size >= minRequired)
      .map(([_, data]) => ({ email: data.originalEmail, name: data.name }))

    if (eligible.length === 0) {
      return NextResponse.json(
        { error: 'Nenhum participante atende aos critérios de participação' },
        { status: 400 }
      )
    }

    // Criar sorteio FECHADO com participantes (não aceita novas inscrições)
    const raffle = await prisma.raffle.create({
      data: {
        name,
        prize,
        description: description || null,
        status: 'closed', // Sorteio fechado - apenas participantes importados
        closedAt: new Date(),
        participants: {
          create: eligible.map(p => ({ email: p.email, name: p.name }))
        }
      },
      include: { _count: { select: { participants: true } } }
    })

    return NextResponse.json({
      raffle,
      participantsImported: eligible.length,
      message: `Sorteio criado com ${eligible.length} participantes`
    }, { status: 201 })
  } catch (error) {
    console.error('Error creating raffle from ranking:', error)
    return NextResponse.json(
      { error: 'Falha ao criar sorteio' },
      { status: 500 }
    )
  }
}
