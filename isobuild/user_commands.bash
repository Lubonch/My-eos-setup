#!/bin/bash
# user_commands.bash - Ejecutado por Calamares al final de la instalación
# Este script corre como root

# Habilitar servicios
systemctl enable docker 2>/dev/null
systemctl enable firewalld 2>/dev/null
systemctl enable zerotier-one 2>/dev/null

# Agregar usuario al grupo docker (si existe docker)
if getent group docker >/dev/null 2>&1; then
    usermod -aG docker "$USER" 2>/dev/null
fi

# Configurar mirrors para Argentina/Brasil
if command -v reflector >/dev/null 2>&1; then
    reflector --country Argentina,Brasil --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null
fi

# Actualizar la base de datos de plocate
updatedb 2>/dev/null

echo "Configuración personal completada."