# Changelog

Todas as mudancas notaveis neste projeto serao documentadas neste arquivo.

O formato e baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.0.0] - 2025-12-05

### Adicionado

- **Sistema de Eventos Completo**
  - Gerenciamento de eventos com trilhas e palestras
  - Presenças por palestra com duração calculada
  - Timeline visual do evento
  - Import CSV para trilhas, palestras e presenças
- **Tipos de Sorteio**
  - Sorteio de Evento (participantes de todas palestras)
  - Sorteio de Palestra (via QR Code)
- **Wizard de Criação** - Assistente em 3 passos
- **Countdown Duplo** - "Abre em" / "Encerra em"
- **Sorteio Automático** ao fim do countdown
- **Display Grandioso** para sorteios de evento
- **Ações em Tempo Real** - Display reflete admin actions

---

## [1.0.0] - 2025-12-05

### Adicionado

- **Estrutura Monorepo** - Organizacao do projeto em 3 componentes
  - `qrcode-raffle-web` - Frontend Next.js 16 com React 19
  - `qrcode-raffle-api` - Backend NestJS 11 com Prisma
  - `qrcode-raffle-app` - Aplicativo Flutter 3 com Riverpod
- **Web (v1.5.3)**
  - Sistema completo de sorteios com QR Code
  - Painel administrativo protegido por senha
  - Painel de exibicao para projetar em tela
  - Sorteio animado estilo slot machine
  - Celebracao com confetti
  - Timebox/Countdown para inscricoes
  - Codigo de confirmacao (PIN) para vencedor
  - Export CSV de participantes
  - Ranking de participacao
  - Sorteio por engajamento
- **API (v0.0.1)**
  - Autenticacao JWT com Passport
  - CRUD de sorteios e participantes
  - Push notifications via Firebase Admin
  - Documentacao Swagger/OpenAPI
- **App Mobile (v1.0.0)**
  - Scanner de QR Code
  - State management com Riverpod
  - Push notifications com Firebase Messaging
  - Navegacao com GoRouter

### Tecnologias

- **Web:** Next.js 16, React 19, Tailwind CSS 4, Prisma, PostgreSQL (Neon)
- **API:** NestJS 11, Prisma, PostgreSQL, Firebase Admin, JWT
- **App:** Flutter 3, Riverpod, GoRouter, Firebase Messaging
