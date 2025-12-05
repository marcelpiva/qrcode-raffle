'use client'

import { useState, useRef } from 'react'
import { Upload, FileText, Loader2, AlertCircle, CheckCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'

interface TalkCsvUploadDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  talkId: string
  onSuccess: () => void
}

export function TalkCsvUploadDialog({ open, onOpenChange, talkId, onSuccess }: TalkCsvUploadDialogProps) {
  const [file, setFile] = useState<File | null>(null)
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [result, setResult] = useState<{
    attendeesImported: number
    totalAttendees: number
    errors: string[]
  } | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const resetForm = () => {
    setFile(null)
    setError(null)
    setResult(null)
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  const handleClose = () => {
    if (!uploading) {
      resetForm()
      onOpenChange(false)
    }
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0]
    if (selectedFile) {
      if (!selectedFile.name.endsWith('.csv')) {
        setError('Por favor, selecione um arquivo CSV')
        return
      }
      setFile(selectedFile)
      setError(null)
      setResult(null)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!file) {
      setError('Selecione um arquivo CSV')
      return
    }

    setUploading(true)
    setError(null)
    setResult(null)

    try {
      const formData = new FormData()
      formData.append('file', file)

      const res = await fetch(`/api/talks/${talkId}/attendance`, {
        method: 'POST',
        body: formData,
      })

      const data = await res.json()

      if (!res.ok) {
        throw new Error(data.error || 'Erro ao importar presenças')
      }

      setResult({
        attendeesImported: data.attendeesImported,
        totalAttendees: data.totalAttendees,
        errors: data.errors || []
      })

      onSuccess()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao importar presenças')
    } finally {
      setUploading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Upload className="h-5 w-5" />
            Importar Presenças
          </DialogTitle>
          <DialogDescription>
            Importe um arquivo CSV com a lista de presenças da palestra
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="csvFile" className="flex items-center gap-2">
              <FileText className="h-4 w-4" />
              Arquivo CSV *
            </Label>
            <Input
              ref={fileInputRef}
              id="csvFile"
              type="file"
              accept=".csv"
              onChange={handleFileChange}
              disabled={uploading}
              className="cursor-pointer"
            />
            <div className="text-xs text-muted-foreground space-y-1">
              <p>Formato suportado: delimitador <code className="bg-muted px-1 rounded">|</code>, <code className="bg-muted px-1 rounded">,</code> ou <code className="bg-muted px-1 rounded">;</code></p>
              <p>Colunas: <span className="font-medium">Nome</span> e <span className="font-medium">Email</span> (obrigatórias)</p>
              <p>Opcionais: <span className="text-muted-foreground">Horário de Entrada, Horário de Saída, Duração</span></p>
            </div>
          </div>

          {file && !result && (
            <div className="p-3 rounded-lg bg-muted/50 border text-sm">
              <div className="flex items-center gap-2">
                <FileText className="h-4 w-4 text-muted-foreground" />
                <span className="font-medium">{file.name}</span>
                <span className="text-muted-foreground">
                  ({(file.size / 1024).toFixed(1)} KB)
                </span>
              </div>
            </div>
          )}

          {result && (
            <div className="p-4 rounded-lg bg-green-500/10 border border-green-500/20 text-sm">
              <div className="flex items-center gap-2 text-green-600 mb-2">
                <CheckCircle className="h-4 w-4" />
                <span className="font-medium">Importação concluída!</span>
              </div>
              <ul className="text-muted-foreground space-y-1">
                <li>Presenças importadas: {result.attendeesImported}</li>
                <li>Total de presenças: {result.totalAttendees}</li>
              </ul>
              {result.errors.length > 0 && (
                <div className="mt-2 pt-2 border-t border-green-500/20">
                  <p className="text-xs text-muted-foreground">
                    {result.errors.length} linha(s) ignorada(s)
                  </p>
                </div>
              )}
            </div>
          )}

          {error && (
            <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20 text-sm text-destructive flex items-center gap-2">
              <AlertCircle className="h-4 w-4" />
              {error}
            </div>
          )}

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={handleClose}
              disabled={uploading}
            >
              {result ? 'Fechar' : 'Cancelar'}
            </Button>
            {!result && (
              <Button type="submit" disabled={uploading || !file}>
                {uploading ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Importando...
                  </>
                ) : (
                  <>
                    <Upload className="h-4 w-4 mr-2" />
                    Importar
                  </>
                )}
              </Button>
            )}
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
