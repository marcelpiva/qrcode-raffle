'use client'

import { useEffect, useState } from 'react'

export function VersionDisplay() {
  const [version, setVersion] = useState<string>('')
  const [buildTime, setBuildTime] = useState<string>('')

  useEffect(() => {
    // Fetch version from API
    fetch('/api/version')
      .then(res => res.json())
      .then(data => {
        setVersion(data.version || '0.0.0')
        setBuildTime(data.buildTime || new Date().toISOString())
      })
      .catch(() => {
        setVersion('0.0.0')
        setBuildTime(new Date().toISOString())
      })
  }, [])

  if (!version) return null

  const formattedDate = new Date(buildTime).toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })

  return (
    <div className="fixed bottom-2 right-2 text-[10px] text-muted-foreground/50 font-mono">
      v{version} • {formattedDate}
    </div>
  )
}
