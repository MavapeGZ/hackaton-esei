#!/bin/bash
# sync_camera.sh

# Ruta al archivo de configuración.
CONFIG_FILE="/home/$USER/camera/camera.conf"
echo "Archivo de configuración: $CONFIG_FILE"

# Obtener las cámaras autorizadas desde el archivo de configuración.
AUTH_CAMS=$(awk -F'[][]' '{for(i=2;i<=NF;i+=2) print $i}' "$CONFIG_FILE")

CURRENT_CAMERA=""

# Detectar la cámara conectada: se recorre cada directorio en /media/$USER/
for dir in /media/$USER/*; do
    if [ -d "$dir" ]; then
        CAMERA_NAME=$(basename "$dir")
        echo "Cámara encontrada: $CAMERA_NAME"
        
        # Comparar con las cámaras autorizadas
        for cam in $AUTH_CAMS; do
            if [ "$CAMERA_NAME" = "$cam" ]; then
                CURRENT_CAMERA="$cam"
                echo "Cámara conectada: $CURRENT_CAMERA"
                break 2  # Salir de ambos bucles si se encuentra coincidencia
            fi
        done
    fi
done

sudo umount /media/$USER/$CAMERA_NAME

# Verificar si se ha encontrado la cámara conectada
if [ -z "$CURRENT_CAMERA" ]; then
    echo "No se ha detectado ninguna cámara autorizada conectada."
    exit 1
fi

# Definir MOUNT_POINT basado en la cámara detectada
MOUNT_POINT="/media/$USER/$CURRENT_CAMERA"
echo $MOUNT_POINT

# Verificar si la cámara está montada
# if ! mount | grep "$MOUNT_POINT" > /dev/null; then
#     # Usar lsblk para obtener el dispositivo correspondiente
#     DEVICE=$(lsblk -o NAME,MOUNTPOINT | grep -E "$MOUNT_POINT" | awk '{print $1}')
#     echo "Dispositivo encontrado: /dev/$DEVICE"
    
#     # Si encontramos el dispositivo, montarlo
#     if [ -n "$DEVICE" ]; then
#         sudo mount /dev/$DEVICE $MOUNT_POINT
#         echo "Cámara montada en: $MOUNT_POINT"
#     else
#         echo "No se encontró dispositivo correspondiente para montar."
#         exit 1
#     fi
# fi

IDVENDOR=`lsusb -v | grep idVendor | tr -s ' ' | cut -d ' ' -f3 | head -n 1`
echo $IDVENDOR

IDPRODUCT=`lsusb -v | grep idProduct | tr -s ' ' | cut -d ' ' -f3 | head -n 1`
echo $IDPRODUCT

PARTITION=$(sudo dmesg | grep -oP 'sd[a-z]+[0-9]+' | tail -n1)
echo "PARTITION $PARTITION"

if [ -z "$(ls -A "/media/$USER/$CAMERA_NAME")" ]; then
    sudo mount /dev/$PARTITION /media/$USER/$CAMERA_NAME
fi

# Verificar que el directorio DCIM existe
if [ ! -d "$MOUNT_POINT/DCIM" ]; then
    echo "No se encontró el directorio 'DCIM' en: $MOUNT_POINT"
    exit 1
fi

# Actualizar las rutas de las cámaras desde el archivo de configuración
MOUNT_POINT=$(awk -F= '/^\['"$CURRENT_CAMERA"'\]/{flag=1} flag==1 && /^mount_point=/{print $2; flag=0}' "$CONFIG_FILE")
DESTINATION_GCSV=$(awk -F= '/^\['"$CURRENT_CAMERA"'\]/{flag=1} flag==1 && /^destination_gcsv=/{print $2; flag=0}' "$CONFIG_FILE")
DESTINATION_MP4=$(awk -F= '/^\['"$CURRENT_CAMERA"'\]/{flag=1} flag==1 && /^destination_mp4=/{print $2; flag=0}' "$CONFIG_FILE")
FILE_TYPES=$(awk -F= '/^\['"$CURRENT_CAMERA"'\]/{flag=1} flag==1 && /^file_types=/{print $2; flag=0}' "$CONFIG_FILE")

# Sustituir "USER" por el valor de la variable de entorno $USER
MOUNT_POINT=$(echo $MOUNT_POINT | sed "s/USER/$USER/g")
DESTINATION_GCSV=$(echo $DESTINATION_GCSV | sed "s/USER/$USER/g")
DESTINATION_MP4=$(echo $DESTINATION_MP4 | sed "s/USER/$USER/g")
FILE_TYPES=$(echo $FILE_TYPES | sed "s/USER/$USER/g")

# Mostrar las rutas configuradas
echo "MOUNT_POINT: $MOUNT_POINT"
echo "DESTINATION_GCSV: $DESTINATION_GCSV"
echo "DESTINATION_MP4: $DESTINATION_MP4"
echo "FILE_TYPES: $FILE_TYPES"

# Crear las carpetas destino si no existen
sudo mkdir -p "$DESTINATION_GCSV"
sudo mkdir -p "$DESTINATION_MP4"

# Procesar cada tipo de archivo definido
IFS=',' read -ra TYPES <<< "$FILE_TYPES"

# Copiar archivos según las extensiones definidas
for ext in "${TYPES[@]}"; do
    echo "Buscando archivos con extensión .$ext en: $MOUNT_POINT/DCIM/"
    archivos=$(find "$MOUNT_POINT/DCIM/" -type f -iname "*.$ext")
    
    if [ -n "$archivos" ]; then
        echo "Archivos encontrados:"
        echo "$archivos"

        if [[ $ext == "mp4" || $ext == "MP4" ]]; then
            DESTINATION=$DESTINATION_MP4
        elif [[ $ext == "gcsv" || $ext == "GCSV" ]]; then
            DESTINATION=$DESTINATION_GCSV
        fi
        
        echo "Copiando archivos a $DESTINATION ..."
        while IFS= read -r archivo; do
            sudo cp -vn "$archivo" "$DESTINATION/"
        done <<< "$archivos"
    else
        echo "No se encontraron archivos .$ext en $MOUNT_POINT/DCIM/"
    fi
done

sudo umount /media/$USER/$CAMERA_NAME

echo "Sincronización completada para la cámara $CURRENT_CAMERA."

echo "Estabilizando"
python3 "$(dirname "$0")/estabilizador.py"
