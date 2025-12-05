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

### qrcode-raffle-web (Next.js)

Aplicacao web completa com:
- Painel administrativo para gerenciar sorteios
- Pagina de registro de participantes via QR Code
- Display para projetar em tela durante eventos
- Sorteio animado estilo slot machine
- Celebracao com confetti

**Tech Stack:** Next.js 16, React 19, Tailwind CSS 4, Prisma, PostgreSQL (Neon)

### qrcode-raffle-api (NestJS)

Backend API REST com:
- Autenticacao JWT
- Gerenciamento de sorteios e participantes
- Push notifications via Firebase
- Swagger/OpenAPI docs

**Tech Stack:** NestJS 11, Prisma, PostgreSQL, Firebase Admin

### qrcode-raffle-app (Flutter)

Aplicativo mobile com:
- Scanner de QR Code
- Notificacoes push
- Acompanhamento de sorteios em tempo real

**Tech Stack:** Flutter 3, Riverpod, Firebase Messaging

## Funcionalidades

- Criar e gerenciar sorteios
- QR Code para registro de participantes
- Sorteio animado estilo slot machine
- Celebracao do vencedor com confetti
- Painel administrativo protegido por senha
- Painel de exibicao para projetar em tela
- Filtro de dominio de e-mail por sorteio
- Atualizacao em tempo real dos participantes
- Re-sorteio quando ganhador esta ausente
- Historico de sorteios com participantes ausentes
- Reabrir sorteio finalizado
- Reabrir inscricoes a qualquer momento
- **Timebox/Countdown** - Tempo limite para inscricoes com encerramento automatico
- **Codigo de confirmacao (PIN)** - Ganhador confirma presenca via codigo de 5 digitos
- **Timeout de confirmacao** - Re-sorteio automatico se ganhador nao confirmar presenca
- **Export CSV** - Download de participantes e vencedor em formato CSV
- **Ranking de Participacao** - Analise de engajamento em multiplos sorteios
- **Sorteio por Engajamento** - Criar sorteio VIP com participantes mais engajados

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

## Deploy

- **Web:** AWS Lightsail (~$3.50/mes)
- **API:** AWS Lightsail ou container
- **App:** App Store / Google Play

## Licenca

MIT
