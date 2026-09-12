# My eos-setup — Branch `eos-setup-iso` (ISO diaria con KDE)

Este branch contiene el build completo de la **ISO de EndeavourOS custom** que usa el setup post-install de este repo: KDE Plasma + todos los paquetes precompilados, para instalar offline desde USB.

## Qué hay en este branch

| Parte | Descripción |
|-------|-------------|
| `install.sh`, `packages/`, `dotfiles/`, `config.conf` | Script post-install (igual que `main`): se instala después del formateo |
| `isobuild/` | Build de la ISO: clona EndeavourOS-ISO, inyecta paquetes, compila AUR y genera `out/*.iso` |

## Build de la ISO

```
cd isobuild
./setup.sh              # Todo: clona + AUR (23 paquetes) + ISO (~5.4GB, 1-2h)
./setup.sh --aur-only   # Solo compilar paquetes AUR (cache en aur-cache/)
./setup.sh --iso-only   # Solo buildear la ISO (AUR ya compilados)
./setup.sh --clean      # Borrar repo clonado y cache
```

Requisitos: `archiso`, `squashfs-tools`, `yay`. ~30GB libres en disco.
Detalle completo en [`isobuild/README.md`](isobuild/README.md): fixes aplicados, formatos, paquetes AUR.

## Post-instalación

Los scripts por categoría para el sistema recién formateado (`install.sh`, `packages/*.txt`) están documentados en [`main`](https://github.com/Lubonch/My-eos-setup/tree/main).

## Branch relacionado

- `benchmark-iso`: ISO liviana sin KDE, con i3 + tools de benchmark