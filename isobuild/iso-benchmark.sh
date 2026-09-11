#!/usr/bin/env bash
#
# iso-benchmark.sh - Builder de ISO EndeavourOS enfocada en benchmarking
#
# Uso:
#   ./iso-benchmark.sh                # Clona, parchea, compila AUR y buildea
#   ./iso-benchmark.sh --aur-only     # Solo compila los paquetes AUR
#   ./iso-benchmark.sh --iso-only     # Solo buildea la ISO (AUR ya compilados)
#   ./iso-benchmark.sh --clean        # Borra el directorio del repo y cache
#
# Perfil: sin KDE, tiling WM i3 + tools de benchmark (geekbench,
# unigine-superposition, phoronix-test-suite, glmark2, vkmark, stress-ng...)

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
    geekbench
    unigine-superposition
    phoronix-test-suite
)

# ============================================================
# Paquetes pacman para agregar a packages.x86_64
# ============================================================
PACKMAN_EXTRAS='# CUSTOM SETUP - Benchmark

## Benchmarking
glmark2
sysbench
stress-ng
7zip
hardinfo2
vkmark

## GPU monitoring / benchmarks
mangohud
nvtop
mesa-utils

## Tiling WM (i3)
i3-wm
i3status
dmenu
xorg-xinit
xcape

## Hardware info
cpufetch
btop'

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

    log "Perfil benchmark: quitando KDE, configurando i3..."

    # 1. Sacar la sección "Desktop environment" de packages.x86_64 (incluye
    #    sddm/plasma/kwin). Se borra desde el header "## Desktop environment"
    #    hasta el siguiente header "## Browser".
    awk '
        /^## Desktop environment$/ { skip=1; next }
        skip && /^## /              { skip=0 }
        !skip { print }
    ' packages.x86_64 > packages.x86_64.tmp && mv packages.x86_64.tmp packages.x86_64
    grep -q "plasma-desktop" packages.x86_64 && warn "  [!] KDE no se removió correctamente"

    log "Agregando paquetes extra a packages.x86_64..."
    echo "$PACKMAN_EXTRAS" >> packages.x86_64

    # 2. Dotfiles: bashrc + nuestro .xinitrc para i3. El .xinitrc va en
    #    airootfs/root/ porque el paquete endeavoursouros-skel-liveuser provee
    #    el suyo (startplasma) y pisa el de /etc/skel.
    log "Agregando dotfiles a airootfs/etc/skel/..."
    mkdir -p airootfs/etc/skel airootfs/root
    cp "$BASE_DIR/dotfiles/.bashrc" airootfs/etc/skel/ 2>/dev/null || true
    cp "$BASE_DIR/dotfiles/.gitconfig" airootfs/etc/skel/ 2>/dev/null || true
    cp "$BASE_DIR/dotfiles/.gtkrc-2.0" airootfs/etc/skel/ 2>/dev/null || true

    cat > airootfs/root/benchmark-xinitrc <<'EOF'
#!/bin/sh
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=i3
export GDK_BACKEND=x11
exec i3
EOF
    chmod +x airootfs/root/benchmark-xinitrc

    log "Agregando user_commands.bash..."
    cp "$BASE_DIR/user_commands.bash" airootfs/root/ 2>/dev/null || true

    # 3. Parchear run_before_squashfs.sh
    #    a) overwrite del skel: cubrir nuestros dotfiles
    sed -i 's|"/etc/skel/\.bashrc"|"/etc/skel/.bashrc","/etc/skel/.gtkrc-2.0","/etc/skel/.gitconfig"|' run_before_squashfs.sh
    grep -q '.gtkrc-2.0' run_before_squashfs.sh || warn "  [!] No aplicó overwrite del skel"
    #    b) instalar el .xinitrc i3 en el liveuser DESPUÉS de useradd -m
    sed -i '/^useradd -m -p ""/a cp "/root/benchmark-xinitrc" "/home/liveuser/.xinitrc"\nchown liveuser:liveuser "/home/liveuser/.xinitrc"' run_before_squashfs.sh
    #    c) instalar el .xinitrc i3 en /etc/skel para el system instalado
    sed -i 's|^cp -af "/root/filebackups/"{"\.bashrc",".bash_profile"} "/etc/skel/"$|cp -af "/root/filebackups/"{".bashrc",".bash_profile"} "/etc/skel/"\ncp "/root/benchmark-xinitrc" "/etc/skel/.xinitrc"|' run_before_squashfs.sh
    #    d) el batch de AUR con -Udd (skip deps, todas presentes en el batch)
    sed -i 's|pacman -U --noconfirm --needed -- "/root/packages/|pacman -Udd --noconfirm --needed -- "/root/packages/|' run_before_squashfs.sh
    grep -q 'pacman -Udd' run_before_squashfs.sh || warn "  [!] No aplicó pacman -Udd"

    # Verificación global del xinitrc i3
    grep -q 'exec i3' airootfs/root/benchmark-xinitrc || err "  [!] .xinitrc i3 mal generado"

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
            log "Reconstruí todo con ./iso-benchmark.sh"
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