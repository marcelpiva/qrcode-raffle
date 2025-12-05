import { NextResponse } from 'next/server'
import { readFileSync, statSync } from 'fs'
import { join } from 'path'

export async function GET() {
  try {
    // Read version from VERSION file
    const versionPath = join(process.cwd(), 'VERSION')
    let version = '0.0.0'
    let buildTime = new Date().toISOString()

    try {
      version = readFileSync(versionPath, 'utf-8').trim()
      const stats = statSync(versionPath)
      buildTime = stats.mtime.toISOString()
    } catch {
      // Fallback to package.json version
      try {
        const packagePath = join(process.cwd(), 'package.json')
        const pkg = JSON.parse(readFileSync(packagePath, 'utf-8'))
        version = pkg.version || '0.0.0'
      } catch {
        // Use defaults
      }
    }

    return NextResponse.json({
      version,
      buildTime
    })
  } catch {
    return NextResponse.json({
      version: '0.0.0',
      buildTime: new Date().toISOString()
    })
  }
}
