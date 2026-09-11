#!/usr/bin/env bash
#
# eos-iso-build.sh - Script maestro para construir la ISO custom de EndeavourOS
#
# Uso:
#   ./setup.sh              # Clona, parchea, compila AUR y buildea la ISO
#   ./setup.sh --aur-only   # Solo compila los paquetes AUR
#   ./setup.sh --iso-only   # Solo buildea la ISO (los AUR ya compilados)
#   ./setup.sh --clean      # Borra el directorio del repo y empieza de cero
#
# Necesita: pacman, git, archiso, squashfs-tools, yay

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$BASE_DIR/EndeavourOS-ISO"
AUR_CACHE="$BASE_DIR/aur-cache"
AUR_BUILD="/tmp/eos-aur-build"
BUILD_LOGS="$BASE_DIR/builds"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err() { echo -e "${RED}[x]${NC} $*"; }

# ============================================================
# Paquetes AUR para compilar
# ============================================================
AUR_PACKAGES=(
    proton-ge-custom-bin
    visual-studio-code-bin
    microsoft-edge-stable-bin
    microsoft-edge-beta-bin
    vesktop
    teams-for-linux
    telegram-desktop-bin
    zapzap
    mullvad-vpn-bin
    handbrake-full
    hakuneko-desktop-bin
    kcc
    kindlegen
    omnissa-horizon-client
    parsec-bin
    opencode-desktop-bin
    antigravity
    ttf-vista-fonts
    olive
    evsieve
    trackma
    ani-cli
    python-mozjpeg-lossless-optimization
)

# ============================================================
# Paquetes pacman para agregar a packages.x86_64
# ============================================================
PACKMAN_EXTRAS='# CUSTOM SETUP - Lubonch

## Gaming
steam
protontricks

## Game Development
godot-mono
blender

## Development
docker
docker-buildx
docker-compose
dotnet-sdk
aspnet-runtime
python
python-pillow
dbeaver

## Communication
thunderbird

## VPN / Network
rclone
zerotier-one

## Multimedia
obs-studio
gimp
mkvtoolnix-cli
inkscape

## Utilities
fastfetch
htop
gnome-disk-utility
qbittorrent
filezilla
timeshift
keepassxc

## Desktop / Hardware
xf86-video-amdgpu
xf86-video-ati
lib32-vulkan-radeon
kwalletmanager

## KDE extras
sddm-kcm
eos-breeze-sddm

## Fonts / Other
gtk2-compat
bchunk'

# ============================================================
# Funciones
# ============================================================

check_deps() {
    local missing=0
    for cmd in pacman git mkarchiso yay; do
        if ! command -v "$cmd" &>/dev/null; then
            warn "Falta: $cmd"
            missing=1
        fi
    done
    if [[ $missing -eq 1 ]]; then
        err "Faltan dependencias. Instalá: sudo pacman -S --needed archiso git squashfs-tools yay"
        exit 1
    fi
}

clone_and_patch() {
    if [[ -d "$ISO_DIR" ]]; then
        log "EndeavourOS-ISO ya existe, verificando..."
        return
    fi

    log "Clonando EndeavourOS-ISO..."
    git clone https://github.com/endeavouros-team/EndeavourOS-ISO.git "$ISO_DIR"
    cd "$ISO_DIR"

    log "Ejecutando prepare.sh..."
    ./prepare.sh

    log "Agregando paquetes extra a packages.x86_64..."
    echo "$PACKMAN_EXTRAS" >> packages.x86_64

    log "Agregando dotfiles a airootfs/etc/skel/..."
    mkdir -p airootfs/etc/skel
    cp "$BASE_DIR/dotfiles/.bashrc"  airootfs/etc/skel/ 2>/dev/null || true
    cp "$BASE_DIR/dotfiles/.gitconfig" airootfs/etc/skel/ 2>/dev/null || true
    cp "$BASE_DIR/dotfiles/.gtkrc-2.0" airootfs/etc/skel/ 2>/dev/null || true

    log "Agregando user_commands.bash..."
    cp "$BASE_DIR/user_commands.bash" airootfs/root/ 2>/dev/null || true

    log "Parcheando run_before_squashfs.sh (conflicto skel con dotfiles)..."
    sed -i 's|"/etc/skel/\.bashrc"|"/etc/skel/.bashrc","/etc/skel/.gtkrc-2.0","/etc/skel/.gitconfig"|' run_before_squashfs.sh
    grep -q '.gtkrc-2.0' run_before_squashfs.sh || warn "  [!] No se pudo verificar el parche de skel, revisá run_before_squashfs.sh"

    log "Repo parcheado correctamente."
}

