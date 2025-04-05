import subprocess
import os

# Rutas de tus archivos
"""
gyroflow_cli_path = "C:\\Users\\izanv\\Downloads\\Gyroflow-windows64\\Gyroflow.exe"  # Cambiá esto según tu sistema
video_path = "C:\\Users\\izanv\\OneDrive\\Documentos\\Haketon_videos\\Runcam6_0000.mp4"
gcsv_path = "C:\\Users\\izanv\\OneDrive\\Documentos\\Haketon_videos\\Runcam6_0000.gcsv"
output_path = "C:\\Users\\izanv\\OneDrive\\Documentos\\Haketon_videos\\Runcam6_0000_estabilizado.mp4"
"""
# Verificá que los archivos existan
if not os.path.exists(video_path):
    raise FileNotFoundError(f"No se encontró el video: {video_path}")
if not os.path.exists(gcsv_path):
    raise FileNotFoundError(f"No se encontró el archivo gcsv: {gcsv_path}")


# Comando Gyroflow CLI
cmd = [
    gyroflow_cli_path,  # Ruta de Gyroflow
    video_path,  # Archivo de video
    "-g", gcsv_path,  # Archivo de datos del giroscopio
    "-t", "_estabilizado",  # Sufijo para el archivo de salida
    "-f"  # Forzar sobreescritura si el archivo de salida ya existe
]




# Ejecutar
try:
    print("Estabilizando el video...")
    subprocess.run(cmd, check=True)
    print(f"Video estabilizado guardado en: {output_path}")
except subprocess.CalledProcessError as e:
    print("Error durante la estabilización:", e)



#path del gyroflow, path del video y path del gcsv el -t es el sufijo que se le va a agregar al video estabilizado, el -f es para forzar la sobreescritura del video si ya existe.

"""
"C:\Users\izanv\Downloads\Gyroflow-windows64\Gyroflow.exe" "C:\Users\izanv\OneDrive\Documentos\Haketon_videos\Runcam6_0000.mp4" -g "C:\Users\izanv\OneDrive\Documentos\Haketon_videos\Runcam6_0000.gcsv" -t "_estabilizado" -f   
"""

# lo mismo pero con el preset de estabilización más fuerte


"""
"C:\Users\izanv\Downloads\Gyroflow-windows64\Gyroflow.exe" "C:\Users\izanv\OneDrive\Documentos\Haketon_videos\Runcam6_0000.mp4" -g "C:\Users\izanv\OneDrive\Documentos\Haketon_videos\Runcam6_0000.gcsv" --preset "{ \"version\": 2, \"stabilization\": { \"smoothing_strength\": 1.2, \"fov\": 1.1 } }" -t "_más_estabilizado" -f"""

