# 🎮 Boosteroid Cloud Gaming App
### Flutter App com Controles Touch para Android

App Flutter que abre o serviço de cloud gaming **Boosteroid** com controles touch na tela iguais ao GeForce NOW mobile — joysticks, botões ABXY, D-Pad, gatilhos L1/L2/R1/R2 e botões de menu.

---

## 📱 Funcionalidades

| Feature | Descrição |
|---|---|
| 🎮 Controles Touch | Joysticks analógicos, ABXY, D-Pad, L1/L2/R1/R2 |
| 📺 Stream Screen | Tela fullscreen com HUD de qualidade (ping, fps, bitrate) |
| 🔄 Layouts | Standard, FPS, Racing, Custom |
| ⚙️ Configurações | Opacidade dos controles, tamanho, qualidade de vídeo |
| 📳 Haptics | Vibração no toque dos botões |
| 🌙 Dark Theme | Interface escura estilo gaming |

---

## 🚀 Como Compilar no Poco X7 Pro via Termux

### Pré-requisitos no celular

1. **Instalar Termux** (via F-Droid, NÃO pela Play Store — versão da Play Store é desatualizada)
   - Baixe em: https://f-droid.org/packages/com.termux/

2. **Ativar modo desenvolvedor** no MIUI:
   - Configurações → Sobre o telefone → Versão MIUI (toque 7x)
   - Ativar: Opções do desenvolvedor → Depuração USB

3. **Armazenamento** — O processo precisa de ~8GB livres

---

### Passo 1: Preparar o Termux

Abra o Termux e execute:

```bash
# Dar permissão de armazenamento ao Termux
termux-setup-storage

# Atualizar repositórios
pkg update && pkg upgrade -y

# Instalar Git
pkg install git -y
```

---

### Passo 2: Clonar e configurar o projeto

```bash
# Clonar este repositório
git clone https://github.com/SEU_USUARIO/boosteroid_app.git
cd boosteroid_app

# Dar permissão ao script de setup
chmod +x setup_termux.sh

# Executar o setup completo (instala Java, Flutter SDK, Android SDK)
./setup_termux.sh
```

> ⏱️ **Tempo estimado:** 20-40 minutos (depende da conexão Wi-Fi)

---

### Passo 3: Compilar o APK

```bash
cd ~/boosteroid_app

# Baixar dependências
flutter pub get

# Build APK Release (arm64 otimizado para o Poco X7 Pro)
flutter build apk --release --target-platform android-arm64

# O APK estará em:
# build/outputs/flutter-apk/app-release.apk
```

---

### Passo 4: Instalar o APK

**Opção A — Pelo gerenciador de arquivos:**
```bash
# Copiar para pasta acessível
cp build/outputs/flutter-apk/app-release.apk ~/storage/downloads/
# Abrir o arquivo pelo gerenciador de arquivos do MIUI
```

**Opção B — Via ADB (se tiver PC conectado):**
```bash
adb install build/outputs/flutter-apk/app-release.apk
```

**Opção C — Instalar diretamente no Termux:**
```bash
# Com Android Debug Bridge local
pkg install android-tools -y
adb install build/outputs/flutter-apk/app-release.apk
```

---

## 📂 Estrutura do Projeto

```
boosteroid_app/
├── lib/
│   ├── main.dart                    # Entrada do app
│   ├── theme/
│   │   └── app_theme.dart          # Cores e tema
│   ├── models/
│   │   └── game_model.dart         # Modelo de dados
│   ├── screens/
│   │   ├── home_screen.dart        # Biblioteca de jogos
│   │   ├── stream_screen.dart      # Tela de gameplay
│   │   └── settings_screen.dart    # Configurações
│   └── widgets/
│       ├── touch_gamepad.dart      # ⭐ Controles touch
│       ├── stream_player.dart      # Player de vídeo
│       └── game_card.dart          # Card de jogo
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml     # Permissões Android
├── pubspec.yaml                    # Dependências
└── setup_termux.sh                 # Script de setup
```

---

## 🔧 Integrar o Stream Real do Boosteroid

O Boosteroid usa streaming baseado em browser (WebRTC). Para integrar o stream real, substitua o `StreamPlayer` por um WebView:

```dart
// Adicionar ao pubspec.yaml:
// webview_flutter: ^4.4.2

import 'package:webview_flutter/webview_flutter.dart';

class StreamPlayer extends StatefulWidget { ... }
  
// No build():
WebViewWidget(
  controller: WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse('https://boosteroid.com/game/${widget.game.id}/stream')),
)
```

---

## 🎮 Customizar Controles

Para adicionar ou reposicionar botões, edite `lib/widgets/touch_gamepad.dart`:

```dart
// Exemplo: adicionar botão personalizado
Positioned(
  right: 100,
  top: 50,
  child: _FaceButton(
    label: 'Z',
    color: Colors.purple,
    pressed: _pressedButtons.contains('Z'),
    onDown: () => _onButtonDown('Z'),
    onUp: () => _onButtonUp('Z'),
  ),
),
```

---

## ⚡ Dicas para o Poco X7 Pro

- Use **modo performance** (Configurações → Bateria → Modo alto desempenho)
- Ative **"Sempre ativo a 120Hz"** para melhor resposta dos controles touch
- Conecte no **Wi-Fi 5GHz** para menor latência no stream
- O chip **Dimensity 8400-Ultra** do X7 Pro compila Flutter APKs em ~3-5 min

---

## 🔄 Atualizar o App

```bash
cd ~/boosteroid_app
git pull origin main
flutter pub get
flutter build apk --release --target-platform android-arm64
```

---

## 📋 Troubleshooting

| Problema | Solução |
|---|---|
| `flutter: command not found` | `source ~/.bashrc` ou reinicie o Termux |
| `SDK licenses not accepted` | `flutter doctor --android-licenses` |
| Build falha com OOM | Feche outros apps, adicione swap: `fallocate -l 2G ~/swapfile` |
| APK não instala | Ative "Fontes desconhecidas" em Configurações → Segurança |
| WebView não carrega | Verifique permissão INTERNET no AndroidManifest.xml |

---

## 📄 Licença

MIT — Use, modifique e distribua livremente.