build_aur_packages() {
    mkdir -p "$AUR_CACHE"
    mkdir -p "$AUR_BUILD"
    mkdir -p "$BUILD_LOGS"

    local pkg_dir="$ISO_DIR/airootfs/root/packages"
    mkdir -p "$pkg_dir"

    local total=${#AUR_PACKAGES[@]}
    local current=0

    for pkg in "${AUR_PACKAGES[@]}"; do
        current=$((current + 1))

        # Si ya existe el .pkg en cache, copiarlo sin recompilar
        cached=$(ls "$AUR_CACHE/${pkg}-"*.pkg.tar.zst 2>/dev/null | head -1) || true
        if [[ -n "$cached" ]]; then
            log "[$current/$total] $pkg - ya compilado en cache, copiando"
            cp "$cached" "$pkg_dir/"
            continue
        fi

        echo -e "\n${CYAN}━━━ [$current/$total] Compilando $pkg ━━━${NC}"

        cd "$AUR_BUILD"
        rm -rf "$pkg"

        if ! git clone --depth 1 "https://aur.archlinux.org/${pkg}.git" "$pkg" 2>/dev/null; then
            warn "  [!] Error clonando $pkg, saltando..."
            continue
        fi

        cd "$pkg"

        local pkg_log="$BASE_DIR/builds/${pkg}.log"
        if makepkg -s --noconfirm --needed 2>&1 | tee "$pkg_log"; then
            cp *.pkg.tar.zst "$pkg_dir/" 2>/dev/null || true
            cp *.pkg.tar.zst "$AUR_CACHE/" 2>/dev/null || true
            log "  [OK] $pkg compilado (también guardado en cache)"
        else
            warn "  [!] Error compilando $pkg - log en $pkg_log"
        fi

        cd "$AUR_BUILD"
        rm -rf "$pkg"
    done

    log "Compilación AUR terminada. Total en $pkg_dir:"
    ls -lh "$pkg_dir" | grep -c "\.pkg" || true
    du -sh "$pkg_dir"
}

build_iso() {
    cd "$ISO_DIR"

    log "Buildeando ISO (puede tomar 15-45 min)..."
    local out_name="$(date +%Y.%m.%d-%H:%M)"
    sudo ./mkarchiso -v "." 2>&1 | tee "eosiso_${out_name}.log"

    local iso_file
    iso_file=$(ls -t out/*.iso 2>/dev/null | head -1)
    if [[ -n "$iso_file" ]]; then
        log "ISO creada:"
        ls -lh "$iso_file"
    else
        err "No se encontró la ISO en out/. Revisá el log eosiso_${out_name}.log"
        exit 1
    fi
}

# ============================================================
# Main
# ============================================================

MODE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --aur-only) MODE="aur"; shift ;;
        --iso-only) MODE="iso"; shift ;;
        --clean)
            rm -rf "$ISO_DIR" "$AUR_CACHE"
            warn "Cache y repo eliminados."
            log "Reconstruí todo con ./setup.sh"
            exit 0
            ;;
        --help|-h)
            echo "Uso: $0 [--aur-only|--iso-only|--clean]"
            exit 0
            ;;
        *) err "Opción desconocida: $1"; exit 1 ;;
    esac
done

check_deps

case "$MODE" in
    all)
        clone_and_patch
        build_aur_packages
        build_iso
        ;;
    aur)
        clone_and_patch
        build_aur_packages
        ;;
    iso)
        if [[ ! -d "$ISO_DIR" ]]; then
            clone_and_patch
        fi
        build_aur_packages
        build_iso
        ;;
esac

log "Todo completado. ISO en $ISO_DIR/out/"