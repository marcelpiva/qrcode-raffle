'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { ArrowLeft, Mail, Clock, KeyRound, Timer } from 'lucide-react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'

export default function NewRaffle() {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    prize: '',
    allowedDomain: '',
    timeboxMinutes: '',
    requireConfirmation: false,
    confirmationTimeoutMinutes: ''
  })

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const res = await fetch('/api/raffles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          timeboxMinutes: formData.timeboxMinutes ? parseInt(formData.timeboxMinutes) : null,
          confirmationTimeoutMinutes: formData.confirmationTimeoutMinutes ? parseInt(formData.confirmationTimeoutMinutes) : null
        })
      })

      if (res.ok) {
        const raffle = await res.json()
        router.push(`/admin/${raffle.id}`)
      }
    } catch (error) {
      console.error('Error creating raffle:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/admin">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-5 w-5" />
          </Button>
        </Link>
        <div>
          <h1 className="text-3xl font-bold">Novo Sorteio</h1>
          <p className="text-muted-foreground">Crie um novo sorteio com QR Code</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <Image
              src="/nava-icon.jpg"
              alt="Nava Logo"
              width={40}
              height={40}
              className="rounded-lg"
            />
            <div>
              <CardTitle>Informacoes do Sorteio</CardTitle>
              <CardDescription>Preencha os dados do seu sorteio</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="name">Nome do Sorteio *</Label>
              <Input
                id="name"
                placeholder="Ex: Sorteio de Natal 2024"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="prize">Premio *</Label>
              <Input
                id="prize"
                placeholder="Ex: iPhone 15 Pro Max"
                value={formData.prize}
                onChange={(e) => setFormData({ ...formData, prize: e.target.value })}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="description">Descricao (opcional)</Label>
              <Textarea
                id="description"
                placeholder="Descreva os detalhes do sorteio..."
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                rows={4}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="allowedDomain" className="flex items-center gap-2">
                <Mail className="h-4 w-4" />
                Dominio de E-mail Permitido (opcional)
              </Label>
              <Input
                id="allowedDomain"
                placeholder="Ex: nava.com.br"
                value={formData.allowedDomain}
                onChange={(e) => setFormData({ ...formData, allowedDomain: e.target.value })}
              />
              <p className="text-xs text-muted-foreground">
                Se preenchido, apenas e-mails com este dominio poderao participar
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="timeboxMinutes" className="flex items-center gap-2">
                <Clock className="h-4 w-4" />
                Tempo Limite (opcional)
              </Label>
              <select
                id="timeboxMinutes"
                value={formData.timeboxMinutes}
                onChange={(e) => setFormData({ ...formData, timeboxMinutes: e.target.value })}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              >
                <option value="">Sem limite de tempo</option>
                <option value="5">5 minutos</option>
                <option value="10">10 minutos</option>
                <option value="15">15 minutos</option>
                <option value="30">30 minutos</option>
                <option value="60">60 minutos</option>
              </select>
              <p className="text-xs text-muted-foreground">
                Se definido, as inscrições serão encerradas automaticamente após o tempo
              </p>
            </div>

            <div className="space-y-2">
              <div className="flex items-center space-x-2">
                <input
                  type="checkbox"
                  id="requireConfirmation"
                  checked={formData.requireConfirmation}
                  onChange={(e) => setFormData({ ...formData, requireConfirmation: e.target.checked, confirmationTimeoutMinutes: e.target.checked ? '2' : '' })}
                  className="h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
                />
                <Label htmlFor="requireConfirmation" className="flex items-center gap-2 cursor-pointer">
                  <KeyRound className="h-4 w-4" />
                  Exigir código de confirmação do ganhador
                </Label>
              </div>
              <p className="text-xs text-muted-foreground ml-6">
                Se ativado, participantes criarão um código de 5 dígitos ao se inscrever.
                O ganhador precisará digitar seu código para confirmar a presença.
              </p>
            </div>

            {formData.requireConfirmation && (
              <div className="space-y-2 ml-6 p-4 bg-muted/50 rounded-lg border">
                <Label htmlFor="confirmationTimeoutMinutes" className="flex items-center gap-2">
                  <Timer className="h-4 w-4" />
                  Tempo limite para confirmação
                </Label>
                <select
                  id="confirmationTimeoutMinutes"
                  value={formData.confirmationTimeoutMinutes}
                  onChange={(e) => setFormData({ ...formData, confirmationTimeoutMinutes: e.target.value })}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                >
                  <option value="1">1 minuto</option>
                  <option value="2">2 minutos</option>
                  <option value="3">3 minutos</option>
                  <option value="5">5 minutos</option>
                </select>
                <p className="text-xs text-muted-foreground">
                  Se o ganhador não confirmar dentro do tempo, um novo sorteio será feito automaticamente.
                </p>
              </div>
            )}

            <div className="flex gap-3 pt-4">
              <Link href="/admin" className="flex-1">
                <Button type="button" variant="outline" className="w-full">
                  Cancelar
                </Button>
              </Link>
              <Button
                type="submit"
                className="flex-1 bg-gradient-to-r from-primary to-secondary hover:opacity-90"
                disabled={loading || !formData.name || !formData.prize}
              >
                {loading ? 'Criando...' : 'Criar Sorteio'}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Preview */}
      {formData.name && (
        <Card className="border-dashed">
          <CardHeader>
            <CardTitle className="text-sm text-muted-foreground">Preview</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <h3 className="text-xl font-bold">{formData.name}</h3>
              {formData.prize && (
                <p className="text-primary font-medium">Premio: {formData.prize}</p>
              )}
              {formData.description && (
                <p className="text-muted-foreground text-sm">{formData.description}</p>
              )}
              {formData.allowedDomain && (
                <p className="text-sm flex items-center gap-1">
                  <Mail className="h-3 w-3" />
                  Apenas @{formData.allowedDomain}
                </p>
              )}
              {formData.timeboxMinutes && (
                <p className="text-sm flex items-center gap-1">
                  <Clock className="h-3 w-3" />
                  Tempo limite: {formData.timeboxMinutes} minutos
                </p>
              )}
              {formData.requireConfirmation && (
                <p className="text-sm flex items-center gap-1">
                  <KeyRound className="h-3 w-3" />
                  Confirmação por código ativada
                  {formData.confirmationTimeoutMinutes && ` (${formData.confirmationTimeoutMinutes} min)`}
                </p>
              )}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
