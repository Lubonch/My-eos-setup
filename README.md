# My eos-setup — Branch `eos-setup-iso` (ISO diaria con KDE)

Branch **autocontenido** para generar la ISO de EndeavourOS custom (KDE Plasma + paquetes precompilados, instalación offline desde USB). **Este branch jamás se mergea a `main`.**

## Uso

```bash
# Clonar directo el branch
git clone -b eos-setup-iso https://github.com/Lubonch/My-eos-setup.git
cd My-eos-setup

./setup.sh                    # Todo: clona + AUR (23 paquetes) + ISO
./setup.sh --aur-only         # Solo compilar paquetes AUR (cache en aur-cache/)
./setup.sh --iso-only         # Solo buildear la ISO (AUR ya compilados)
./setup.sh --clean            # Borrar repo clonado y cache
./setup.sh --profile daily    # Perfil por defecto (no hace falta)
```

Requisitos: `archiso`, `squashfs-tools`, `yay`. ~30GB libres en disco, ISO ~5.4GB.

## Estructura

| Archivo | Descripción |
|---------|-------------|
| `setup.sh` | Builder de la ISO: clona EndeavourOS-ISO, inyecta paquetes, compila AUR con cache y genera `out/*.iso` |
| `profiles/daily.conf` | Perfil daily: AUR + paquetes extra + hooks |
| `profiles/benchmark.conf` | Perfil benchmark (i3, sin KDE) |
| `dotfiles/` | Dotfiles copiados a `/etc/skel/` de la ISO (bashrc, gitconfig, gtkrc-2.0) |
| `user_commands.bash` | Comandos de post-instalación que corre Calamares |

## Fixes aplicados automáticamente por setup.sh

- **Conflicto skel**: el `.gtkrc-2.0`/`.gitconfig` copiados a `airootfs/etc/skel/` rompían la instalación del paquete `endeavouros-skel-liveuser` (sin esto no arranca el DE en live). `clone_and_patch` agrega esos archivos al `--overwrite` de `run_before_squashfs.sh`.
- **Dependencia AUR**: `kcc` requiere `python-mozjpeg-lossless-optimization` (AUR) que abortaba todo el batch de paquetes locales. Se compila e incluye junto al resto.
- **Batch `pacman -U`**: `mullvad-vpn-bin` depende de `mullvad-vpn-daemon-bin` y otras cadenas (omnissa-horizon, handbrake-full) requieren resolver deps entre los `.pkg` locales → se usa `pacman -Udd`.

## Branch relacionado

- `benchmark-iso`: ISO liviana sin KDE, con i3 + tools de benchmark