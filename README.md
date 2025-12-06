# QR Code Raffle

Sistema completo de sorteios com QR Code para eventos, composto por aplicacao web, API backend e aplicativo mobile.

## Arquitetura

```
qrcode-raffle/
├── qrcode-raffle-web/   # Frontend Next.js (painel admin + display)
├── qrcode-raffle-api/   # Backend NestJS (API REST)
└── qrcode-raffle-app/   # App Flutter (mobile)
```

## Componentes

### qrcode-raffle-web (Next.js) - v2.0.0

Aplicacao web completa com:
- **Sistema de Eventos** - Gerenciamento de eventos com trilhas e palestras
- **Painel Administrativo** - Dashboard para gerenciar sorteios, eventos, trilhas e palestras
- **Pagina de Registro** - Inscricao de participantes via QR Code
- **Display para Projecao** - Tela para exibir durante eventos com design grandioso
- **Sorteio Animado** - Estilo slot machine com celebracao confetti
- **Wizard de Criacao** - Assistente em 3 passos para criar sorteios
- **Import CSV** - Importacao em massa de trilhas, palestras e presencas

**Tech Stack:** Next.js 16, React 19, Tailwind CSS 4, Prisma, PostgreSQL (Neon), Radix UI, Framer Motion

### qrcode-raffle-api (NestJS) - v0.0.1

Backend API REST com:
- Autenticacao JWT com Passport
- Gerenciamento de usuarios e tokens
- Push notifications via Firebase Admin
- Documentacao Swagger/OpenAPI

**Tech Stack:** NestJS 11, Prisma, PostgreSQL, Firebase Admin, JWT

### qrcode-raffle-app (Flutter) - v2.0.0

Aplicativo mobile completo com:
- **Sistema de Eventos** - Criar e gerenciar eventos com trilhas e palestras
- **Event Wizard** - Assistente em 3 passos para criar eventos completos
- **Registro de Presencas** - Via QR Code com duracao calculada
- **Ranking de Participacao** - Visualizar engajamento por evento/trilha
- **Display em Tempo Real** - Exibicao para projecao durante eventos
- **Sorteios Animados** - Slot machine com celebracao confetti
- **UX Moderno** - Navegacao por telas (sem dialogs), animacoes fluidas
- **Tema Claro/Escuro** - Suporte completo a dark mode
- **Notificacoes Push** - Via Firebase Cloud Messaging

**Tech Stack:** Flutter 3, Riverpod, GoRouter, Firebase Messaging, Dio, flutter_animate, confetti

## Funcionalidades

### Gerenciamento de Eventos
- Criar e gerenciar eventos com datas de inicio e fim
- **Trilhas (Tracks)** - Organizar palestras por tema ou sala
- **Palestras (Talks)** - Cadastrar palestras com horarios e palestrantes
- **Presencas (Attendances)** - Registrar presencas via QR Code com duracao calculada
- **Timeline Visual** - Visualizacao cronologica do evento
- **Import CSV** - Importacao em massa de dados

### Tipos de Sorteio
- **Sorteio de Evento** - Participantes de todas as palestras com filtro de tempo minimo
- **Sorteio de Palestra** - Via QR Code com auto-inscricao durante a palestra
- **Sorteio por Engajamento** - Criar sorteio VIP com participantes mais engajados

### Funcionalidades de Sorteio
- Sorteio animado estilo slot machine
- Celebracao do vencedor com confetti
- Painel administrativo protegido por senha
- Display para projecao com design grandioso para eventos
- Filtro de dominio de e-mail por sorteio
- Atualizacao em tempo real dos participantes
- Re-sorteio quando ganhador esta ausente
- Historico de sorteios com participantes ausentes
- Reabrir sorteio finalizado
- Reabrir inscricoes a qualquer momento
- **Timebox/Countdown** - Tempo limite para inscricoes com encerramento automatico
- **Countdown Duplo** - "Abre em" antes do inicio, "Encerra em" durante o periodo
- **Sorteio Automatico** - Sortear automaticamente quando countdown termina
- **Codigo de confirmacao (PIN)** - Ganhador confirma presenca via codigo de 5 digitos
- **Timeout de confirmacao** - Re-sorteio automatico se ganhador nao confirmar presenca
- **Export CSV** - Download de participantes e vencedor em formato CSV
- **Ranking de Participacao** - Analise de engajamento em multiplos sorteios
- **Acoes em Tempo Real** - Admin actions refletem imediatamente no display

## Quick Start

### Web (Next.js)

```bash
cd qrcode-raffle-web
npm install
npm run dev
```

Acesse http://localhost:3000

### API (NestJS)

```bash
cd qrcode-raffle-api
npm install
npm run start:dev
```

