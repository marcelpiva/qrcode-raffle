interface Attendee {
  name: string
  email: string
  entryTime?: Date
  exitTime?: Date
  duration?: number // em minutos
}

interface CsvParseResult {
  attendees: Attendee[]
  errors: string[]
  skippedRows: number
  filteredByDomain: number
  mergedDuplicates: number
}

interface ParseOptions {
  allowedDomain?: string | null // e.g., "nava.com.br"
}

// Simple email validation
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// Normalize name to Title Case (handles UPPER CASE and mixed case)
function normalizeName(name: string): string {
  return name
    .toLowerCase()
    .split(' ')
    .map(word => {
      // Keep small words lowercase (de, da, do, dos, das, e)
      const smallWords = ['de', 'da', 'do', 'dos', 'das', 'e']
      if (smallWords.includes(word)) {
        return word
      }
      // Capitalize first letter
      return word.charAt(0).toUpperCase() + word.slice(1)
    })
    .join(' ')
}

// Normalize email to lowercase
function normalizeEmail(email: string): string {
  return email.toLowerCase().trim()
}

// Check if email matches allowed domain
function matchesDomain(email: string, allowedDomain: string | null | undefined): boolean {
  if (!allowedDomain) return true // No filter, accept all
  const domain = email.split('@')[1]?.toLowerCase()
  return domain === allowedDomain.toLowerCase()
}

// Parse time string in various formats:
// - "08:30:00" or "08:30" (time only)
// - "12/04/25, 17:50:26" (date + time from Google Meet/Zoom exports)
// - "2025-04-12 17:50:26" (ISO-like datetime)
function parseTime(timeStr: string, baseDate?: Date): Date | undefined {
  if (!timeStr || timeStr.trim() === '') return undefined

  let cleanStr = timeStr.trim()

  // Remove surrounding quotes if present
  if ((cleanStr.startsWith('"') && cleanStr.endsWith('"')) ||
      (cleanStr.startsWith("'") && cleanStr.endsWith("'"))) {
    cleanStr = cleanStr.slice(1, -1)
  }

  // Check if it's a datetime format with comma (e.g., "12/04/25, 17:50:26")
  if (cleanStr.includes(',')) {
    const parts = cleanStr.split(',')
    if (parts.length >= 2) {
      // Take the time part (after the comma)
      cleanStr = parts[parts.length - 1].trim()
    }
  }

  // Check if it's a datetime format with space (e.g., "2025-04-12 17:50:26")
  if (cleanStr.includes(' ') && cleanStr.includes('-')) {
    const parts = cleanStr.split(' ')
    if (parts.length >= 2) {
      cleanStr = parts[parts.length - 1].trim()
    }
  }

  // Now parse the time part
  const timeParts = cleanStr.split(':')
  if (timeParts.length < 2) return undefined

  const hours = parseInt(timeParts[0], 10)
  const minutes = parseInt(timeParts[1], 10)
  const seconds = timeParts.length > 2 ? parseInt(timeParts[2], 10) : 0

  if (isNaN(hours) || isNaN(minutes)) return undefined

  const date = baseDate ? new Date(baseDate) : new Date()
  date.setHours(hours, minutes, seconds, 0)
  return date
}

// Calculate duration in minutes from time string like "01:30:00" or just return minutes
function parseDuration(durationStr: string): number | undefined {
  if (!durationStr || durationStr.trim() === '') return undefined

  const trimmed = durationStr.trim()

  // If it contains ":", treat as HH:MM:SS or HH:MM
  if (trimmed.includes(':')) {
    const parts = trimmed.split(':')
    const hours = parseInt(parts[0], 10) || 0
    const minutes = parseInt(parts[1], 10) || 0
    return hours * 60 + minutes
  }

  // Otherwise, try to parse as number (already in minutes)
  const num = parseInt(trimmed, 10)
  return isNaN(num) ? undefined : num
}

