import pandas as pd
import cv2
import numpy as np

def leer_datos_gcsv(archivo_gcsv):
    try:
        with open(archivo_gcsv, 'r') as file:
            lines = file.readlines()

        # Buscar la línea donde comienza el encabezado
        header_row = None
        for idx, line in enumerate(lines):
            if 't,rx,ry,rz,ax,ay,az' in line:
                header_row = idx
                break

        if header_row is None:
            print("No se encontró la fila con los encabezados esperados.")
            return None

        datos = pd.read_csv(archivo_gcsv, header=header_row, delimiter=',')
        
        print("Nombres de las columnas en el archivo .gcsv:")
        print(datos.columns)
        
        return datos
    except pd.errors.ParserError as e:
        print(f"Error al leer el archivo .gcsv: {e}")
        return None
    except Exception as e:
        print(f"Error inesperado: {e}")
        return None

def estabilizar_video(video_path, gcsv_path, output_path):
    datos_giroscopio = leer_datos_gcsv(gcsv_path)

    if datos_giroscopio is None:
        print("No se pudieron cargar los datos del giroscopio.")
        return

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print("No se pudo abrir el video.")
        return

    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) * 0.8)  # Reducir resolución a 80%
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) * 0.8)

    # Crear un VideoWriter para guardar el video estabilizado
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    prev_frame = None
    prev_rotation = np.zeros(3)  # Rotación previa (rx, ry, rz)
    
    # Suavizado de la rotación utilizando un filtro de media móvil (para evitar movimientos bruscos)
    smoothing_factor = 0.4  # Factor de suavizado 
    smoothed_rotation = np.zeros(3)

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_idx = int(cap.get(cv2.CAP_PROP_POS_FRAMES)) - 1
        if frame_idx >= len(datos_giroscopio):
            break
        
        if 'rx' in datos_giroscopio.columns and 'ry' in datos_giroscopio.columns and 'rz' in datos_giroscopio.columns:
            rot = datos_giroscopio.iloc[frame_idx][['rx', 'ry', 'rz']].values

            # Suavizado de la rotación
            smoothed_rotation = smoothing_factor * rot + (1 - smoothing_factor) * smoothed_rotation

            rotation_diff = smoothed_rotation - prev_rotation

            # Crear una matriz de transformación basada en la diferencia de rotación (2x3)
            transform = np.array([[1, 0, rotation_diff[0]],
                                  [0, 1, rotation_diff[1]]], dtype=np.float32)

            if prev_frame is not None:
                frame = cv2.warpAffine(frame, transform, (width, height))

            # Guardar el frame estabilizado
            out.write(frame)

            prev_rotation = smoothed_rotation
            prev_frame = frame
        else:
            print("Las columnas 'rx', 'ry', 'rz' no están presentes en los datos.")
            break

    cap.release()
    out.release()
    print(f"Video estabilizado guardado en {output_path}")

# Rutas de tus archivos
archivo_gcsv = "/home/administrador/9C33-6BBD/gcsv/Runcam6_0002.gcsv"
archivo_video = "/home/administrador/9C33-6BBD/mp4/Runcam6_0002.MP4"
archivo_salida = "/home/administrador/9C33-6BBD/Runcam6_0002_estabilizado.MP4"

# Llamada a la función de estabilización
estabilizar_video(archivo_video, archivo_gcsv, archivo_salida)

