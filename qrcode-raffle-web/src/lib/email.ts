/**
 * Normaliza e-mail removendo . e _ da parte local (antes do @)
 *
 * Exemplos:
 * - fulano.algo@nava.com.br → fulanoalgo@nava.com.br
 * - fulano_algo@nava.com.br → fulanoalgo@nava.com.br
 * - Fulano.Algo@NAVA.com.br → fulanoalgo@nava.com.br
 *
 * Usado para identificar a mesma pessoa que se registrou
 * com variações de e-mail em diferentes sorteios.
 */
export function normalizeEmail(email: string): string {
  const [local, domain] = email.toLowerCase().split('@')
  if (!domain) return email.toLowerCase()
  const normalizedLocal = local.replace(/[._]/g, '')
  return `${normalizedLocal}@${domain}`
}