API disponivel em http://localhost:3001

### App (Flutter)

```bash
cd qrcode-raffle-app
flutter pub get
flutter run
```

## Desenvolvimento

### Pre-requisitos

- Node.js 18+
- Flutter SDK 3.10+
- PostgreSQL (ou Neon para cloud)

### Configuracao

Cada subprojeto tem seu proprio `.env.example`. Copie e configure as variaveis necessarias:

```bash
# Web
cp qrcode-raffle-web/.env.example qrcode-raffle-web/.env.local

# API
cp qrcode-raffle-api/.env.example qrcode-raffle-api/.env
```

### Variaveis de Ambiente (Web)

```env
# Banco de dados PostgreSQL (Neon)
DATABASE_URL="postgresql://..."

# Senha do painel admin
ADMIN_PASSWORD="sua-senha-aqui"
```

## Paginas (Web)

| Rota | Descricao |
|------|-----------|
| `/` | Landing page publica |
| `/admin` | Dashboard administrativo (requer senha) |
| `/admin/[id]` | Detalhes do sorteio |
| `/admin/[id]/draw` | Realizar sorteio com animacao |
| `/admin/events` | Gerenciar eventos |
| `/admin/events/[id]` | Detalhes do evento (trilhas e palestras) |
| `/admin/ranking` | Ranking de participacao e sorteio por engajamento |
| `/register/[id]` | Pagina de registro (QR Code) |
| `/display/[id]` | Painel de exibicao (projetar em tela) |
| `/confirm/[id]` | Confirmacao de presenca do vencedor (PIN) |

## API Endpoints (Web)

### Autenticacao
| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| POST | `/api/auth` | Autenticacao admin |
| GET | `/api/auth` | Verifica sessao |

### Sorteios
| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| GET | `/api/raffles` | Lista sorteios |
| POST | `/api/raffles` | Cria sorteio |
| GET | `/api/raffles/[id]` | Detalhes do sorteio |
| PATCH | `/api/raffles/[id]` | Atualiza sorteio |
| DELETE | `/api/raffles/[id]` | Remove sorteio |
| GET | `/api/raffles/[id]/participants` | Lista participantes |
| POST | `/api/raffles/[id]/draw` | Realiza sorteio |
| POST | `/api/raffles/[id]/confirm-winner` | Confirma presenca do vencedor |
| POST | `/api/raffles/[id]/confirm-pin` | Confirma presenca via PIN |
| POST | `/api/raffles/[id]/reopen` | Reabre sorteio finalizado |
| GET | `/api/raffles/[id]/export` | Exporta participantes em CSV |
| GET | `/api/raffles/ranking` | Ranking de participacao |
| POST | `/api/raffles/create-from-ranking` | Cria sorteio por engajamento |

### Eventos
| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| GET | `/api/events` | Lista eventos |
| POST | `/api/events` | Cria evento |
| GET | `/api/events/[id]` | Detalhes do evento |
| PATCH | `/api/events/[id]` | Atualiza evento |
| DELETE | `/api/events/[id]` | Remove evento |
| GET | `/api/events/[id]/eligible-count` | Contagem de participantes elegiveis |

### Trilhas
| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| POST | `/api/tracks` | Cria trilha |
| GET | `/api/tracks/[id]` | Detalhes da trilha |
| PATCH | `/api/tracks/[id]` | Atualiza trilha |
| DELETE | `/api/tracks/[id]` | Remove trilha |

### Palestras
| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| POST | `/api/talks` | Cria palestra |
| GET | `/api/talks/[id]` | Detalhes da palestra |
| PATCH | `/api/talks/[id]` | Atualiza palestra |
| DELETE | `/api/talks/[id]` | Remove palestra |
| GET | `/api/talks/[id]/attendance` | Lista presencas |
| POST | `/api/talks/[id]/attendance` | Registra presenca |
| DELETE | `/api/talks/[id]/attendance/[attendanceId]` | Remove presenca |

### Ranking
| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| GET | `/api/ranking/events` | Lista eventos para ranking |
| GET | `/api/ranking/tracks` | Lista trilhas de um evento |
| POST | `/api/ranking/create-raffle` | Cria sorteio a partir do ranking |

### Utilitarios
| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| POST | `/api/register/[id]` | Registra participante |
| GET | `/api/register/[id]` | Info do sorteio para registro |
| GET | `/api/time` | Hora do servidor (sync) |
| GET | `/api/version` | Versao da aplicacao |

## Deploy

- **Web:** AWS Lightsail (~$3.50/mes) com Caddy como reverse proxy
- **API:** AWS Lightsail ou container
- **App:** App Store / Google Play

## Licenca

MIT
