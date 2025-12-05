'use client'

import { QRCodeSVG } from 'qrcode.react'
import { Copy, Download, Check } from 'lucide-react'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'

interface QRCodeDisplayProps {
  url: string
  size?: number
}

export function QRCodeDisplay({ url, size = 256 }: QRCodeDisplayProps) {
  const [copied, setCopied] = useState(false)

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
      canvas.width = size
      canvas.height = size
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
      <CardContent className="p-6 flex flex-col items-center space-y-4">
        <div className="p-4 bg-white rounded-xl shadow-inner">
          <QRCodeSVG
            id="qr-code-svg"
            value={url}
            size={size}
            level="H"
            includeMargin
            bgColor="#ffffff"
            fgColor="#000000"
          />
        </div>

        <div className="w-full space-y-2">
          <div className="flex items-center gap-2 p-3 bg-muted rounded-lg">
            <code className="text-xs flex-1 truncate">{url}</code>
          </div>

          <div className="flex gap-2">
            <Button
              variant="outline"
              className="flex-1"
              onClick={handleCopy}
            >
              {copied ? (
                <>
                  <Check className="h-4 w-4 mr-2 text-green-500" />
                  Copiado!
                </>
              ) : (
                <>
                  <Copy className="h-4 w-4 mr-2" />
                  Copiar Link
                </>
              )}
            </Button>
            <Button
              variant="outline"
              className="flex-1"
              onClick={handleDownload}
            >
              <Download className="h-4 w-4 mr-2" />
              Baixar PNG
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
