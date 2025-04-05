#!/bin/bash
# sync_camera.sh
# Script para sincronizar archivos desde una cámara conectada al ordenador sin sobrescribir archivos existentes.

# Ruta al archivo de configuración.
CONFIG_FILE="/ruta/al/archivo/cameras.conf"

# Nombre de la cámara a procesar.
CAMERA="runcam6"

# Extraer parámetros del archivo de configuración.
MOUNT_POINT=$(awk -F= '/^\[runcam6\]/{flag=1} flag==1 && /^mount_point=/{print $2; flag=0}' "$CONFIG_FILE")
DESTINATION=$(awk -F= '/^\[runcam6\]/{flag=1} flag==1 && /^destination=/{print $2; flag=0}' "$CONFIG_FILE")
FILE_TYPES=$(awk -F= '/^\[runcam6\]/{flag=1} flag==1 && /^file_types=/{print $2; flag=0}' "$CONFIG_FILE")

# Verificar la existencia del punto de montaje.
if [ ! -d "$MOUNT_POINT" ]; then
    echo "El punto de montaje '$MOUNT_POINT' no se encuentra disponible."
    exit 1
fi

# Crear la carpeta destino si no existe.
mkdir -p "$DESTINATION"

# Procesar cada tipo de archivo definido.
IFS=',' read -ra TYPES <<< "$FILE_TYPES"
for ext in "${TYPES[@]}"; do
    rsync -av --ignore-existing "$MOUNT_POINT"/*."$ext" "$DESTINATION"/
done

echo "Sincronización completada para la cámara $CAMERA."
