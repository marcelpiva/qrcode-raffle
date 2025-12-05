import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
  try {
    const { password } = await request.json()
    const adminPassword = process.env.ADMIN_PASSWORD

    if (!adminPassword) {
      console.error('ADMIN_PASSWORD not configured in environment')
      return NextResponse.json({ error: 'Server configuration error' }, { status: 500 })
    }

    if (password === adminPassword) {
      const response = NextResponse.json({ success: true })

      // Set HTTP-only cookie for session
      // Note: For cross-origin requests (Flutter app), we need sameSite: 'none' and secure: true
      // But in development over HTTP, we use 'lax'
      const isProduction = process.env.NODE_ENV === 'production'
      response.cookies.set('admin_session', 'authenticated', {
        httpOnly: true,
        secure: isProduction,
        sameSite: isProduction ? 'strict' : 'lax',
        maxAge: 60 * 60 * 24, // 24 hours
        path: '/',
      })

      return response
    }

    return NextResponse.json({ error: 'Invalid password' }, { status: 401 })
  } catch (error) {
    console.error('Auth error:', error)
    return NextResponse.json({ error: 'Authentication failed' }, { status: 500 })
  }
}

export async function GET(request: NextRequest) {
  const session = request.cookies.get('admin_session')

  if (session?.value === 'authenticated') {
    return NextResponse.json({ authenticated: true })
  }

  return NextResponse.json({ authenticated: false }, { status: 401 })
}

export async function DELETE() {
  const response = NextResponse.json({ success: true })
  response.cookies.delete('admin_session')
  return response
}
