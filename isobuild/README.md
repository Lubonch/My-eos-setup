# My eos-setup - ISO Build (Benchmark)

ISO custom de EndeavourOS enfocada en benchmarking: liviana (sin KDE), con tiling WM **i3**,
ricing sobrio (picom + rofi) y herramientas de benchmark/stress preinstaladas.

Branch `benchmark-iso` con los archivos fuente para reproducir el build de la ISO de benchmark.

## Estructura

| Archivo | Descripción |
|---------|-------------|
| `setup.sh` | Script maestro: clona EndeavourOS-ISO, parchea packages, compila AUR con cache y buildea la ISO |
| `profiles/benchmark.conf` | Perfil benchmark: AUR, paquetes extra, y hook que quita KDE + configura i3 |
| `user_commands.bash` | Comandos de post-instalación que corre Calamares (servicios, docker, mirrors) |
| `dotfiles/` | Dotfiles base copiados a `/etc/skel/` de la ISO (bashrc, gitconfig, gtkrc-2.0, i3 config, picom) |

## Uso

```
# Copiar el contenido de isobuild/ a un directorio con ~30GB libres
cp -r isobuild /mnt/Files-2tb/eos-benchmark-iso
cd /mnt/Files-2tb/eos-benchmark-iso

./setup.sh              # Todo: clona + AUR + ISO (perfil benchmark)
./setup.sh --aur-only   # Solo compilar paquetes AUR (cache en aur-cache/)
./setup.sh --iso-only   # Solo buildear la ISO
./setup.sh --clean      # Borrar repo clonado y empezar de cero
./setup.sh --profile daily  # (opcional) si otro día querés el perfil KDE
```

Requisitos: `archiso`, `squashfs-tools`, `yay`. El build requiere ~30GB en disco y ~1-2h.

## Tools de benchmark incluidas

- CPU: geekbench, sysbench, stress-ng, 7zip (compresión), blender-benchmark
- GPU: unigine-superposition, glmark2, vkmark, gputest, basemark, mangohud, nvtop
- Suite: phoronix-test-suite
- Info hardware: hardinfo2, cpufetch, btop, mesautils