// Detect delimiter (pipe, comma, semicolon, tab)
function detectDelimiter(line: string): string {
  // Count occurrences of potential delimiters (outside of quoted strings)
  const unquoted = line.replace(/"[^"]*"/g, '') // Remove quoted content

  const counts = {
    '|': (unquoted.match(/\|/g) || []).length,
    ',': (unquoted.match(/,/g) || []).length,
    ';': (unquoted.match(/;/g) || []).length,
    '\t': (unquoted.match(/\t/g) || []).length,
  }

  // Return the most common delimiter
  let maxDelimiter = ','
  let maxCount = 0
  for (const [delimiter, count] of Object.entries(counts)) {
    if (count > maxCount) {
      maxCount = count
      maxDelimiter = delimiter
    }
  }

  return maxDelimiter
}

// Parse CSV line respecting quoted fields
function parseCsvLine(line: string, delimiter: string): string[] {
  const result: string[] = []
  let current = ''
  let inQuotes = false

  for (let i = 0; i < line.length; i++) {
    const char = line[i]

    if (char === '"') {
      // Toggle quote state
      inQuotes = !inQuotes
      current += char
    } else if (char === delimiter && !inQuotes) {
      // End of field
      result.push(current.trim())
      current = ''
    } else {
      current += char
    }
  }

  // Don't forget the last field
  result.push(current.trim())

  // Remove surrounding quotes from each field
  return result.map(field => {
    if (field.startsWith('"') && field.endsWith('"')) {
      return field.slice(1, -1)
    }
    return field
  })
}

// Merge attendees by email, summing durations and finding min entry / max exit
function mergeAttendeesByEmail(attendees: Attendee[]): { merged: Attendee[], mergedCount: number } {
  const emailMap = new Map<string, {
    name: string
    email: string
    entries: Date[]
    exits: Date[]
    totalDuration: number
  }>()

  for (const attendee of attendees) {
    const key = attendee.email.toLowerCase()
    const existing = emailMap.get(key)

    if (existing) {
      // Merge: add entry/exit times and accumulate duration
      if (attendee.entryTime) existing.entries.push(attendee.entryTime)
      if (attendee.exitTime) existing.exits.push(attendee.exitTime)

      if (attendee.duration) {
        existing.totalDuration += attendee.duration
      } else if (attendee.entryTime && attendee.exitTime) {
        // Calculate duration from this session
        const diffMs = attendee.exitTime.getTime() - attendee.entryTime.getTime()
        existing.totalDuration += Math.round(diffMs / 60000)
      }
    } else {
      let initialDuration = 0
      if (attendee.duration) {
        initialDuration = attendee.duration
      } else if (attendee.entryTime && attendee.exitTime) {
        const diffMs = attendee.exitTime.getTime() - attendee.entryTime.getTime()
        initialDuration = Math.round(diffMs / 60000)
      }

      emailMap.set(key, {
        name: attendee.name,
        email: attendee.email,
        entries: attendee.entryTime ? [attendee.entryTime] : [],
        exits: attendee.exitTime ? [attendee.exitTime] : [],
        totalDuration: initialDuration
      })
    }
  }

  const merged: Attendee[] = []
  let mergedCount = 0

  for (const [email, data] of emailMap.entries()) {
    // Check if this email had multiple rows
    const totalRows = Math.max(data.entries.length, data.exits.length)
    if (totalRows > 1) mergedCount++

    const result: Attendee = {
      name: data.name,
      email: data.email
    }

    // Use earliest entry time
    if (data.entries.length > 0) {
      result.entryTime = new Date(Math.min(...data.entries.map(d => d.getTime())))
    }

    // Use latest exit time
    if (data.exits.length > 0) {
      result.exitTime = new Date(Math.max(...data.exits.map(d => d.getTime())))
    }

    // Use accumulated duration
    if (data.totalDuration > 0) {
      result.duration = data.totalDuration
    }

    merged.push(result)
  }

  return { merged, mergedCount }
}

