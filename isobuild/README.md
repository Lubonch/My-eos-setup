# My eos-setup - ISO Build

ISO custom de EndeavourOS con KDE y todos los paquetes preinstalados, para instalar offline desde USB.

Branch `eos-setup-iso` con los archivos fuente para reproducir el build de la ISO `EndeavourOS_Titan-2026.09.10.iso` (5.4GB).

## Estructura

| Archivo | Descripción |
|---------|-------------|
| `setup.sh` | Script maestro: clona EndeavourOS-ISO, parchea packages, compila AUR con cache y buildea la ISO |
| `user_commands.bash` | Comandos de post-instalación que corre Calamares (servicios, docker, mirrors) |
| `dotfiles/` | Dotfiles base copiados a `/etc/skel/` de la ISO (bashrc, gitconfig, gtkrc-2.0) |
| `builds/*.log` | Logs de compilación de los paquetes AUR (referencia) |

## Uso

```
# Copiar el contenido de isobuild/ a un directorio con ~30GB libres
cp -r isobuild /mnt/Files-2tb/eos-iso-build
cd /mnt/Files-2tb/eos-iso-build

./setup.sh              # Todo: clona + AUR + ISO
./setup.sh --aur-only   # Solo compilar paquetes AUR (cache en aur-cache/)
./setup.sh --iso-only   # Solo buildear la ISO
./setup.sh --clean      # Borrar repo clonado y empezar de cero
```

Requisitos: `archiso`, `squashfs-tools`, `yay`. El build requiere ~30GB en disco y ~1-2h.

## Fixes aplicados automáticamente por setup.sh

- **Conflicto skel**: el `.gtkrc-2.0`/`.gitconfig` copiados a `airootfs/etc/skel/` rompían la instalación del paquete `endeavouros-skel-liveuser` (sin esto no arranca el DE en live). `clone_and_patch` agrega esos archivos al `--overwrite` de `run_before_squashfs.sh`.
- **Dependencia AUR**: `kcc` requiere `python-mozjpeg-lossless-optimization` (AUR) que abortaba todo el batch de paquetes locales. Ahora se compila e incluye junto al resto.

## Formatos

- `./setup.sh --aur-only` → compila los 23 paquetes AUR y los cachea en `aur-cache/`
- `./setup.sh --iso-only` → mkarchiso genera `out/EndeavourOS_Titan-YYYY.MM.DD.iso`
- La ISO sale ~5.4GB → USB de 8GB mínimo

## Paquetes AUR (23)

proton-ge-custom-bin, visual-studio-code-bin, microsoft-edge-stable-bin, microsoft-edge-beta-bin, vesktop, teams-for-linux, telegram-desktop-bin, zapzap, mullvad-vpn-bin, handbrake-full, hakuneko-desktop-bin, kcc, kindlegen, omnissa-horizon-client, parsec-bin, opencode-desktop-bin, antigravity, ttf-vista-fonts, olive, evsieve, trackma, ani-cli, python-mozjpeg-lossless-optimization (dep de kcc)

## Paquetes pacman extras (~50)

Inyectados en `packages.x86_64` del build de EndeavourOS: steam, protontricks, godot-mono, blender, docker + compose, dotnet-sdk, aspnet-runtime, python + herramientas, nodejs + yarn, edge (stable/beta ya van por AUR), vesktop, teams, telegram, thunderbird, zapzap, mullvad, zerotier, rclone, obs, handbrake (CLI extra), gimp, inkscape, mkvtoolnix, olive, hakuneko, kcc, fastfetch, htop, gparted, gnome-disk-utility, qbittorrent, filezilla, timeshift, keepassxc, wireshark-cli, gtk2-compat, noto-fonts, ttf-vista-fonts, letsencrypt, reflectors, timeshift, yay, sddm, mesa-utils. Ver lista completa en `setup.sh` (`PACKMAN_EXTRAS`).

## Post-instalación

Los scripts modulares por categoría para instalar en el sistema recién formateado viven en la raíz de este repo (`install.sh`, `packages/*.txt`).