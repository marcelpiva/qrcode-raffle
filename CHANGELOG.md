# Changelog

Todas as mudancas notaveis neste projeto serao documentadas neste arquivo.

O formato e baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.0.5] - 2025-12-06

### Adicionado

- **App Flutter Completo (v2.0.0)** - App mobile nativo com todas as funcionalidades
  - Sistema de eventos com trilhas e palestras
  - Wizard para criar eventos com trilhas e palestras em 3 passos
  - Registro de presencas via QR Code
  - Ranking de participantes por engajamento
  - Display em tempo real para projecao
  - Tema claro/escuro com design moderno
  - Animacoes fluidas com flutter_animate e confetti
  - Firebase Cloud Messaging para notificacoes push
  - Providers com Riverpod para state management
  - GoRouter para navegacao

### Melhorado

- **UX Modernizado (App) - Navegacao por Telas** - Dialogs substituidos por telas completas
  - Confirmacoes de exclusao usam telas animadas em vez de dialogs
  - Formularios de trilha e palestra sao telas dedicadas com preview em tempo real
  - Sucesso de registro exibe tela com confetti animado
  - Event Wizard redesenhado com indicador de progresso visual
  - Cores tematicas (AppColors) com suporte completo a dark mode

- **Novas Telas Compartilhadas**
  - `ConfirmationScreen` - Confirmacao generica com tipos (delete, close, warning, info)
  - `SuccessScreen` - Tela de sucesso com confetti animado
  - `TrackFormScreen` - Formulario de trilha com seletor de cor
  - `TalkFormScreen` - Formulario de palestra com seletores de horario

---

## [2.0.0] - 2025-12-05

### Adicionado

- **Sistema de Eventos Completo**
  - Gerenciamento de eventos com trilhas e palestras
  - Presencas por palestra com duracao calculada
  - Timeline visual do evento
  - Import CSV para trilhas, palestras e presencas
  - Paginas `/admin/events` e `/admin/events/[id]`
- **Tipos de Sorteio**
  - Sorteio de Evento (participantes de todas palestras com filtro de tempo minimo)
  - Sorteio de Palestra (via QR Code)
- **Wizard de Criacao de Sorteio** - Assistente em 3 passos
  - Passo 1: Escolha do tipo (Evento ou Palestra)
  - Passo 2: Configuracao (tempo minimo ou selecao de palestra)
  - Passo 3: Detalhes do premio e opcoes avancadas
- **Countdown Duplo** - "Abre em" antes do inicio, "Encerra em" durante o periodo
- **Sorteio Automatico** ao fim do countdown (`autoDrawOnEnd`)
- **Inscricao por Link** - Toggle para permitir inscricao via QR Code em sorteios de evento
- **Display Grandioso para Eventos** - Layout especial com trofeu animado e contador de participantes
- **Acoes Admin em Tempo Real** - Display reflete imediatamente acoes do admin
- **Novos Componentes UI**
  - Checkbox, Radio Group, Select, Switch, Tooltip
  - Event Form Dialog, Event Wizard Dialog
  - Raffle Wizard Dialog, Talk Form Dialog, Track Form Dialog
  - CSV Upload Dialogs (trilhas, palestras, presencas)
  - Attendance List Dialog, Delete Confirmation Dialog
  - Event Timeline
- **Novas APIs**
  - `/api/events` - CRUD de eventos
  - `/api/tracks` - CRUD de trilhas
  - `/api/talks` - CRUD de palestras
  - `/api/talks/[id]/attendance` - Gerenciar presencas
  - `/api/ranking/events` - Eventos para ranking
  - `/api/ranking/tracks` - Trilhas de um evento
  - `/api/ranking/create-raffle` - Criar sorteio a partir do ranking
  - `/api/events/[id]/eligible-count` - Contagem de participantes elegiveis
- **Utilitario CSV** - `src/lib/csv.ts` com funcoes de parse e validacao

### Alterado

- Schema Prisma atualizado com modelos Event, Track, Talk e TalkAttendance
- Raffle agora suporta vinculo com Event e Talk
- Polling continua durante fase de celebracao para detectar acoes do admin
- Interface Track atualizada com `startDate/endDate`
- README principal do monorepo revisado com documentacao completa

### Removido

- Pagina `/admin/new` (substituida pelo wizard)
- Scripts de migracao obsoletos (`migrate-raffles.ts`, `migrate-nava-summit.ts`)
- Endpoint `/api/tracks/[id]/attendance` (presencas sao por Talk)

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
