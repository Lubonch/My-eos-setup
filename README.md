# My eos-setup — Branch `benchmark-iso` (ISO de benchmarking con i3)

Branch **autocontenido** para generar una **ISO de EndeavourOS liviana enfocada en benchmarking**: sin KDE, tiling WM **i3** (X11, arranque vía `startx`), ricing sobrio (picom + rofi) y todas las tools de benchmark/stress preinstaladas. **Este branch jamás se mergea a `main`.**

## Uso

```bash
# Clonar directo el branch
git clone -b benchmark-iso https://github.com/Lubonch/My-eos-setup.git
cd My-eos-setup

./setup.sh                    # Todo: clona + AUR (6 paquetes) + ISO (perfil benchmark)
./setup.sh --aur-only         # Solo compilar paquetes AUR (cache en aur-cache/)
./setup.sh --iso-only         # Solo buildear la ISO (AUR ya compilados)
./setup.sh --clean            # Borrar repo clonado y cache
./setup.sh --profile benchmark  # Perfil por defecto (no hace falta pasarlo)
```

Requisitos: `archiso`, `squashfs-tools`, `yay`. ~30GB libres en disco.

## Estructura

| Archivo | Descripción |
|---------|-------------|
| `setup.sh` | Builder de la ISO: clona EndeavourOS-ISO, parchea (quita KDE, configura i3), compila AUR con cache y genera `out/*.iso` |
| `profiles/benchmark.conf` | Perfil benchmark: 6 AUR + paquetes extra + hook que quita KDE y configura i3/picom en el skel |
| `dotfiles/` | Dotfiles para `/etc/skel/` de la ISO: bashrc, gitconfig, gtkrc-2.0, `i3/config`, `picom.conf` |
| `user_commands.bash` | Comandos de post-instalación que corre Calamares |

## Tools de benchmark incluidas

- **CPU**: geekbench, sysbench, stress-ng, 7zip, blender-benchmark
- **GPU**: unigine-superposition, glmark2, vkmark, gputest, basemark, mangohud, nvtop
- **Suite**: phoronix-test-suite
- **Info hardware**: hardinfo2, cpufetch, btop, mesa-utils, openssl

## Fixes aplicados automáticamente por setup.sh

- **Quitar KDE**: el hook `configure_profile` del perfil benchmark marca `plasma-desktop=0` en el repo EOS para que el live arranque sin escritorio.
- **xinitrc i3**: inyecta `exec i3` en `.xinitrc` del `liveuser` y de `/etc/skel` después de `useradd -m`.
- **Conflicto skel**: el `i3/config`/`picom.conf`/`.gtkrc-2.0`/`.gitconfig` copiados a `airootfs/etc/skel/` se agregan al `--overwrite` de `run_before_squashfs.sh` (el paquete `endeavouros-skel-liveuser` los pisa).
- **Dependencias AUR**: `mullvad-vpn-bin` requiere `mullvad-vpn-daemon-bin` y otras cadenas → se compilan en orden y se instalan juntas con `pacman -Udd`.

## Diferencia con el branch `eos-setup-iso`

`eos-setup-iso` arma la ISO diaria (KDE Plasma + apps). `benchmark-iso` arma una ISO mínima (i3 + tools de benchmark) corriendo el mismo `setup.sh` parametrizado con perfil `benchmark`.