#!/bin/bash
set -e

GITHUB_OWNER="alejandro-delatorre"
GITHUB_REPO="zentra-agent"
VERSION="7.0.25"
TMP_DEB="/tmp/zentra-agent-install.deb"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} Ejecuta con: sudo bash install.sh"
    exit 1
fi

echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║        ZENTRA AGENT  Installer           ║${NC}"
echo -e "${CYAN}  ║        Nuanet  |  zentra.nuanet.com.mx   ║${NC}"
echo -e "${CYAN}  ╚══════════════════════════════════════════╝${NC}"
echo ""

ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo -e "${RED}[ERROR]${NC} Arquitectura no soportada: $ARCH"; exit 1
fi
echo -e "${GREEN}[OK]${NC} Arquitectura: $ARCH"

if [ ! -f /etc/os-release ]; then
    echo -e "${RED}[ERROR]${NC} No se pudo detectar el sistema operativo."; exit 1
fi

. /etc/os-release
echo -e "${GREEN}[OK]${NC} Sistema: $PRETTY_NAME"

# Extraer solo major.minor (22.04, 24.04)
OS_VERSION=$(echo "$VERSION_ID" | cut -d'.' -f1,2)

if [[ "$OS_VERSION" == "22.04" ]]; then
    PACKAGE_NAME="zentra-agent_${VERSION}_ubuntu22_amd64.deb"
elif [[ "$OS_VERSION" == "24.04" ]]; then
    PACKAGE_NAME="zentra-agent_${VERSION}_amd64.deb"
else
    echo -e "${YELLOW}[WARN]${NC} Ubuntu $OS_VERSION no probado, usando paquete 22.04..."
    PACKAGE_NAME="zentra-agent_${VERSION}_ubuntu22_amd64.deb"
fi

echo -e "${GREEN}[OK]${NC} Paquete: $PACKAGE_NAME"
echo -e "${CYAN}[1/3]${NC} Descargando Zentra Agent..."
curl -fL "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest/download/${PACKAGE_NAME}" -o "$TMP_DEB"
if [ ! -s "$TMP_DEB" ]; then
    echo -e "${RED}[ERROR]${NC} Descarga fallida."; exit 1
fi
echo -e "${GREEN}[OK]${NC} Descarga completa."

echo -e "${CYAN}[2/3]${NC} Instalando paquete..."
dpkg -i "$TMP_DEB"
rm -f "$TMP_DEB"
echo -e "${GREEN}[OK]${NC} Paquete instalado."

echo -e "${CYAN}[3/3]${NC} Verificando servicio..."
sleep 2
if systemctl is-active --quiet zentra-agent; then
    echo -e "${GREEN}[OK]${NC} zentra-agent esta corriendo."
else
    echo -e "${RED}[ERROR]${NC} El servicio no arranco. Revisa: journalctl -u zentra-agent -n 50"
    exit 1
fi

echo ""
echo -e "${GREEN}  ✔ Zentra Agent instalado exitosamente.${NC}"
echo ""
echo "  systemctl status zentra-agent"
echo "  journalctl -u zentra-agent -f"
echo "  cat /etc/zentra/zentra_agent2.conf"
echo ""
