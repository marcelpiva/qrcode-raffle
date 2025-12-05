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
          orderBy: { createdAt: 'asc' }
        },
        winner: true,
        drawHistory: {
          include: { participant: true },
          orderBy: { drawNumber: 'asc' }
        }
      }
    })

    if (!raffle) {
      return NextResponse.json({ error: 'Raffle not found' }, { status: 404 })
    }

    // Build CSV content
    const BOM = '\uFEFF' // UTF-8 BOM for Excel compatibility
    const headers = [
      'Nome',
      'Email',
      'Data de Registro',
      'E Ganhador',
      'Premio',
      'Status do Sorteio',
      'Confirmou Presenca'
    ]

    // If requireConfirmation was enabled, add column
    if (raffle.requireConfirmation) {
      headers.push('Codigo Registrado')
    }

    const rows = raffle.participants.map(p => {
      const isWinner = raffle.winnerId === p.id
      const drawEntry = raffle.drawHistory.find(d => d.participantId === p.id)
      const wasPresent = drawEntry?.wasPresent ?? false

      const row = [
        escapeCsvField(p.name),
        escapeCsvField(p.email),
        formatDateBR(p.createdAt),
        isWinner ? 'Sim' : 'Nao',
        isWinner ? escapeCsvField(raffle.prize) : '',
        getStatusLabel(raffle.status),
        isWinner ? (wasPresent ? 'Sim' : 'Nao') : ''
      ]

      if (raffle.requireConfirmation) {
        // Don't expose actual PIN, just indicate if they have one
        row.push(p.pinHash ? 'Sim' : 'Nao')
      }

      return row.join(',')
    })

    const csvContent = BOM + headers.join(',') + '\n' + rows.join('\n')

    // Create response with proper headers
    return new NextResponse(csvContent, {
      status: 200,
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="${sanitizeFilename(raffle.name)}_participantes.csv"`,
        'Cache-Control': 'no-cache'
      }
    })
  } catch (error) {
    console.error('Error exporting CSV:', error)
    return NextResponse.json({ error: 'Failed to export CSV' }, { status: 500 })
  }
}

// Helper functions
function escapeCsvField(field: string): string {
  if (field.includes(',') || field.includes('"') || field.includes('\n')) {
    return `"${field.replace(/"/g, '""')}"`
  }
  return field
}

function formatDateBR(date: Date): string {
  return new Date(date).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

function getStatusLabel(status: string): string {
  switch (status) {
    case 'active': return 'Ativo'
    case 'closed': return 'Encerrado'
    case 'drawn': return 'Sorteado'
    default: return status
  }
}

function sanitizeFilename(name: string): string {
  return name.replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 50)
}
