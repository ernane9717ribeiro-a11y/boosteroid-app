#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  BOOSTEROID APP - Setup Completo no Termux (Poco X7 Pro)
#  Execute: chmod +x setup.sh && ./setup.sh
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✔]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[→]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo -e "${CYAN}"
cat << 'EOF'
  ██████╗  ██████╗  ██████╗ ███████╗████████╗███████╗██████╗  ██████╗ ██╗██████╗
  ██╔══██╗██╔═══██╗██╔═══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗██║██╔══██╗
  ██████╔╝██║   ██║██║   ██║███████╗   ██║   █████╗  ██████╔╝██║   ██║██║██║  ██║
  ██╔══██╗██║   ██║██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗██║   ██║██║██║  ██║
  ██████╔╝╚██████╔╝╚██████╔╝███████║   ██║   ███████╗██║  ██║╚██████╔╝██║██████╔╝
  ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═════╝
  Cloud Gaming App Builder — Poco X7 Pro Edition
EOF
echo -e "${NC}"

# ── PASSO 1: Atualizar Termux ──────────────────────────────
info "Atualizando pacotes Termux..."
pkg update -y && pkg upgrade -y
log "Termux atualizado"

# ── PASSO 2: Instalar dependências base ───────────────────
info "Instalando dependências base..."
pkg install -y \
    curl \
    wget \
    git \
    unzip \
    zip \
    tar \
    openssl \
    clang \
    cmake \
    ninja \
    openjdk-17 \
    aapt \
    android-tools
log "Dependências base instaladas"

# ── PASSO 3: Configurar Java ──────────────────────────────
info "Configurando Java 17..."
export JAVA_HOME="$PREFIX/opt/openjdk-17"
export PATH="$JAVA_HOME/bin:$PATH"
echo 'export JAVA_HOME="$PREFIX/opt/openjdk-17"' >> ~/.bashrc
echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.bashrc
java -version && log "Java configurado: $(java -version 2>&1 | head -1)"

# ── PASSO 4: Instalar Flutter ─────────────────────────────
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
    info "Baixando Flutter SDK..."
    # Flutter para Linux ARM64 (compatível com Termux)
    FLUTTER_VERSION="3.19.6"
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    
    warn "Download pode demorar ~5-10 min dependendo da conexão..."
    wget -q --show-progress -O /tmp/flutter.tar.xz "$FLUTTER_URL" || \
        err "Falha no download do Flutter. Verifique sua conexão."
    
    info "Extraindo Flutter..."
    tar xf /tmp/flutter.tar.xz -C "$HOME/"
    rm /tmp/flutter.tar.xz
    log "Flutter extraído em $FLUTTER_DIR"
else
    warn "Flutter já encontrado em $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc

# ── PASSO 5: Configurar Android SDK ──────────────────────
ANDROID_SDK="$HOME/android-sdk"
CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

if [ ! -d "$ANDROID_SDK" ]; then
    info "Configurando Android SDK..."
    mkdir -p "$ANDROID_SDK/cmdline-tools"
    wget -q --show-progress -O /tmp/cmdtools.zip "$CMDTOOLS_URL"
    unzip -q /tmp/cmdtools.zip -d /tmp/cmdtools_extract
    mv /tmp/cmdtools_extract/cmdline-tools "$ANDROID_SDK/cmdline-tools/latest"
    rm -rf /tmp/cmdtools.zip /tmp/cmdtools_extract
    log "Android SDK configurado"
fi

export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"
export PATH="$ANDROID_SDK/cmdline-tools/latest/bin:$ANDROID_SDK/platform-tools:$PATH"

echo "export ANDROID_HOME=\"$ANDROID_SDK\"" >> ~/.bashrc
echo "export ANDROID_SDK_ROOT=\"$ANDROID_SDK\"" >> ~/.bashrc
echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"' >> ~/.bashrc

# Aceitar licenças e instalar componentes SDK
info "Instalando Android SDK components (aceite as licenças com 'y')..."
yes | sdkmanager --licenses 2>/dev/null || true
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
log "Android SDK components instalados"

# ── PASSO 6: Configurar Flutter para Android ─────────────
info "Configurando Flutter..."
flutter config --android-sdk "$ANDROID_SDK" --no-analytics
flutter doctor --android-licenses 2>/dev/null || true

# ── PASSO 7: Clonar repositório do app ───────────────────
APP_DIR="$HOME/boosteroid_app"

if [ ! -d "$APP_DIR" ]; then
    info "Clonando repositório do app..."
    warn "Substitua pela URL do seu repositório GitHub:"
    echo ""
    echo -e "  ${CYAN}git clone https://github.com/SEU_USUARIO/boosteroid_app.git${NC}"
    echo ""
    read -p "Cole a URL do seu repositório (ou Enter para pular): " REPO_URL
    
    if [ -n "$REPO_URL" ]; then
        git clone "$REPO_URL" "$APP_DIR"
        log "Repositório clonado"
    else
        warn "Pulando clone. Certifique-se que o projeto está em: $APP_DIR"
    fi
else
    info "Atualizando repositório existente..."
    cd "$APP_DIR" && git pull origin main 2>/dev/null || true
fi

# ── PASSO 8: Build do APK ────────────────────────────────
if [ -d "$APP_DIR" ]; then
    info "Instalando dependências Flutter..."
    cd "$APP_DIR"
    flutter pub get
    
    info "Compilando APK Release..."
    warn "Este processo pode levar 5-15 minutos..."
    flutter build apk --release --target-platform android-arm64
    
    APK_PATH="$APP_DIR/build/outputs/flutter-apk/app-release.apk"
    if [ -f "$APK_PATH" ]; then
        log "APK gerado com sucesso!"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✅ BUILD CONCLUÍDO!${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════${NC}"
        echo -e "  APK: ${CYAN}$APK_PATH${NC}"
        echo -e "  Tamanho: $(du -sh $APK_PATH | cut -f1)"
        echo ""
        echo -e "  Para instalar:"
        echo -e "  ${YELLOW}adb install $APK_PATH${NC}"
        echo -e "  ou abra o arquivo pelo gerenciador de arquivos"
        echo ""
    fi
fi

# ── RESULTADO FINAL ───────────────────────────────────────
echo -e "${CYAN}"
echo "════════════════════════════════════════════════"
echo "  SETUP COMPLETO! Próximos passos:"
echo "════════════════════════════════════════════════"
echo -e "${NC}"
echo "  1. source ~/.bashrc  (recarregar variáveis)"
echo "  2. cd ~/boosteroid_app"
echo "  3. flutter run        (modo debug com USB)"
echo "  4. flutter build apk  (gerar APK release)"
echo ""
echo -e "  ${YELLOW}Dica:${NC} Para compilações futuras, apenas:"
echo "  cd ~/boosteroid_app && git pull && flutter build apk --release"
echo ""
