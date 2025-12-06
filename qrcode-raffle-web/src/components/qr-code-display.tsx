'use client'

import { QRCodeSVG } from 'qrcode.react'
import { Copy, Download, Check } from 'lucide-react'
import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'

interface QRCodeDisplayProps {
  url: string
  size?: number
}

export function QRCodeDisplay({ url, size = 256 }: QRCodeDisplayProps) {
  const [copied, setCopied] = useState(false)
  const [qrSize, setQrSize] = useState(size)

  useEffect(() => {
    const updateSize = () => {
      // On mobile (< 640px), use smaller QR code
      setQrSize(window.innerWidth < 640 ? 180 : size)
    }
    updateSize()
    window.addEventListener('resize', updateSize)
    return () => window.removeEventListener('resize', updateSize)
  }, [size])

  const handleCopy = async () => {
    await navigator.clipboard.writeText(url)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  const handleDownload = () => {
    const svg = document.getElementById('qr-code-svg')
    if (!svg) return

    const svgData = new XMLSerializer().serializeToString(svg)
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')
    const img = new Image()

    img.onload = () => {
      canvas.width = qrSize
      canvas.height = qrSize
      ctx?.drawImage(img, 0, 0)
      const pngFile = canvas.toDataURL('image/png')
      const downloadLink = document.createElement('a')
      downloadLink.download = 'qrcode.png'
      downloadLink.href = pngFile
      downloadLink.click()
    }

    img.src = 'data:image/svg+xml;base64,' + btoa(svgData)
  }

  return (
    <Card className="overflow-hidden">
      <CardContent className="p-3 sm:p-6 flex flex-col items-center space-y-3 sm:space-y-4">
        <div className="p-2 sm:p-4 bg-white rounded-xl shadow-inner">
          <QRCodeSVG
            id="qr-code-svg"
            value={url}
            size={qrSize}
            level="H"
            includeMargin
            bgColor="#ffffff"
            fgColor="#000000"
          />
        </div>

        <div className="w-full space-y-2">
          <div className="flex items-center gap-2 p-2 sm:p-3 bg-muted rounded-lg overflow-hidden">
            <code className="text-[10px] sm:text-xs flex-1 truncate">{url}</code>
          </div>

          <div className="flex gap-2">
            <Button
              variant="outline"
              className="flex-1 text-xs sm:text-sm h-8 sm:h-10"
              onClick={handleCopy}
            >
              {copied ? (
                <>
                  <Check className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-2 text-green-500" />
                  <span className="hidden sm:inline">Copiado!</span>
                  <span className="sm:hidden">OK</span>
                </>
              ) : (
                <>
                  <Copy className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-2" />
                  <span className="hidden sm:inline">Copiar Link</span>
                  <span className="sm:hidden">Copiar</span>
                </>
              )}
            </Button>
            <Button
              variant="outline"
              className="flex-1 text-xs sm:text-sm h-8 sm:h-10"
              onClick={handleDownload}
            >
              <Download className="h-3 w-3 sm:h-4 sm:w-4 mr-1 sm:mr-2" />
              <span className="hidden sm:inline">Baixar PNG</span>
              <span className="sm:hidden">PNG</span>
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
