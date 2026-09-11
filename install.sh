#!/usr/bin/env bash
#
# EndeavourOS Post-Install Setup
# Repo: https://github.com/Lubonch/eos-setup (cambiar por tu repo)
#
# Uso:
#   ./install.sh              # Instala todo según config
#   ./install.sh --list       # Muestra categorías disponibles
#   ./install.sh --only gaming,dev  # Solo esas categorías
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/packages"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
LOG_FILE="/tmp/eos-setup-$(date +%Y%m%d-%H%M%S).log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; }
err() { echo -e "${RED}[x]${NC} $*" | tee -a "$LOG_FILE"; }
info() { echo -e "${BLUE}[i]${NC} $*" | tee -a "$LOG_FILE"; }

# ============================================================
# Categorías disponibles (archivos en packages/)
# ============================================================
declare -A CATEGORIES
CATEGORIES=(
    [system]="system|Paquetes base del sistema (kernel, filesystem, etc)"
    [gaming]="gaming|Steam, Proton, protontricks"
    [gamedev]="gamedev|Godot Mono, Blender"
    [dev]="development|Docker, .NET, Python, VS Code, DBeaver"
    [browsers]="browsers|Edge Stable + Beta"
    [comms]="communication|Vesktop, Teams, Telegram, Thunderbird, ZapZap"
    [vpn]="vpn-network|Mullvad VPN, ZeroTier, Rclone"
    [media]="multimedia|OBS, Handbrake, GIMP, Inkscape, MKVToolNix, Olive"
    [util]="utilities|fastfetch, htop, GParted, qBittorrent, FileZilla, Timeshift, KeePassXC"
    [desktop]="desktop-hardware|Drivers AMD, Vulkan, Omnissa, Parsec, OpenCode"
    [kde]="desktop-kde|KDE Plasma: sddm-kcm, kwalletmanager (solo si KDE)"
    [anime]="anime|Trackma, ani-cli"
    [fonts]="fonts-other|ttf-vista-fonts, gtk2-compat, herramientas varias"
)

# ============================================================
# Detección de escritorio
# ============================================================
detect_desktop() {
    local de=""

    # Verificar por variables de entorno
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        de="$XDG_CURRENT_DESKTOP"
    elif [[ -n "${DESKTOP_SESSION:-}" ]]; then
        de="$DESKTOP_SESSION"
    fi

    # Verificar por paquetes instalados
    if [[ -z "$de" ]]; then
        if pacman -Qi plasma-desktop &>/dev/null; then
            de="KDE"
        elif pacman -Qi gnome-shell &>/dev/null; then
            de="GNOME"
        elif pacman -Qi xfce4-session &>/dev/null; then
            de="XFCE"
        elif pacman -Qi i3-wm &>/dev/null; then
            de="i3"
        elif pacman -Qi sway &>/dev/null; then
            de="Sway"
        elif pacman -Qi hyprland &>/dev/null; then
            de="Hyprland"
        fi
    fi

    echo "$de"
}

is_kde() {
    local de
    de=$(detect_desktop)
    [[ "${de,,}" == *"kde"* || "${de,,}" == *"plasma"* ]]
}

# ============================================================
# Funciones
# ============================================================

show_categories() {
    echo -e "\n${CYAN}Categorías disponibles:${NC}\n"
    for key in $(echo "${!CATEGORIES[@]}" | tr ' ' '\n' | sort); do
        IFS='|' read -r file desc <<< "${CATEGORIES[$key]}"
        echo -e "  ${GREEN}$key${NC} -> $desc"
    done
    echo ""
}

check_deps() {
    if ! command -v pacman &>/dev/null; then
        err "Esto es para Arch/EndeavourOS (pacman no encontrado)"
        exit 1
    fi
    if [[ $EUID -eq 0 ]]; then
        err "No correr como root. El script usa sudo cuando necesita."
        exit 1
    fi
}

install_yay() {
    if command -v yay &>/dev/null; then
        log "yay ya instalado"
    else
        log "Instalando yay (AUR helper)..."
        sudo pacman -S --needed --noconfirm yay
    fi
}

