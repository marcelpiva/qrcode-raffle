import { createHash } from 'crypto'

// Simple hash for 5-digit PIN (not meant for passwords, just for basic verification)
export function hashPin(pin: string): string {
  return createHash('sha256').update(pin).digest('hex')
}

export function verifyPin(pin: string, hash: string): boolean {
  return hashPin(pin) === hash
}

export function isValidPin(pin: string): boolean {
  return /^\d{5}$/.test(pin)
}
