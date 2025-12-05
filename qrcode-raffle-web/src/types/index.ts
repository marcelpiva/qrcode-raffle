export type RaffleStatus = 'active' | 'closed' | 'drawn'

export interface Raffle {
  id: string
  name: string
  description: string | null
  prize: string
  status: RaffleStatus
  winnerId: string | null
  createdAt: Date
  closedAt: Date | null
  // Timebox feature
  timeboxMinutes: number | null
  endsAt: Date | null
  // PIN confirmation feature
  requireConfirmation: boolean
  allowedDomain: string | null
  participants?: Participant[]
  winner?: Participant | null
  _count?: {
    participants: number
  }
}

export interface Participant {
  id: string
  name: string
  email: string
  raffleId: string
  createdAt: Date
  pinHash?: string | null
}

export interface CreateRaffleInput {
  name: string
  description?: string
  prize: string
  allowedDomain?: string
  timeboxMinutes?: number
  requireConfirmation?: boolean
}

export interface RegisterParticipantInput {
  name: string
  email: string
  pin?: string
}
