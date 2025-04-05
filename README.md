# hackaton-esei

## Comando de inicio sync cámara

`./camera/detect_camera.sh`

## Descripción del Código

Leer los datos del giroscopio: Utiliza un archivo .gcsv que contiene información de la rotación del dispositivo en tres ejes (rx, ry, rz) y la aceleración (ax, ay, az). Los datos de rotación se utilizan para calcular las transformaciones que estabilizan el video.


Abrir el video: Usa OpenCV para cargar el video que será estabilizado. Se obtiene la tasa de fotogramas por segundo (FPS) y las dimensiones del video.

Reducir resolución del video: Para facilitar la estabilización y mejorar el rendimiento, la resolución del video se reduce al 80% de la original.

**Aplicar estabilización:**

Los datos de rotación se leen del archivo .gcsv para cada fotograma del video.

Se calcula la diferencia de rotación entre los fotogramas consecutivos, utilizando los valores rx, ry y rz.

Se aplica un filtro de suavizado de media móvil a las rotaciones para evitar movimientos bruscos.

Una transformación de matriz 2x3 se genera a partir de la diferencia de rotación para corregir la posición de cada fotograma.

Los fotogramas se estabilizan aplicando la transformación de rotación usando la función cv2.warpAffine().

Guardar el video estabilizado: El video estabilizado se guarda en un archivo de salida.

## Estructura de las funciones:
leer_datos_gcsv(archivo_gcsv): Esta función lee el archivo .gcsv, busca la fila que contiene los encabezados de las columnas y carga los datos utilizando pandas. Si se produce un error, se informa al usuario.

estabilizar_video(video_path, gcsv_path, output_path): Esta función realiza el proceso de estabilización del video. Lee los datos de rotación, abre el video, aplica la estabilización a cada fotograma y guarda el video estabilizado.

Parámetros de Entrada
archivo_video: Ruta al archivo de video que se quiere estabilizar (en formato .MP4 o compatible).


archivo_gcsv: Ruta al archivo .gcsv que contiene los datos de rotación (rx, ry, rz) y aceleración (ax, ay, az).

archivo_salida: Ruta donde se guardará el video estabilizado.

**rotación suavizada=α⋅rotación actual(1−α)⋅rotación suavizada previa**

α es el factor de suavizado (en este código es 0.1).

La rotación actual es la rotación medida en el giroscopio para el fotograma actual.

La rotación suavizada previa es el valor suavizado de la rotación del fotograma anterior.
