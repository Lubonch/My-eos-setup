# EndeavourOS Post-Install Setup

Script de automatización para reinstalar EndeavourOS con las mismas configuraciones y apps.

## Uso rápido

```bash
# Clonar el repo
git clone https://github.com/Lubonch/eos-setup.git
cd eos-setup

# Instalar todo
./install.sh

# O seleccionar categorías
./install.sh --only gaming,dev,comms

# Ver categorías disponibles
./install.sh --list
```

## Categorías

| Categoría | Contenido |
|-----------|-----------|
| `system` | Kernel, filesystem tools, utilidades base |
| `gaming` | Steam, Proton GE, protontricks |
| `gamedev` | Godot Mono, Blender |
| `dev` | Docker, .NET SDK, Python, VS Code, DBeaver, Google Cloud CLI |
| `browsers` | Edge Stable + Beta |
| `comms` | Vesktop, Teams, Telegram, Thunderbird, ZapZap |
| `vpn` | Mullvad VPN, ZeroTier, Rclone |
| `media` | OBS, Handbrake, GIMP, Inkscape, MKVToolNix, Olive, Hakuneko |
| `util` | fastfetch, htop, GParted, qBittorrent, FileZilla, Timeshift, KeePassXC |
| `desktop` | Drivers AMD, Vulkan, Omnissa Horizon, Parsec, OpenCode |
| `anime` | Trackma, ani-cli |
| `fonts` | fuentes, gtk2-compat, herramientas varias |

## Estructura

```
eos-setup/
├── install.sh           # Script principal
├── config.conf          # Configuración (categorías por defecto)
├── packages/            # Listas de paquetes por categoría
│   ├── system.txt
│   ├── gaming.txt
│   ├── gamedev.txt
│   ├── development.txt
│   ├── browsers.txt
│   ├── communication.txt
│   ├── vpn-network.txt
│   ├── multimedia.txt
│   ├── utilities.txt
│   ├── desktop-hardware.txt
│   ├── desktop-kde.txt
│   ├── anime.txt
│   └── fonts-other.txt
└── dotfiles/            # Archivos de configuración
    ├── bashrc
    ├── gitconfig
    └── gtkrc-2.0
```

## Agregar/quitar paquetes

Editá los archivos en `packages/`. Cada archivo tiene dos secciones separadas:

```
# Nombre de la categoría
# --- Pacman (oficiales) ---
firefox
steam

# --- AUR ---
proton-ge-custom-bin
vesktop
```

**Importante**: los paquetes AUR van **después** de `# --- AUR ---`. El script usa `yay` para instalarlos (resuelve dependencias automáticamente). Los que están antes se instalan con `sudo pacman -S`.

### Ejemplo: agregar un paquete pacman

1. Abrí el archivo correspondiente (ej: `packages/utilities.txt`)
2. Agregalo bajo `# --- Pacman (oficiales) ---`
3. Ejecutá `git pull` en la instalación fresh

### Ejemplo: agregar un paquete AUR

1. Abrí el archivo (ej: `packages/gaming.txt`)
2. Agregalo bajo `# --- AUR ---`
3. `git pull` en la instalación

### Agregar una categoría nueva

1. Creá el archivo `packages/mi-categoria.txt` con la sección pacman y AUR
2. Agregá la entrada en `CATEGORIES` en `install.sh`:
   ```bash
   [mi-categoria]="mi-categoria|Descripción breve"
   ```

### Logs

Cada ejecución genera un log en `/tmp/eos-setup-YYYYMMDD-HHMMSS.log` con todo el output de instalación. Si algo falla, revisá el log:

```bash
# Ver el último log
ls -t /tmp/eos-setup-*.log | head -1

# Ver errores
grep -i error /tmp/eos-setup-*.log
```

Si un paquete falla, el script se detiene en ese punto (por `set -euo pipefail`). Corregilo y volvé a ejecutar — los paquetes ya instalados se saltan automáticamente.
