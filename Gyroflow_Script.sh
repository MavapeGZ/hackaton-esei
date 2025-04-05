#!/bin/bash

# Verifica si Gyroflow CLI está disponible
if ! command -v Gyroflow &> /dev/null
then
    echo "Gyroflow no está instalado o no está en tu PATH."
    exit 1
fi

# Ruta del archivo de video y datos .gcsv 

VIDEO_PATH=
GCSV_PATH=
OUTPUT_DIR=

# Verificar si los archivos existen
if [[ ! -f "$VIDEO_PATH" ]]; then
    echo "El archivo de video no existe: $VIDEO_PATH"
    exit 1
fi

if [[ ! -f "$GCSV_PATH" ]]; then
    echo "El archivo GCSV no existe: $GCSV_PATH"
    exit 1
fi

# Crear directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"

# Estabilizar el video usando Gyroflow
OUTPUT_VIDEO="$OUTPUT_DIR/$(basename "$VIDEO_PATH" .mp4)_stabilizado.mp4"

echo "Estabilizando el video..."
Gyroflow --video "$VIDEO_PATH" --gyro-data "$GCSV_PATH" --output "$OUTPUT_VIDEO"

# Verificar si el proceso fue exitoso
if [[ $? -eq 0 ]]; then
    echo "Video estabilizado guardado en: $OUTPUT_VIDEO"
else
    echo "Hubo un error durante el proceso de estabilización."
    exit 1
fi
