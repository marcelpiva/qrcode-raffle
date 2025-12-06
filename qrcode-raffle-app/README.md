# QR Code Raffle App

Aplicativo Flutter para sistema de sorteios com QR Code para eventos.

## Versao

**v2.0.0** - App completo com sistema de eventos, trilhas, palestras e sorteios.

## Funcionalidades

### Sistema de Eventos
- Criar e gerenciar eventos com trilhas e palestras
- **Event Wizard** - Assistente em 3 passos para criar eventos completos
- Timeline visual do evento
- Registro de presencas via QR Code

### Sorteios
- Sorteio de Evento (participantes de todas palestras)
- Sorteio de Palestra (via QR Code)
- Sorteio animado estilo slot machine
- Celebracao com confetti
- Re-sorteio quando ganhador ausente

### UX Moderno
- **Navegacao por Telas** - Todos os fluxos usam telas completas (sem dialogs)
- **Confirmacoes Animadas** - Telas de confirmacao com animacoes
- **Formularios com Preview** - Visualizacao em tempo real
- **Tema Claro/Escuro** - Suporte completo a dark mode
- **Animacoes Fluidas** - flutter_animate em todas as telas

### Outras Funcionalidades
- Ranking de participacao por engajamento
- Display em tempo real para projecao
- Notificacoes push via Firebase
- Sincronizacao com hora do servidor

## Tech Stack

- **Framework:** Flutter 3.x
- **State Management:** Riverpod
- **Navegacao:** GoRouter
- **HTTP:** Dio
- **Animacoes:** flutter_animate, confetti
- **Push Notifications:** Firebase Messaging
- **Armazenamento:** SharedPreferences

## Estrutura do Projeto

```
lib/
├── core/
│   ├── constants/          # Cores, endpoints, dimensoes
│   ├── router/             # Configuracao GoRouter
│   └── services/           # Servicos (API, notificacoes)
├── data/
│   ├── models/             # Modelos JSON (freezed)
│   └── services/           # Implementacoes de servico
├── domain/
│   └── entities/           # Entidades de dominio
└── presentation/
    ├── providers/          # Riverpod providers
    ├── screens/
    │   ├── admin/          # Telas administrativas
    │   ├── home/           # Tela inicial
    │   ├── participant/    # Telas do participante
    │   └── shared/         # Telas compartilhadas
    └── widgets/            # Widgets reutilizaveis
```

## Telas Principais

### Admin
| Tela | Descricao |
|------|-----------|
| `DashboardScreen` | Dashboard com sorteios e eventos |
| `RaffleListScreen` | Lista de sorteios |
| `RaffleDetailScreen` | Detalhes do sorteio |
| `DrawScreen` | Sorteio animado |
| `EventsListScreen` | Lista de eventos |
| `EventDetailScreen` | Detalhes do evento |
| `EventWizardScreen` | Wizard para criar evento |
| `RankingScreen` | Ranking de participacao |

### Participant
| Tela | Descricao |
|------|-----------|
| `RegisterScreen` | Inscricao no sorteio |
| `ConfirmationScreen` | Confirmacao de inscricao |

### Shared
| Tela | Descricao |
|------|-----------|
| `ConfirmationScreen` | Confirmacao generica (delete, close, etc) |
| `SuccessScreen` | Tela de sucesso com confetti |
| `TrackFormScreen` | Formulario de trilha |
| `TalkFormScreen` | Formulario de palestra |

## Desenvolvimento

### Pre-requisitos

- Flutter SDK 3.10+
- Dart 3.0+
- Xcode (para iOS/macOS)
- Android Studio (para Android)

### Instalacao

```bash
# Clone o repositorio
git clone https://github.com/seu-usuario/qrcode-raffle.git
cd qrcode-raffle/qrcode-raffle-app

# Instale as dependencias
flutter pub get

# Gere arquivos (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Execute o app
flutter run
```

### Firebase Setup

O app usa Firebase para notificacoes push. Veja `FIREBASE_SETUP.md` para instrucoes de configuracao.

### Variaveis de Ambiente

Configure o endpoint da API em `lib/core/constants/api_endpoints.dart`:

```dart
class ApiEndpoints {
  static const String baseUrl = 'https://sua-api.com';
}
```

## Build

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release

# macOS
flutter build macos --release
```

## Design System

### Cores (AppColors)

O app usa um sistema de cores com suporte a tema claro/escuro:

- `primary` - Cor principal (roxo)
- `secondary` - Cor secundaria (azul)
- `success` - Verde para sucesso
- `warning` - Amarelo para alertas
- `error` - Vermelho para erros
- `info` - Azul para informacoes

### Animacoes

Todas as telas usam `flutter_animate` para animacoes de entrada:

```dart
Widget.animate()
  .fadeIn(duration: 300.ms)
  .slideY(begin: 0.1, end: 0)
```

## Licenca

MIT
