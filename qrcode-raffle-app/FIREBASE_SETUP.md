# Configuração do Firebase para Push Notifications

## Pré-requisitos instalados
- ✅ Firebase CLI (v14.27.0)
- ✅ FlutterFire CLI (v1.3.1)

## Passo 1: Login no Firebase

```bash
# No terminal, execute:
firebase login

# Isso abrirá o navegador para autenticação com sua conta Google
```

## Passo 2: Criar/Selecionar Projeto Firebase

### Opção A: Criar novo projeto via console
1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em "Adicionar projeto"
3. Nome sugerido: `qrcode-raffle` ou `qrcode-raffle-app`
4. Habilite Google Analytics (opcional)
5. Aguarde a criação

### Opção B: Usar projeto existente
Se já tem um projeto, anote o ID do projeto (ex: `qrcode-raffle-12345`)

## Passo 3: Configurar FlutterFire

```bash
# Navegue até a pasta do app Flutter
cd /Users/marcelpiva/Projects/qrcode-raffle/qrcode-raffle-app

# Execute o configurador (substitua PROJECT_ID pelo ID do seu projeto)
~/.pub-cache/bin/flutterfire configure --project=PROJECT_ID
```

O FlutterFire irá:
1. Perguntar quais plataformas configurar (selecione Android e iOS)
2. Criar automaticamente os apps no Firebase
3. Baixar os arquivos de configuração
4. Gerar `lib/firebase_options.dart`

## Passo 4: Configurações Manuais (se necessário)

### Android
Se o FlutterFire não configurar automaticamente:

1. No Firebase Console, vá em Configurações do Projeto > Geral
2. Clique em "Adicionar app" > Android
3. Package name: `com.example.qrcode_raffle_app` (verifique em `android/app/build.gradle.kts`)
4. Baixe `google-services.json`
5. Coloque em `android/app/google-services.json`

### iOS
1. No Firebase Console, adicione app iOS
2. Bundle ID: verifique em `ios/Runner.xcodeproj/project.pbxproj` (PRODUCT_BUNDLE_IDENTIFIER)
3. Baixe `GoogleService-Info.plist`
4. Coloque em `ios/Runner/GoogleService-Info.plist`

## Passo 5: Habilitar Cloud Messaging

1. No Firebase Console, vá em **Engajamento > Cloud Messaging**
2. O serviço será habilitado automaticamente

### Para iOS (APNs)
1. Vá em Configurações do Projeto > Cloud Messaging
2. Na seção iOS, faça upload do:
   - **APNs Authentication Key** (recomendado) - arquivo .p8
   - Ou **APNs Certificate** - arquivo .p12

Para obter a APNs Key:
1. Acesse [Apple Developer](https://developer.apple.com/account/resources/authkeys/list)
2. Crie uma nova Key com "Apple Push Notifications service (APNs)"
3. Baixe o arquivo .p8 e anote o Key ID
4. No Firebase, faça upload do .p8, informe Key ID e Team ID

## Passo 6: Atualizar main.dart

Após executar `flutterfire configure`, atualize o `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart'; // Arquivo gerado pelo FlutterFire

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase com options geradas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: QrCodeRaffleApp(),
    ),
  );
}
```

## Passo 7: Testar

```bash
# Executar o app
cd /Users/marcelpiva/Projects/qrcode-raffle/qrcode-raffle-app
flutter run
```

No console do app, você deverá ver:
- "Firebase initialized"
- "NotificationService initialized"
- "FCM Token: ..."

## Enviar Notificação de Teste

### Via Firebase Console
1. Vá em Cloud Messaging > Compose notification
2. Título: "Teste QR Raffle"
3. Texto: "Notificação funcionando!"
4. Selecione o app
5. Envie para dispositivo de teste usando o FCM Token

### Via cURL (com Server Key)
```bash
curl -X POST \
  https://fcm.googleapis.com/fcm/send \
  -H 'Authorization: key=YOUR_SERVER_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Sorteio Iniciando!",
      "body": "O sorteio XYZ está prestes a começar"
    },
    "data": {
      "type": "raffle_starting",
      "raffleId": "abc123"
    }
  }'
```

## Troubleshooting

### Erro: "No Firebase App"
- Verifique se `Firebase.initializeApp()` é chamado antes de qualquer outro código Firebase
- Certifique-se que `firebase_options.dart` foi gerado

### Notificações não chegam no iOS
- Verifique se o APNs está configurado no Firebase Console
- Rode no dispositivo físico (simulador não recebe push)
- Verifique permissões em Settings > Notifications

### Notificações não chegam no Android
- Verifique se `google-services.json` está em `android/app/`
- Limpe e rebuild: `flutter clean && flutter pub get && flutter run`

## Comandos Úteis

```bash
# Verificar login Firebase
firebase projects:list

# Re-configurar FlutterFire
~/.pub-cache/bin/flutterfire configure

# Limpar cache Flutter
flutter clean
flutter pub get

# Ver logs do app
flutter logs
```
