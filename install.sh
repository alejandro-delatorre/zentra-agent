#!/bin/bash
# ============================================================
#   Zentra Agent - Instalador
#   Nuanet | zentra.nuanet.com.mx
#
#   Uso:
#   curl -fsSL https://raw.githubusercontent.com/alejandro-delatorre/zentra-agent/main/install.sh | sudo bash
# ============================================================

set -e

GITHUB_OWNER="alejandro-delatorre"
GITHUB_REPO="zentra-agent"
PACKAGE_NAME="zentra-agent_7.0.25_amd64.deb"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

banner() {
    echo ""
    echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║                                          ║${NC}"
    echo -e "${CYAN}  ║        ZENTRA AGENT  Installer           ║${NC}"
    echo -e "${CYAN}  ║        Nuanet  |  zentra.nuanet.com.mx   ║${NC}"
    echo -e "${CYAN}  ║                                          ║${NC}"
    echo -e "${CYAN}  ╚══════════════════════════════════════════╝${NC}"
    echo ""
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[ERROR]${NC} Este script requiere permisos de root." >&2
        exit 1
    fi
}

check_arch() {
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        echo -e "${RED}[ERROR]${NC} Arquitectura no soportada: $ARCH" >&2
        exit 1
    fi
    echo -e "${GREEN}[OK]${NC} Arquitectura: $ARCH"
}

check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "${GREEN}[OK]${NC} Sistema: $PRETTY_NAME"
        if [[ "$ID" != "ubuntu" && "$ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
            echo -e "${YELLOW}[WARN]${NC} Este instalador está optimizado para Ubuntu/Debian."
        fi
    fi
}

download_package() {
    echo -e "${CYAN}[1/3]${NC} Descargando Zentra Agent..." >&2
    TMP_DEB=$(mktemp /tmp/zentra-agent-XXXXXX.deb)
    DOWNLOAD_URL="https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest/download/${PACKAGE_NAME}"
    curl -fL "$DOWNLOAD_URL" -o "$TMP_DEB" >&2
    if [ ! -s "$TMP_DEB" ]; then
        echo -e "${RED}[ERROR]${NC} La descarga falló o el archivo está vacío." >&2
        exit 1
    fi
    echo -e "${GREEN}[OK]${NC} Descarga completa." >&2
    echo "$TMP_DEB"
}

install_package() {
    local DEB_PATH="$1"
    echo -e "${CYAN}[2/3]${NC} Instalando paquete..."
    dpkg -i "$DEB_PATH"
    rm -f "$DEB_PATH"
    echo -e "${GREEN}[OK]${NC} Paquete instalado."
}

verify_service() {
    echo -e "${CYAN}[3/3]${NC} Verificando servicio..."
    sleep 2
    if systemctl is-active --quiet zentra-agent; then
        echo -e "${GREEN}[OK]${NC} zentra-agent está corriendo."
    else
        echo -e "${RED}[ERROR]${NC} El servicio no arrancó correctamente."
        echo "        Revisa los logs con: journalctl -u zentra-agent -n 50"
        exit 1
    fi
}

banner
check_root
check_arch
check_os

TMP_DEB=$(download_package)
install_package "$TMP_DEB"
verify_service

echo ""
echo -e "${GREEN}  ✔ Zentra Agent instalado exitosamente.${NC}"
echo ""
echo "  Comandos útiles:"
echo "    systemctl status zentra-agent"
echo "    journalctl -u zentra-agent -f"
echo "    cat /etc/zentra/zentra_agent2.conf"
echo ""
