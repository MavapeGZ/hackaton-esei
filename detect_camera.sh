#!/bin/bash
# sync_camera.sh

# Ruta al archivo de configuración.
CONFIG_FILE="/home/$USER/camera/camera.conf"

# Nombre de la cámara a procesar.
AUTH_CAMS=$(awk -F'[][]' '{for(i=2;i<=NF;i+=2) print $i}' "$CONFIG_FILE")

CURRENT_CAMERA=""
echo "current camera: $CURRENT_CAMERA"  

# Detectar la cámara conectada: se recorre cada directorio en MOUNT_DIR
for dir in "$MOUNT_DIR"/*; do
    if [ -d "$dir" ]; then
        CAMERA_NAME=$(basename "$dir")
        # Comparar con cada cámara autorizada
        for cam in $AUTHORIZED_CAMERAS; do
            if [ "$CAMERA_NAME" = "$cam" ]; then
                CURRENT_CAMERA="$cam"
                echo "current camera: $CURRENT_CAMERA"  
                break 2  # Salir de ambos bucles si se encuentra coincidencia
            fi
        done
    fi
done

if [ -z "$CURRENT_CAMERA" ]; then
    echo "No se ha detectado ninguna cámara autorizada conectada."
fi

echo "Cámara detectada: $CURRENT_CAMERA"

if [ ! -d "/home/$USER/camera" ]; then
    sudo mkdir -p "/home/$USER/camera"
fi

if [ ! -d "/media/$USER/$CURRENT_CAMERA" ]; then
    sudo mkdir -p "/media/$USER/$CURRENT_CAMERA"
fi

if [ ! -d "/home/$USER/Videos/$CURRENT_CAMERA" ]; then
    sudo mkdir -p "/home/$USER/Videos/$CURRENT_CAMERA"
fi

MOUNT_POINT="/media/$USER/$CURRENT_CAMERA"
CFG="SYNC_PARA.CFG.BAK"

# Bucle de espera: se verifica si el archivo existe en el punto de montaje
while [ ! -f "$MOUNT_POINT/$CFG" ]; do
    echo "Esperando a que se conecte la cámara..."
    echo "$MOUNT_POINT/$CFG"
    sleep 5
done

echo "Conectando a la cámara..."

IDVENDOR=`lsusb -v | grep idVendor | tr -s ' ' | cut -d ' ' -f3 | head -n 1`

IDPRODUCT=`lsusb -v | grep idProduct | tr -s ' ' | cut -d ' ' -f3 | head -n 1`

RULE="SUBSYSTEM==\"usb\", ATTR{idVendor}==\"$IDVENDOR\", ATTR{idProduct}==\"$IDPRODUCT\", ACTION==\"add\", RUN+=\"/home/$USER/camera/sync_camera.sh\""

mkdir -p "/etc/udev/rules.d/"
sudo touch "/etc/udev/rules.d/99-camera.rules"
echo "$RULE" | sudo tee /etc/udev/rules.d/99-camera.rules

sudo udevadm control --reload-rules && sudo udevadm trigger

# Extraer parámetros de la cámara detectada desde el archivo de configuración
MOUNT_POINT=$(awk -F= '/^\['"$CURRENT_CAMERA"'\]/{flag=1} flag==1 && /^mount_point=/{print $2; flag=0}' "$CONFIG_FILE")
DESTINATION=$(awk -F= '/^\['"$CURRENT_CAMERA"'\]/{flag=1} flag==1 && /^destination=/{print $2; flag=0}' "$CONFIG_FILE")
FILE_TYPES=$(awk -F= '/^\['"$CURRENT_CAMERA"'\]/{flag=1} flag==1 && /^file_types=/{print $2; flag=0}' "$CONFIG_FILE")

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
