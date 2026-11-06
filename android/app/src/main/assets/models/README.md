# Modelo Vosk para reconocimiento de voz

## Descarga del modelo

Para que el reconocimiento de voz funcione, necesitas descargar el modelo Vosk en español:

1. Descarga el modelo desde: https://alphacephei.com/vosk/models
2. Busca y descarga: `vosk-model-small-es-0.42.zip`
3. Extrae el contenido del ZIP
4. Copia la carpeta `vosk-model-small-es-0.42` **directamente** dentro de `android/app/src/main/assets/` (no la coloques dentro de subcarpetas)

La estructura final debe ser:
```
android/app/src/main/assets/
  └── vosk-model-small-es-0.42/
      ├── am/
      ├── graph/
      └── ... (otros archivos del modelo)
```

## Nota

El modelo no se incluye en el repositorio por su tamaño (~40MB). Cada desarrollador debe descargarlo manualmente.

## Alternativa

Si el modelo no está disponible, la app usará un fallback que devuelve resultados por defecto (los niveles se marcarán como "Fuerte").