install_pacman_packages() {
    local category_file="$1"
    local list_file="$PACKAGES_DIR/${category_file}.txt"

    if [[ ! -f "$list_file" ]]; then
        warn "Archivo no encontrado: $list_file"
        return
    fi

    # Leer paquetes, ignorar comentarios y líneas vacías
    # Frena en el marcador '# --- AUR ---' (los AUR van con yay, no pacman)
    local packages=()
    while IFS= read -r line; do
        [[ "$line" == "# --- AUR ---" ]] && break
        line="${line%%#*}"       # Quitar comentarios
        line="${line// /}"       # Quitar espacios
        [[ -n "$line" ]] && packages+=("$line")
    done < "$list_file"

    if [[ ${#packages[@]} -eq 0 ]]; then
        return
    fi

    log "Instalando ${#packages[@]} paquetes pacman de [$category_file]..."

    # Filtrar los que ya están instalados
    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log "  Todos ya instalados, nada que hacer"
        return
    fi

    log "  Paquetes a instalar: ${to_install[*]}"
    sudo pacman -S --needed --noconfirm "${to_install[@]}" 2>&1 | tee -a "$LOG_FILE"
}

install_aur_packages() {
    local category_file="$1"
    local list_file="$PACKAGES_DIR/${category_file}.txt"

    if [[ ! -f "$list_file" ]]; then
        return
    fi

    local packages=()
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line// /}"
        [[ -n "$line" ]] && packages+=("$line")
    done < <(awk '/^# --- AUR/,0' "$list_file" | tail -n +2)

    if [[ ${#packages[@]} -eq 0 ]]; then
        return
    fi

    log "Instalando ${#packages[@]} paquetes AUR de [$category_file]..."

    local to_install=()
    for pkg in "${packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log "  Todos ya instalados, nada que hacer"
        return
    fi

    log "  Paquetes AUR a instalar: ${to_install[*]}"
    yay -S --needed --noconfirm "${to_install[@]}" 2>&1 | tee -a "$LOG_FILE"
}

install_category() {
    local key="$1"
    local file="${CATEGORIES[$key]%%|*}"

    # Saltar categorías KDE si no estamos en KDE
    if [[ "$file" == "desktop-kde" ]] && ! is_kde; then
        local de
        de=$(detect_desktop)
        warn "Escritorio detectado: ${de:-desconocido} - saltando paquetes KDE"
        return
    fi

    echo -e "\n${CYAN}━━━ Instalando: $key ━━━${NC}"
    install_pacman_packages "$file"
    install_aur_packages "$file"
}

copy_dotfiles() {
    log "Copiando dotfiles..."

    [[ -f "$DOTFILES_DIR/bashrc" ]] && cp "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
    [[ -f "$DOTFILES_DIR/gitconfig" ]] && cp "$DOTFILES_DIR/gitconfig" "$HOME/.gitconfig"
    [[ -f "$DOTFILES_DIR/gtkrc-2.0" ]] && cp "$DOTFILES_DIR/gtkrc-2.0" "$HOME/.gtkrc-2.0"

    log "Dotfiles copiados"
}

# ============================================================
# Main
# ============================================================

main() {
    local categories_to_install=()

    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list)
                show_categories
                exit 0
                ;;
            --only)
                IFS=',' read -ra categories_to_install <<< "$2"
                shift 2
                ;;
            --help|-h)
                echo "Uso: $0 [--list] [--only cat1,cat2]"
                echo "  --list          Muestra categorías disponibles"
                echo "  --only cat1,...  Solo instala categorías específicas"
                exit 0
                ;;
            *)
                err "Opción desconocida: $1"
                exit 1
                ;;
        esac
    done

    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║   EndeavourOS Post-Install Setup     ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"

    check_deps

    # Detectar escritorio
    DETECTED_DESKTOP=$(detect_desktop)
    if [[ -n "$DETECTED_DESKTOP" ]]; then
        info "Escritorio detectado: $DETECTED_DESKTOP"
    else
        warn "No se detectó escritorio - se saltarán paquetes de entorno de escritorio"
    fi

    install_yay

    # Si no se especificaron categorías, preguntar
    if [[ ${#categories_to_install[@]} -eq 0 ]]; then
        show_categories
        echo -e "${YELLOW}¿Qué categorías querés instalar? (separadas por coma, o 'all' para todo)${NC}"
        read -r input

        if [[ "$input" == "all" ]]; then
            categories_to_install=($(echo "${!CATEGORIES[@]}" | tr ' ' '\n' | sort))
        else
            IFS=',' read -ra categories_to_install <<< "$input"
        fi
    fi

    # Instalar cada categoría
    for cat in "${categories_to_install[@]}"; do
        cat=$(echo "$cat" | xargs)  # trim espacios
        if [[ -v "CATEGORIES[$cat]" ]]; then
            install_category "$cat"
        else
            warn "Categoría '$cat' no encontrada, saltando..."
        fi
    done

    # Copiar dotfiles
    copy_dotfiles

    echo -e "\n${GREEN}╔══════════════════════════════════════╗"
    echo "║         Instalación completa!        ║"
    echo "╚══════════════════════════════════════╝${NC}"
    echo -e "\nLog guardado en: $LOG_FILE\n"
}

main "$@"
