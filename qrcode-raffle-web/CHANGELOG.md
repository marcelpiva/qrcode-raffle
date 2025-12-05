# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.5.3] - 2025-12-03

### Corrigido

- **Script de deploy Lightsail** - Removida flag `--silent` do `prisma generate` (nao suportada pelo Prisma CLI)
- **Nova instancia Lightsail** - Servidor recriado com deploy limpo

### Alterado

- Deploy script agora mais robusto e confiavel

## [1.5.2] - 2025-12-03

### Corrigido

- **Normalizacao de e-mail no Ranking** - E-mails com `.` ou `_` agora sao tratados como a mesma pessoa
  - `fulano.algo@nava.com.br` e `fulano_algo@nava.com.br` contam como 1 registro
  - Normalizacao remove `.` e `_` da parte local (antes do @)
  - Afeta calculo do ranking e criacao de sorteio por engajamento
  - E-mail original e preservado para exibicao

### Adicionado

- Utilitario `src/lib/email.ts` com funcao `normalizeEmail()`

### Removido

- Suporte a SQLite removido (apenas PostgreSQL/Neon agora)
  - Removido `prisma/schema.sqlite.prisma`
  - Removido `prisma/schema.postgres.prisma`
  - Removido `prisma/dev.db`
  - Removido `scripts/setup-db.sh`
  - Removido scripts `db:local` e `db:prod` do package.json

## [1.5.1] - 2025-12-03

### Corrigido

- **Status efetivo baseado em timeout** - Se o tempo expirou, status é tratado como "encerrado"
  - Dashboard e detalhes do sorteio mostram status correto
  - Display mostra "ENCERRADO" em vez de "AO VIVO" quando tempo expira
  - Countdown timer esconde automaticamente após expirar
- **Botões de ação consistentes com status efetivo**
  - "Encerrar Inscrições" só aparece se ainda está dentro do prazo
  - "Reabrir Inscrições" aparece quando encerrado (por timeout ou manualmente)
  - "Realizar Sorteio" só disponível quando efetivamente encerrado
- Badge "Tempo esgotado" exibido quando timeout expirou

### Alterado

- Script `deploy-lightsail.sh` atualizado com:
  - Instalação automática do Caddy (porta 80 → 3000)
  - Parada do Apache (Bitnami default)
  - DATABASE_URL correta do Neon
  - COPYFILE_DISABLE=1 para evitar warnings do macOS

## [1.5.0] - 2025-12-03

### Adicionado

- **Ranking de Participação** - Análise de engajamento em múltiplos sorteios
  - Página `/admin/ranking` para visualizar ranking
  - Selecionar múltiplos sorteios finalizados para análise
  - Tabela com posições e medalhas (🥇🥈🥉)
  - Estatísticas de participação (ex: "4 de 4 - 100%")
- **Sorteio por Engajamento** - Criar sorteio VIP com participantes mais engajados
  - Regras configuráveis: "pelo menos X de Y" ou "todos"
  - Preview de participantes elegíveis antes de criar
  - Sorteio criado fechado (não aceita novas inscrições)
- **Timeout de Confirmação** - Re-sorteio automático se ganhador não confirmar
  - Configurável: 1, 2, 3 ou 5 minutos
  - Countdown visual na página de display
  - Dispara novo sorteio automaticamente ao expirar
- Endpoint `/api/raffles/ranking` para calcular ranking
- Endpoint `/api/raffles/create-from-ranking` para criar sorteio por engajamento
- Botão "Ranking" no dashboard admin

### Alterado

- Display page detecta mudança/remoção de vencedor e volta ao estado idle
- PIN destacado na página de registro para o usuário não esquecer
- Acentuação corrigida em todas as páginas em português

## [1.4.0] - 2025-12-02

### Adicionado

- **Timebox/Countdown** - Tempo limite para inscrições (5, 10, 15, 30, 60 min)
  - Countdown proeminente no display e página de registro
  - Encerramento automático quando tempo expira
  - Sincronização com hora do servidor