export function parseCsv(content: string, options: ParseOptions = {}): CsvParseResult {
  const rawAttendees: Attendee[] = []
  const errors: string[] = []
  let skippedRows = 0
  let filteredByDomain = 0

  // Split by newlines and filter empty lines
  const lines = content.split(/\r?\n/).filter(line => line.trim())

  if (lines.length === 0) {
    errors.push('Arquivo CSV vazio')
    return { attendees: [], errors, skippedRows, filteredByDomain, mergedDuplicates: 0 }
  }

  // Detect delimiter from header
  const delimiter = detectDelimiter(lines[0])

  // Parse header (use parseCsvLine to handle quoted fields)
  const headers = parseCsvLine(lines[0], delimiter).map(h => h.toLowerCase().trim())

  // Find column indices (support PT-BR and EN variations)
  const nameIndex = headers.findIndex(h =>
    h === 'name' || h === 'nome' || h === 'participante'
  )
  const emailIndex = headers.findIndex(h =>
    h === 'email' || h === 'e-mail'
  )
  const entryTimeIndex = headers.findIndex(h =>
    h.includes('entrada') || h === 'entry_time' || h === 'entry time' || h === 'check-in' || h === 'checkin' || h === 'horário de entrada'
  )
  const exitTimeIndex = headers.findIndex(h =>
    h.includes('saida') || h.includes('saída') || h === 'exit_time' || h === 'exit time' || h === 'check-out' || h === 'checkout' || h === 'horário de saída'
  )
  const durationIndex = headers.findIndex(h =>
    h.includes('dura') || h === 'duration' || h === 'tempo'
  )

  if (nameIndex === -1) {
    errors.push('Coluna "nome" ou "name" nao encontrada no header')
    return { attendees: [], errors, skippedRows, filteredByDomain, mergedDuplicates: 0 }
  }

  if (emailIndex === -1) {
    errors.push('Coluna "email" nao encontrada no header')
    return { attendees: [], errors, skippedRows, filteredByDomain, mergedDuplicates: 0 }
  }

  // Use today's date as base for time parsing
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  // Parse data rows
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim()
    if (!line) continue

    // Parse line respecting quoted fields
    const values = parseCsvLine(line, delimiter)

    // Extract and normalize name and email
    const rawName = values[nameIndex]?.trim()
    const rawEmail = values[emailIndex]?.trim()

    const name = rawName ? normalizeName(rawName) : ''
    const email = rawEmail ? normalizeEmail(rawEmail) : ''

    if (!name || !email) {
      skippedRows++
      continue
    }

    if (!isValidEmail(email)) {
      errors.push(`Linha ${i + 1}: Email invalido "${email}"`)
      skippedRows++
      continue
    }

    // Check domain filter
    if (!matchesDomain(email, options.allowedDomain)) {
      filteredByDomain++
      continue
    }

    const attendee: Attendee = { name, email }

    // Parse optional fields if present
    if (entryTimeIndex !== -1 && values[entryTimeIndex]) {
      attendee.entryTime = parseTime(values[entryTimeIndex], today)
    }

    if (exitTimeIndex !== -1 && values[exitTimeIndex]) {
      attendee.exitTime = parseTime(values[exitTimeIndex], today)
    }

    if (durationIndex !== -1 && values[durationIndex]) {
      attendee.duration = parseDuration(values[durationIndex])
    }

    // Calculate duration from entry/exit times if not provided
    if (!attendee.duration && attendee.entryTime && attendee.exitTime) {
      const diffMs = attendee.exitTime.getTime() - attendee.entryTime.getTime()
      attendee.duration = Math.round(diffMs / 60000) // Convert to minutes
    }

    rawAttendees.push(attendee)
  }

  // Merge duplicates by email
  const { merged, mergedCount } = mergeAttendeesByEmail(rawAttendees)

  return {
    attendees: merged,
    errors,
    skippedRows,
    filteredByDomain,
    mergedDuplicates: mergedCount
  }
}
