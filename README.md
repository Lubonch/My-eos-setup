# My eos-setup — Branch `benchmark-iso` (ISO de benchmarking con i3)

Este branch contiene el build de una **ISO de EndeavourOS liviana enfocada en benchmarking**: sin KDE, con tiling WM **i3** (X11, arranque vía `startx`), ricing sobrio (picom + rofi) y todas las tools de benchmark/stress preinstaladas.

## Qué hay en este branch

| Parte | Descripción |
|-------|-------------|
| `install.sh`, `packages/`, `dotfiles/`, `config.conf` | Script post-install (mismo que `main`/`eos-setup-iso`) |
| `isobuild/` | Build de la ISO benchmark: clona EndeavourOS-ISO, quita KDE, configura i3 y compila los AUR de benchmark |

## Build de la ISO

```
cd isobuild
./setup.sh              # Todo: clona + AUR + ISO (perfil benchmark)
./setup.sh --aur-only   # Solo compilar paquetes AUR (cache en aur-cache/)
./setup.sh --iso-only   # Solo buildear la ISO (AUR ya compilados)
./setup.sh --clean      # Borrar repo clonado y cache
./setup.sh --profile benchmark  # Perfil por defecto (no hace falta pasarlo)
```

Requisitos: `archiso`, `squashfs-tools`, `yay`. ~30GB libres en disco.
Detalle en [`isobuild/README.md`](isobuild/README.md).

## Tools de benchmark incluidas

- **CPU**: geekbench, sysbench, stress-ng, 7zip, blender-benchmark
- **GPU**: unigine-superposition, glmark2, vkmark, gputest, basemark, mangohud, nvtop
- **Suite**: phoronix-test-suite
- **Info hardware**: hardinfo2, cpufetch, btop, mesa-utils, openssl

## Diferencia con el branch `eos-setup-iso`

`eos-setup-iso` arma la ISO diaria (KDE Plasma + apps). `benchmark-iso` arma una ISO mínima (i3 + tools de benchmark) corriendo el mismo `setup.sh` parametrizado con perfil `benchmark` (quita el escritorio KDE del build).