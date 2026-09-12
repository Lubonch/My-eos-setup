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
│   └── fonts-other.txt
└── dotfiles/            # Archivos de configuración
    ├── bashrc
    ├── gitconfig
    └── gtkrc-2.0
```

## Agregar/quitar paquetes

Editá los archivos en `packages/`. Cada archivo tiene secciones:

```
# --- Pacman (oficiales) ---
paquete1
paquete2

# --- AUR ---
paquete-aur-1
```

## Dotfiles incluidos

- `.bashrc` - aliases, PATH para dotnet/bin/opencode
- `.gitconfig` - nombre y email
- `.gtkrc-2.0` - tema Breeze-Dark

Para agregar más dotfiles, copialos a `dotfiles/` y agregá la línea de copia en `install.sh` (función `copy_dotfiles`).