- **Código de confirmação (PIN)** - Verificação de presença do ganhador
  - Participante cria seu próprio PIN de 5 dígitos ao se inscrever
  - PIN armazenado com hash SHA-256 (seguro)
  - QR Code exibido após sorteio para confirmação
  - Página `/confirm/[id]` para ganhador confirmar presença
- **Export CSV** - Download de dados do sorteio
  - Botão "Download CSV" na página de detalhes
  - Campos: Nome, Email, Data, Ganhador, Prêmio, Status, Confirmação
  - UTF-8 BOM para compatibilidade com Excel
- Versão e data/hora exibidos discretamente no painel admin
- Endpoint `/api/time` para sincronização de tempo
- Endpoint `/api/raffles/[id]/confirm-pin` para confirmação via PIN
- Endpoint `/api/raffles/[id]/export` para exportação CSV
- Componente `CountdownTimer` com animação de urgência

### Alterado

- Schema do banco atualizado com novos campos (timeboxMinutes, endsAt, requireConfirmation, pinHash)
- Formulário de criação de sorteio com novas opções
- Página de registro mostra countdown e input de PIN

## [1.3.1] - 2025-12-02

### Adicionado

- Botão "Reabrir Inscrições" quando sorteio está fechado (sem vencedor ainda)
- Botão "Sortear Novamente" na página de sorteio (quando há vencedor pendente)

### Corrigido

- Botão de sortear não desaparece mais após primeiro sorteio
- Permite múltiplos re-sorteios pela página animada

## [1.3.0] - 2025-12-02

### Adicionado

- Re-sorteio quando ganhador está ausente
- Histórico de sorteios com participantes ausentes (DrawHistory)
- Confirmação de presença do vencedor
- Reabrir sorteio finalizado
- APIs: `/api/raffles/[id]/confirm-winner` e `/api/raffles/[id]/reopen`
- Novo modelo `DrawHistory` no banco de dados
- UI para confirmar presença ou sortear novamente
- Card de "Sorteados Ausentes" com histórico

### Alterado

- Sorteio agora exclui participantes já sorteados (ausentes)
- Página de sorteio redireciona para confirmar ou re-sortear

## [1.2.0] - 2025-12-01

### Alterado

- Renomeado projeto de "NAVA QR Sort" para "QR Code Raffle"
- Migrado repositório para github.com/marcelpiva-nava/nava-qr-code-raffle
- Display mobile redesenhado com layout mais impactante
- Botão "Acompanhar Sorteio ao Vivo" na confirmação de inscrição

## [1.1.0] - 2025-12-01

### Adicionado

- Autenticação do painel admin com senha (validada no backend)
- Filtro de domínio de e-mail por sorteio
- Atualização em tempo real da lista de participantes (polling 3s)
- Painel de exibição `/display/[id]` para projetar em tela durante eventos
- Animação de slot machine no painel de display
- Celebração com confetti no painel de display
- Notificação de novo participante em tempo real
- Botão "Abrir Painel de Exibição" nos detalhes do sorteio

### Corrigido

- Notificação de novo participante não repete mais a cada polling
- Schema PostgreSQL simplificado (removido directUrl)

### Alterado

- README atualizado com novas funcionalidades
- Variável `ADMIN_PASSWORD` agora é obrigatória em produção

## [1.0.0] - 2025-12-01

### Adicionado

- Sistema completo de sorteios com QR Code
- Painel administrativo para gerenciar sorteios
- Registro de participantes via QR Code
- Sorteio animado estilo slot machine
- Celebração do vencedor com efeito confetti
- API REST para gerenciamento de sorteios e participantes
- Suporte a SQLite para desenvolvimento local
- Suporte a PostgreSQL (Neon) para produção
- Script de seed para gerar dados de teste (150 participantes)
- Chaveamento automático entre bancos de dados (dev/prod)
- Documentação completa no README

### Tecnologias

- Next.js 16
- React 19
- Prisma ORM
- Tailwind CSS 4
- Radix UI
- Framer Motion
- Deploy via Vercel

## [0.1.0] - 2025-12-01

### Adicionado

- Setup inicial do projeto com Create Next App
- Configuração do Prisma com PostgreSQL (Neon)
