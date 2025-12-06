# QR Code Raffle

Sistema de sorteios com QR Code para eventos.

## Funcionalidades

### Gerenciamento de Eventos
- **Sistema de Eventos** - Criar e gerenciar eventos com múltiplas trilhas e palestras
- **Trilhas (Tracks)** - Organizar palestras por tema ou sala
- **Palestras (Talks)** - Cadastrar palestras com horários de início e fim
- **Presenças (Attendances)** - Registrar presenças via QR Code com duração (contagem única por e-mail)
- **Timeline Visual** - Visualização cronológica do evento
- **Import CSV** - Importação em massa de trilhas, palestras e presenças

### Tipos de Sorteio
- **Sorteio de Evento** - Participantes de todas as palestras com filtro de tempo mínimo
- **Sorteio de Palestra** - Via QR Code com auto-inscrição durante a palestra
- **Wizard de Criação** - Assistente em 3 passos para criar sorteios

### Funcionalidades de Sorteio
- Sorteio animado estilo slot machine
- Celebração do vencedor com confetti
- Painel administrativo protegido por senha
- Painel de exibição para projetar em tela (design grandioso para eventos)
- Filtro de domínio de e-mail por sorteio
- Atualização em tempo real dos participantes
- Re-sorteio quando ganhador está ausente
- Histórico de sorteios com participantes ausentes
- Reabrir sorteio finalizado
- Reabrir inscrições a qualquer momento
- **Timebox/Countdown** - Tempo limite para inscrições com encerramento automático
- **Countdown Duplo** - "Abre em" antes do início, "Encerra em" durante o período
- **Sorteio Automático** - Sortear automaticamente quando countdown termina
- **Código de confirmação (PIN)** - Ganhador confirma presença via código de 5 dígitos
- **Timeout de confirmação** - Re-sorteio automático se ganhador não confirmar presença
- **Export CSV** - Download de participantes e vencedor em formato CSV
- **Ranking de Participação** - Análise de engajamento em múltiplos sorteios
- **Sorteio por Engajamento** - Criar sorteio VIP com participantes mais engajados
- **Ações em Tempo Real** - Admin actions refletem imediatamente no display

## Tech Stack

- **Frontend:** Next.js 16, React 19, Tailwind CSS 4
- **Backend:** Next.js API Routes
- **Database:** PostgreSQL (Neon)
- **ORM:** Prisma
- **UI:** Radix UI, Framer Motion
- **Deploy:** AWS Lightsail ($3.50/mês)

## Desenvolvimento Local

### Pré-requisitos

- Node.js 18+
- npm ou yarn

### Instalação

```bash
# Clone o repositório
git clone https://github.com/marcelpiva-nava/nava-qr-code-raffle.git
cd nava-qr-code-raffle

# Instale as dependências
npm install

# Configure .env com DATABASE_URL do Neon PostgreSQL
# DATABASE_URL="postgresql://..."
# ADMIN_PASSWORD="sua-senha"

# Sincronize o schema com o banco
npm run db:push

# Inicie o servidor de desenvolvimento
npm run dev
```

Acesse http://localhost:3000

### Scripts Disponíveis

| Comando | Descrição |
|---------|-----------|
| `npm run dev` | Inicia o servidor de desenvolvimento |
| `npm run build` | Build para produção |
| `npm run start` | Inicia o servidor de produção |
| `npm run db:push` | Sincroniza schema com o banco |
| `npm run db:studio` | Abre Prisma Studio |
| `npm run seed` | Popula o banco com dados de teste |

## Configuração de Ambiente

### Variáveis de Ambiente

```env
# Banco de dados
DATABASE_URL="postgresql://..."

# Senha do painel admin
ADMIN_PASSWORD="sua-senha-aqui"
```

### Configuração do Banco

O projeto usa PostgreSQL (Neon) tanto para desenvolvimento quanto produção:

```bash
# Sincronizar schema
npm run db:push

# Abrir Prisma Studio
npm run db:studio
```

## Estrutura do Projeto

```
nava-qr-code-raffle/
├── prisma/
│   ├── schema.prisma          # Schema PostgreSQL
│   └── seed.ts                # Script de seed
├── src/
│   ├── app/
│   │   ├── admin/             # Painel administrativo
│   │   ├── display/           # Painel de exibição
│   │   ├── register/          # Registro de participantes
│   │   └── api/               # API Routes
│   ├── components/            # Componentes React
│   └── lib/                   # Utilitários
└── ...
```

## Páginas

| Rota | Descrição |
|------|-----------|
| `/admin` | Dashboard administrativo (requer senha) |
| `/admin/new` | Criar novo sorteio |
| `/admin/[id]` | Detalhes do sorteio |
| `/admin/[id]/draw` | Realizar sorteio com animação |
| `/admin/ranking` | Ranking de participação e sorteio por engajamento |
| `/register/[id]` | Página de registro (QR Code) |
| `/display/[id]` | Painel de exibição (projetar em tela) |
| `/confirm/[id]` | Confirmação de presença do vencedor (PIN) |

## API Endpoints

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/api/auth` | Autenticação admin |
| GET | `/api/auth` | Verifica sessão |
| GET | `/api/raffles` | Lista sorteios |
| POST | `/api/raffles` | Cria sorteio |
| GET | `/api/raffles/[id]` | Detalhes do sorteio |
| DELETE | `/api/raffles/[id]` | Remove sorteio |
| GET | `/api/raffles/[id]/participants` | Lista participantes |
| POST | `/api/raffles/[id]/draw` | Realiza sorteio |
| POST | `/api/raffles/[id]/confirm-winner` | Confirma presença do vencedor |
| POST | `/api/raffles/[id]/reopen` | Reabre sorteio finalizado |
| POST | `/api/register/[id]` | Registra participante |
| GET | `/api/register/[id]` | Info do sorteio |
| POST | `/api/raffles/[id]/confirm-pin` | Confirma presença via PIN |
| GET | `/api/raffles/[id]/export` | Exporta participantes em CSV |
| GET | `/api/raffles/ranking` | Ranking de participação |
| POST | `/api/raffles/create-from-ranking` | Cria sorteio por engajamento |
| GET | `/api/time` | Retorna hora do servidor (sync) |

## Deploy (AWS Lightsail)

O projeto usa AWS Lightsail para deploy (~$3.50/mês).

### Pré-requisitos

- AWS CLI configurado com perfil
- Node.js 18+

### Deploy

```bash
# Deploy completo (cria instância se não existir)
AWS_PROFILE=seu-perfil ./scripts/deploy-lightsail.sh
```

O script automaticamente:
1. Cria instância Lightsail (se não existir)
2. Abre portas 80, 443, 3000
3. Faz build do projeto
4. Envia para o servidor
5. Instala dependências e Prisma
6. Configura PM2 para gerenciar o processo
7. Instala Caddy como reverse proxy (porta 80 → 3000)

### Variáveis de Ambiente

O arquivo `.env` é criado automaticamente no servidor com:
- `DATABASE_URL` - PostgreSQL (Neon)
- `ADMIN_PASSWORD` - Senha do painel admin
- `NODE_ENV=production`
- `PORT=3000`

## Licença

MIT
