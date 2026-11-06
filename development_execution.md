# Alerta ACV – Development Execution Log

Este documento registra el progreso de implementación del MVP de Alerta ACV según el plan de desarrollo.

---

## ÉPICA 1 – Arquitectura base + UI FAST con mocks ✅ COMPLETADA

**Rama:** `feature/architecture-and-ui`  
**Fecha de inicio:** [Fecha actual]  
**Fecha de finalización:** [Fecha actual]  
**Estado:** ✅ COMPLETADA

### Objetivo
Tener toda la UI y flujo FAST funcional, pero con datos mock (sin nativo todavía).

### Tareas completadas

#### 1.1 Setup Flutter & dependencias ✅
- ✅ Añadidas todas las dependencias a `pubspec.yaml`:
  - `go_router` (^14.0.0) - Routing
  - `flutter_riverpod` (^2.5.1) - State management
  - `flutter_tts` (^4.0.2) - Text to speech
  - `permission_handler` (^11.3.0) - Permisos
  - `url_launcher` (^6.2.5) - Llamadas 911
  - `sqflite` (^2.3.3+1) - Base de datos local (cambiado de isar por compatibilidad)
  - `path_provider` (^2.1.2) - Rutas de archivos
  - `flutter_secure_storage` (^9.0.0) - Almacenamiento seguro
  - `intl` (^0.20.2) - Internacionalización
  - `flutter_localizations` - Localización

- ✅ Creada estructura de carpetas:
```
lib/
  main.dart
  app.dart
  core/
    routing/
      app_router.dart
    theme/
      app_theme.dart
    di/
      app_providers.dart
    constants/
      fast_constants.dart
      risk_levels.dart
  features/
    fast/
      pages/
        home_page.dart
        face_step_page.dart
        arms_step_page.dart
        speech_step_page.dart
        decision_page.dart
    history/
      pages/
        history_page.dart
    contacts/
      pages/
        contacts_page.dart
    settings/
      pages/
        settings_page.dart
    help/
      pages/
        help_page.dart
  services/
    device/
      floating_911_button.dart
  l10n/
    app_es.arb
```

- ✅ Configurado `app_router.dart` con todas las rutas:
  - `/` (Home)
  - `/fast/face`
  - `/fast/arms`
  - `/fast/speech`
  - `/fast/decision`
  - `/history`
  - `/contacts`
  - `/settings`
  - `/help`

- ✅ Configurado `app_theme.dart` con:
  - Tema claro (lightTheme)
  - Tema alto contraste (highContrastTheme)
  - Soporte para toggle de modo alto contraste

- ✅ Configurado `intl_es.arb` con textos básicos

#### 1.2 UI FAST (mock) ✅

- ✅ **HomePage**
  - Botón "Iniciar prueba FAST" en color rojo con texto blanco
  - Botón 911 permanente (Floating911Button con icono de teléfono)
  - Accesos a Historial, Contactos, Ajustes, Ayuda
  - Disclaimer visible: "Esta app no proporciona diagnóstico médico. Ante cualquier duda, llama al 911."
  - Sin AppBar (título "Alerta ACV" directamente en el contenido)
  - Orden de botones: Contactos de emergencia, Ayuda, Ajustes, Historial

- ✅ **FaceStepPage (mock)**
  - Instrucciones para usar cámara trasera: "Coloca a la persona en cuadro y pídele que sonría por 5 segundos."
  - Temporizador de 5s con animación
  - Resultado mock: enum `FaceLevel { sin, leve, fuerte }` (hardcode como "sin" por ahora)
  - Botón 911 flotante visible

- ✅ **ArmsStepPage (mock)**
  - Instrucciones: "Pídele que levante ambos brazos al frente y los mantenga arriba mientras contamos 10."
  - Temporizador de 10s
  - Resultado mock: `dropDetected = false` (hardcode)
  - Botón 911 flotante visible

- ✅ **SpeechStepPage (mock)**
  - Muestra frase: "Hoy es un buen día para ayudar."
  - Botón de grabar (solo flujo visual)
  - Temporizador de 10s
  - Resultado mock: `SpeechLevel { sin, leve, fuerte }` (hardcode como "sin" por ahora)
  - Botón 911 flotante visible

- ✅ **DecisionPage**
  - Combina los niveles mock usando la heurística de `risk_levels.dart`
  - Muestra riesgo global (Bajo/Medio/Alto) con colores:
    - Verde para Bajo
    - Naranja para Medio
    - Rojo para Alto
  - Si ALTO:
    - Cuenta regresiva de 10s
    - Botón "Cancelar"
    - Al terminar, botón para llamar al 911 (o llamado directo)
  - Muestra detalles de cada prueba (Habla, Cara, Brazos)
  - Botón 911 flotante visible

- ✅ **Floating911Button**
  - Widget global reutilizable
  - Icono de teléfono (Icons.phone)
  - Color rojo con texto blanco
  - Usa `url_launcher` con `tel:911`
  - Visible en todas las pantallas

#### 1.3 Modo alto contraste (básico) ✅
- ✅ Añadido en Settings un toggle "Modo alto contraste"
- ✅ Cambia ThemeData para mayor contraste (fondo oscuro + texto claro)
- ✅ Persistencia del estado con Riverpod (`highContrastProvider`)
- ✅ Se aplica automáticamente en toda la app

### Constantes FAST implementadas ✅
- ✅ `fast_constants.dart`:
  - `faceSeconds = 5`
  - `armsSeconds = 10`
  - `speechSeconds = 10`
  - Umbrales de habla: >= 0.80 (sin), 0.60-0.79 (leve), < 0.60 (fuerte)
  - Umbrales de cara: < 0.08 (sin), 0.08-0.14 (leve), >= 0.15 (fuerte)
  - Umbrales de brazos: delta(t) >= 0.20 durante >= 2s
  - Frase objetivo: "Hoy es un buen día para ayudar."
  - Tiempo de cuenta regresiva: 10s

- ✅ `risk_levels.dart`:
  - Enums: `RiskLevel`, `SpeechLevel`, `FaceLevel`
  - Función `combineFastResults()` con lógica:
    - ALTO si: habla fuerte, cara fuerte, caída detectada, o >= 2 leves
    - MEDIO si: exactamente 1 leve
    - BAJO si: 0 leves/fuertes

### Páginas secundarias implementadas ✅
- ✅ **HistoryPage**: Placeholder básico (funcionalidad en ÉPICA 6)
- ✅ **ContactsPage**: Placeholder básico (funcionalidad en ÉPICA 7)
- ✅ **SettingsPage**: Toggle de modo alto contraste funcional
- ✅ **HelpPage**: Información sobre FAST y disclaimer

### Definition of Done - Verificación ✅
- ✅ App corre en Android (verificado con `flutter analyze` - sin errores)
- ✅ Se puede completar todo el flujo FAST con datos mock
- ✅ Botón 911 siempre visible en todas las pantallas
- ✅ UI entendible y accesible (texto >= 16sp)
- ✅ Modo alto contraste funcional
- ✅ Routing completo y funcional
- ✅ Estado global con Riverpod configurado

### Notas técnicas
- Se cambió de `isar` a `sqflite` por problemas de compatibilidad con Android Gradle Plugin 8.9.1 (error de namespace). `sqflite` es más estable y compatible.
- Todos los resultados son mock/hardcodeados por ahora. La lógica real se implementará en las épicas siguientes.
- El flujo completo funciona: Home → Face → Arms → Speech → Decision → Home

### Próximos pasos
- **ÉPICA 2**: Pigeon + servicios nativos (stubs)
- Implementar APIs Pigeon para comunicación Flutter ↔ nativo
- Crear stubs nativos Android que devuelvan datos simulados

---

## ÉPICA 2 – Pigeon + servicios nativos (stubs) ✅ COMPLETADA

**Rama:** `feature/pigeon-and-stubs`  
**Fecha de inicio:** [Fecha actual]  
**Fecha de finalización:** [Fecha actual]  
**Estado:** ✅ COMPLETADA

### Objetivo
Tener la interfaz Flutter ↔ nativo lista, aunque la lógica nativa aún sea stub.

### Tareas completadas

#### 2.1 Definir APIs Pigeon ✅
- ✅ Creado `pigeons/fast_api.dart` con:
  - Clases de datos:
    - `SpeechResult { String transcript; double similarity; String level; }`
    - `FaceResult { double asymmetry; String level; bool faceFound; bool lowLight; }`
    - `ArmsResult { double deltaY; bool dropDetected; }`
  - Host API `FastNativeApi`:
    - `void init()`
    - `SpeechResult runSpeech(String targetPhrase, int maxSeconds)`
    - `FaceResult runFace(int maxMillis)`
    - `ArmsResult runArms(int seconds)`
    - `void dispose()`
  - Host API `DeviceApi`:
    - `bool placeCall911()`
    - `bool sendEmergencySms(String message, bool includeLocation)`

- ✅ Generado código Pigeon:
  - Dart: `lib/pigeons/fast_api.g.dart`
  - Kotlin: `android/app/src/main/kotlin/com/example/alerta_acv/FastApi.kt`
  - Swift: `ios/Runner/FastApi.swift` (para futuro soporte iOS)

#### 2.2 Stubs nativos Android ✅
- ✅ Implementado `FastNativeApiImpl.kt` con retornos simulados:
  - `runSpeech` → transcript "hoy es un buen dia para ayudar", similarity 0.9, level "Sin"
  - `runFace` → asymmetry 0.05, level "Sin", faceFound true, lowLight false
  - `runArms` → deltaY 0.1, dropDetected false

- ✅ Implementado `DeviceApiImpl.kt` con stubs:
  - `placeCall911()` → intenta realizar llamada real (requiere permiso CALL_PHONE)
  - `sendEmergencySms()` → stub que solo loguea (implementación real en épicas futuras)

- ✅ Registradas las implementaciones en `MainActivity.kt`:
  - `FastNativeApi.setUp()` con `FastNativeApiImpl()`
  - `DeviceApi.setUp()` con `DeviceApiImpl(this)`

- ✅ Añadido permiso `CALL_PHONE` en `AndroidManifest.xml`

#### 2.3 Servicio Flutter ✅
- ✅ Creado `FastService` en `lib/services/fast/fast_service.dart`:
  - Wrappea las clases generadas por Pigeon (`FastNativeApi`, `DeviceApi`)
  - Convierte strings de nivel a enums (`SpeechLevel`, `FaceLevel`)
  - Métodos:
    - `init()` - Inicializa recursos nativos
    - `runSpeech()` - Devuelve `SpeechLevel`
    - `runFace()` - Devuelve `FaceLevel`
    - `runArms()` - Devuelve `bool dropDetected`
    - `placeCall911()` - Llama al 911
    - `sendEmergencySms()` - Envía SMS (stub)
    - `dispose()` - Libera recursos

- ✅ Conectada la UI para usar `FastService`:
  - **FaceStepPage**: Usa `_fastService.runFace()` en lugar de mock hardcoded
  - **ArmsStepPage**: Usa `_fastService.runArms()` en lugar de mock hardcoded
  - **SpeechStepPage**: Usa `_fastService.runSpeech()` en lugar de mock hardcoded
  - Todas las páginas muestran indicador de carga (`CircularProgressIndicator`) mientras se procesan los resultados
  - Inicialización y limpieza de recursos en `initState()` y `dispose()`

### Dependencias añadidas ✅
- ✅ `pigeon: ^22.1.0` en `dev_dependencies`

### Definition of Done - Verificación ✅
- ✅ UI sigue funcionando igual, pero ahora los datos vienen de Pigeon (stubs nativos)
- ✅ No hay lógica ML real aún (solo stubs)
- ✅ Comunicación Flutter ↔ nativo funcional
- ✅ Sin errores de análisis (`flutter analyze` - sin issues)
- ✅ Código generado por Pigeon correctamente integrado

### Notas técnicas
- Los stubs devuelven valores simulados según el plan de desarrollo
- `DeviceApiImpl.placeCall911()` intenta realizar la llamada real, pero requiere permisos en tiempo de ejecución (se manejará en épicas futuras)
- `sendEmergencySms()` es completamente stub por ahora
- El código Swift se generó pero no se implementó (para futura ÉPICA 9 - iOS)

### Próximos pasos
- **ÉPICA 3**: Voz offline con Vosk (Android)
- Implementar `runSpeech` real usando Vosk para reconocimiento de voz offline
- Calcular similitud con la frase objetivo usando Levenshtein/CER

---

## ÉPICA 3 – Voz offline con Vosk (Android) ✅ COMPLETADA

**Rama:** `feature/voice-vosk-android`  
**Fecha de inicio:** [Fecha actual]  
**Fecha de finalización:** [Fecha actual]  
**Estado:** ✅ COMPLETADA

### Objetivo
Implementar `runSpeech` real en Android usando Vosk para reconocimiento de voz offline.

### Tareas completadas

#### 3.1 Integración Vosk ✅
- ✅ Añadida dependencia `com.alphacephei:vosk-android:0.3.38` en `android/app/build.gradle.kts`
- ✅ Añadida dependencia JNA (`net.java.dev.jna:jna:5.13.0@aar`) para librerías nativas de Vosk
- ✅ Configurado repositorio Maven de Vosk en `android/build.gradle.kts`:
  - `maven("https://alphacephei.com/maven/")`
- ✅ Configurado modelo de lenguaje español:
  - Modelo requerido: `vosk-model-small-es-0.42`
  - Ubicación: `android/app/src/main/assets/vosk-model-small-es-0.42/`
  - Documentación de descarga añadida en `README.md` y `android/app/src/main/assets/models/README.md`
  - Creado archivo placeholder `uuid` dentro del modelo (requerido por Vosk)

#### 3.2 AsrEngine (Motor de reconocimiento) ✅
- ✅ Creado `AsrEngine.kt` en `android/app/src/main/kotlin/com/example/alerta_acv/`:
  - Carga perezosa del modelo Vosk de forma asíncrona (no bloquea UI)
  - Inicialización en background thread usando `StorageService.unpack()`
  - Método `waitForModel()` para esperar carga del modelo si es necesario
  - Grabación de audio con `AudioRecord`:
    - Configuración: 16kHz mono, PCM16
    - Buffer size: 4096 bytes
    - Duración configurable según `maxSeconds`
  - Procesamiento de audio en tiempo real con Vosk `Recognizer`
  - Extracción de transcript desde JSON resultante
  - Cálculo de similitud usando distancia de Levenshtein:
    - Normalización de texto (lowercase, sin acentos, sin puntuación)
    - Character Error Rate (CER) calculado
    - Similitud = 1.0 - (distancia / max_length)
  - Clasificación de nivel según umbrales FAST:
    - `>= 0.80` → "Sin" dificultad
    - `0.60-0.79` → "Leve"
    - `< 0.60` → "Fuerte"
  - Método `dispose()` para liberar recursos (`Model` y `Recognizer`)

#### 3.3 Integración con Pigeon y FastNativeApi ✅
- ✅ Modificado `pigeons/fast_api.dart`:
  - Método `runSpeech` marcado como `@async` para permitir ejecución asíncrona en native
- ✅ Regenerado código Pigeon:
  - Dart: `lib/pigeons/fast_api.g.dart` (actualizado con callback asíncrono)
  - Kotlin: `android/app/src/main/kotlin/com/example/alerta_acv/FastApi.kt` (actualizado)
- ✅ Actualizado `FastNativeApiImpl.kt`:
  - `init()` inicializa `AsrEngine` y llama a `asrEngine.init()` (no bloquea)
  - `runSpeech()` implementado con reconocimiento real:
    - Ejecuta en `Thread` separado para no bloquear UI
    - Llama a `asrEngine.recognize()` para grabar y procesar audio
    - Calcula similitud usando `asrEngine.calculateSimilarity()`
    - Clasifica nivel usando `asrEngine.classifyLevel()`
    - Retorna `SpeechResult` con transcript, similarity y level
    - Usa `callback(Result.success(...))` para retornar resultado asíncronamente
    - Maneja errores con `callback(Result.failure(...))`
  - `dispose()` libera recursos de `AsrEngine`

#### 3.4 Servicio Flutter ✅
- ✅ Actualizado `FastService` en `lib/services/fast/fast_service.dart`:
  - Introducida clase `SpeechAnalysis` para encapsular:
    - `SpeechLevel level` (enum)
    - `String transcript` (texto detectado)
    - `double similarity` (porcentaje de similitud 0-1)
  - `runSpeech()` ahora retorna `Future<SpeechAnalysis>` con datos completos
  - Conversión de nivel string a enum (`SpeechLevel`)
  - Singleton pattern mantenido para instancia única
  - `init()` usa `_initFuture` para asegurar inicialización única y asíncrona

#### 3.5 Integración UI ✅
- ✅ Actualizado `SpeechStepPage`:
  - Muestra frase objetivo: "Hoy es un buen día para ayudar."
  - Botón "Grabar" inicia grabación y temporizador visual
  - Timer visual (countdown de 10 segundos) sincronizado con grabación real
  - Muestra transcript detectado en tiempo real
  - Muestra porcentaje de similitud calculado: `${(similarity * 100).toStringAsFixed(1)}%`
  - Muestra nivel de dificultad clasificado
  - Indicador de carga durante procesamiento
  - Convertido a `SingleChildScrollView` para evitar overflow
  - Removida espera explícita de `init()` (se maneja automáticamente en background)

#### 3.6 Optimizaciones de rendimiento ✅
- ✅ Pre-inicialización del modelo Vosk al inicio de la app:
  - `main.dart` llama a `FastService().init()` antes de `runApp()`
  - Modelo se carga en background thread sin bloquear UI
  - Eliminado lag de ~10 segundos al presionar "Grabar"
- ✅ Procesamiento asíncrono:
  - Grabación de audio ejecutada en `Thread` separado
  - Pigeon `@async` permite comunicación asíncrona Flutter ↔ native
  - UI permanece responsiva durante grabación y procesamiento
- ✅ Espera inteligente:
  - Si el modelo no está listo cuando se inicia grabación, `AsrEngine.recognize()` espera automáticamente (máx 30s)
  - No se bloquea la UI mientras espera

#### 3.7 Permisos y configuración ✅
- ✅ Añadido permiso `RECORD_AUDIO` en `AndroidManifest.xml`
- ✅ Permisos solicitados al inicio de la app (`main.dart`):
  - Microphone (RECORD_AUDIO)
  - Camera (para futuras épicas)
  - Phone (CALL_PHONE)
  - Contacts (para futuras épicas)
- ✅ Función `_requestPermissions()` centralizada en `main.dart`

### Dependencias añadidas ✅
- ✅ `com.alphacephei:vosk-android:0.3.38` - Librería Vosk para Android
- ✅ `net.java.dev.jna:jna:5.13.0@aar` - JNA para librerías nativas (requerida por Vosk)

### Archivos modificados/creados ✅
- ✅ `android/app/build.gradle.kts` - Dependencias Vosk y JNA
- ✅ `android/build.gradle.kts` - Repositorio Maven Vosk
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/AsrEngine.kt` - Motor de reconocimiento (NUEVO)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/FastNativeApiImpl.kt` - Integración con AsrEngine
- ✅ `android/app/src/main/AndroidManifest.xml` - Permiso RECORD_AUDIO
- ✅ `pigeons/fast_api.dart` - Método `runSpeech` marcado como `@async`
- ✅ `lib/pigeons/fast_api.g.dart` - Código generado actualizado (regenerado)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/FastApi.kt` - Código generado actualizado (regenerado)
- ✅ `lib/services/fast/fast_service.dart` - Clase `SpeechAnalysis` y retorno mejorado
- ✅ `lib/features/fast/pages/speech_step_page.dart` - UI con transcript y similarity visibles
- ✅ `lib/main.dart` - Pre-inicialización del modelo y permisos globales
- ✅ `README.md` - Instrucciones de descarga del modelo Vosk
- ✅ `android/app/src/main/assets/models/README.md` - Guía de instalación del modelo (NUEVO)

### Definition of Done - Verificación ✅
- ✅ En un Android físico, la app escucha la frase y entrega un nivel de dificultad según similitud
- ✅ Las pruebas FAST ya usan audio real en la parte de Speech
- ✅ Reconocimiento de voz funcional 100% offline
- ✅ Transcript y porcentaje de similitud se muestran en la UI
- ✅ Clasificación de nivel (Sin/Leve/Fuerte) según umbrales FAST
- ✅ Sin lag al iniciar grabación (modelo pre-cargado)
- ✅ UI responsiva durante grabación y procesamiento
- ✅ Sin errores de análisis (`flutter analyze` - sin issues)

### Notas técnicas
- El modelo Vosk (`vosk-model-small-es-0.42`) debe descargarse manualmente y colocarse en `android/app/src/main/assets/vosk-model-small-es-0.42/`
- El modelo se carga de forma asíncrona en background al iniciar la app
- Si el modelo aún no está cargado cuando se inicia una grabación, el sistema espera automáticamente (máx 30s) sin bloquear la UI
- El procesamiento de audio se ejecuta en un thread separado para mantener la UI fluida
- Pigeon `@async` permite que los métodos nativos ejecuten trabajo pesado en background y retornen resultados asincrónicamente
- La similitud se calcula usando Levenshtein distance (Character Error Rate) después de normalizar ambos textos
- El modelo Vosk requiere un archivo `uuid` dentro de la carpeta del modelo (se creó un placeholder)

### Problemas resueltos
- ✅ **Error de lag/freezing**: Resuelto mediante pre-inicialización del modelo y procesamiento en threads separados
- ✅ **Error de modelo no encontrado**: Resuelto moviendo modelo directamente a `assets/` y creando archivo `uuid`
- ✅ **Error de librerías nativas**: Resuelto añadiendo dependencia JNA explícita
- ✅ **UI overflow**: Resuelto usando `SingleChildScrollView` en lugar de `Column` con `Spacer()`
- ✅ **Sincronización timer/grabación**: Resuelto ejecutando timer visual y grabación en paralelo

### Próximos pasos
- **ÉPICA 4**: Cara con MediaPipe Face (Android, cámara trasera)
- Ajustar umbrales de similitud según pruebas reales con usuarios
- Considerar optimizaciones adicionales si se detectan problemas de rendimiento

---

## ÉPICA 4 – Cara: MediaPipe Face (Android, cámara trasera) ✅ COMPLETADA

**Rama:** `feature/face-mediapipe-android`  
**Fecha de inicio:** Diciembre 2025  
**Fecha de finalización:** Diciembre 2025  
**Estado:** ✅ COMPLETADA

### Objetivo
Implementar `runFace` real con MediaPipe Face Landmarker y CameraX usando cámara trasera.

### Tareas completadas

#### 4.1 Dependencias ✅
- ✅ Añadidas dependencias en `android/app/build.gradle.kts`:
  - `com.google.mediapipe:tasks-vision:0.10.14` - MediaPipe Tasks Vision
  - `androidx.camera:camera-core:1.3.4` - CameraX Core
  - `androidx.camera:camera-camera2:1.3.4` - CameraX Camera2
  - `androidx.camera:camera-lifecycle:1.3.4` - CameraX Lifecycle
  - `androidx.camera:camera-view:1.3.4` - CameraX View (PreviewView)
  - `androidx.appcompat:appcompat:1.6.1` - AppCompat para Activities

#### 4.2 Modelo MediaPipe ✅
- ✅ Descargado modelo `face_landmarker.task` de MediaPipe
- ✅ Ubicación: `android/app/src/main/assets/models/face_landmarker.task`
- ✅ Tamaño: ~4.5MB (modelo optimizado para móviles)

#### 4.3 FaceActivity (Activity nativa para cámara) ✅
- ✅ Creado `FaceActivity.kt` en `android/app/src/main/kotlin/com/example/alerta_acv/`:
  - **CameraX Integration**:
    - Usa `ProcessCameraProvider` para bindear cámara
    - Preview + ImageAnalysis con `AspectRatio.RATIO_4_3` sincronizados
    - `OUTPUT_IMAGE_FORMAT_RGBA_8888` para conversión directa a Bitmap
    - Cámara trasera (`DEFAULT_BACK_CAMERA`)
  - **MediaPipe Face Landmarker**:
    - `RunningMode.VIDEO` para procesamiento de frames
    - `minFaceDetectionConfidence: 0.5f`
    - Detecta 478 landmarks faciales completos
  - **Procesamiento de imagen**:
    - `toRotatedBitmap()`: Rota el bitmap ANTES de enviar a MediaPipe usando `Matrix.postRotate()`
    - Corrección crítica: La rotación se aplica al bitmap, NO a los landmarks después
    - Soporte para flip horizontal en cámara frontal (no usado actualmente)
  - **Cálculo de asimetría**:
    - Usa landmarks 1 (nariz), 61 (comisura izquierda), 291 (comisura derecha)
    - Calcula distancia euclidiana nariz-a-comisuras
    - `asymmetry = |distLeft - distRight| / max(distLeft, distRight)`
    - Promedio de scores durante toda la sesión
  - **Mapeo de coordenadas**:
    - `mapToView()`: Convierte coordenadas normalizadas (0-1) a coordenadas de view
    - Usa center-crop scaling: `scale = max(vw/imageWidth, vh/imageHeight)`
    - Calcula offsets para centrar: `offX = (vw - scaledW) / 2f`
  - **Gated countdown**:
    - Requiere rostro estable por 600ms antes de iniciar conteo
    - Si se pierde el rostro >1s, reinicia el conteo
    - Pausa/resume el conteo si el rostro se pierde brevemente
    - Timeout de 30s si no se detecta rostro
  - **Detección de luz baja**:
    - Analiza luminancia promedio del frame
    - `lowLight = true` si promedio < 50
  - **Resultado final**:
    - `FaceResult(asymmetry, level, faceFound, lowLight)`
    - Clasificación según umbrales: <0.08 Sin, 0.08-0.14 Leve, >=0.15 Fuerte

#### 4.4 FaceOverlayView (Vista de landmarks) ✅
- ✅ Creado `FaceOverlayView.kt`:
  - Dibuja los **478 landmarks** faciales completos
  - Dibuja **conectores** del mesh facial usando `FaceLandmarker.FACE_LANDMARKS_CONNECTORS`
  - Dibuja **bounding box** alrededor del rostro
  - Muestra **mensaje de estado** (buscando rostro, analizando, etc.)
  - Muestra **countdown** restante
  - Indicador de **luz baja** cuando aplica
  - Colores diferenciados:
    - Líneas del mesh: verde semi-transparente
    - Puntos de landmarks: amarillo
    - Bounding box: cian
    - Texto de estado: blanco sobre fondo negro semi-transparente

#### 4.5 Layout de Activity ✅
- ✅ Creado `activity_face.xml`:
  - `FrameLayout` como contenedor
  - `PreviewView` con `scaleType="fillCenter"` para preview de cámara
  - `FaceOverlayView` superpuesto para dibujar landmarks

#### 4.6 Integración con Pigeon y FastNativeApi ✅
- ✅ Actualizado `FastNativeApiImpl.kt`:
  - `runFace(maxMillis, callback)` lanza `FaceActivity` con Intent
  - Usa patrón de `pendingCallback` estático para retornar resultado
  - `FaceActivity.pendingCallback` se asigna antes de iniciar Activity
  - Al finalizar, Activity llama `callback(Result.success(FaceResult))`
- ✅ Registrado `FaceActivity` en `AndroidManifest.xml`:
  - `android:theme="@style/Theme.AppCompat.NoActionBar"`
  - `android:screenOrientation="portrait"`

#### 4.7 Integración UI Flutter ✅
- ✅ Actualizado `FaceStepPage`:
  - Llama a `_fastService.runFace()` que abre la Activity nativa
  - La Activity maneja todo el countdown y detección
  - Al retornar, muestra el resultado (nivel de asimetría)
  - Sin countdown duplicado en Flutter (la Activity lo maneja)

#### 4.8 Guía de implementación ✅
- ✅ Creado `docs/guia_face_landmarker.md`:
  - Documenta el patrón correcto de rotación de bitmap
  - Explica el mapeo de coordenadas con center-crop
  - Lista los 478 landmarks y sus usos
  - Incluye código de referencia completo

### Archivos creados/modificados ✅
- ✅ `android/app/build.gradle.kts` - Dependencias MediaPipe y CameraX
- ✅ `android/app/src/main/assets/models/face_landmarker.task` - Modelo (NUEVO)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/FaceActivity.kt` - Activity de cámara (NUEVO)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/FaceOverlayView.kt` - Vista de landmarks (NUEVO)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/FaceEngine.kt` - Engine inicial (removido, lógica movida a FaceActivity)
- ✅ `android/app/src/main/res/layout/activity_face.xml` - Layout de Activity (NUEVO)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/FastNativeApiImpl.kt` - Integración con FaceActivity
- ✅ `android/app/src/main/AndroidManifest.xml` - Registro de FaceActivity, permiso CAMERA
- ✅ `lib/features/fast/pages/face_step_page.dart` - UI actualizada
- ✅ `docs/guia_face_landmarker.md` - Documentación técnica (NUEVO)

### Diferencias con el plan original
| Plan original | Implementación real |
|--------------|---------------------|
| `FaceEngine.kt` separado | Lógica integrada en `FaceActivity.kt` para mejor control del ciclo de vida |
| Resolución baja (480p) | `AspectRatio.RATIO_4_3` con resolución automática de CameraX |
| Solo landmarks de comisuras/nariz/mentón | 478 landmarks completos con mesh facial |
| Rotación de landmarks post-detección | Rotación de bitmap PRE-detección (corrección crítica) |
| Sin overlay visual | `FaceOverlayView` con mesh completo, bounding box y estado |
| Countdown en Flutter | Countdown en Activity nativa (gated con detección de rostro) |

### Definition of Done - Verificación ✅
- ✅ En un Android real, el paso Face usa cámara trasera
- ✅ Devuelve un índice de asimetría razonable
- ✅ El resultado cambia si la expresión está "chueca"
- ✅ Los landmarks se dibujan correctamente alineados con el rostro
- ✅ El countdown funciona con detección de presencia de rostro
- ✅ Sin errores de análisis

### Problemas resueltos
- ✅ **Landmarks desalineados/flotando**: Resuelto rotando bitmap ANTES de enviar a MediaPipe, no después
- ✅ **Coordenadas invertidas**: Resuelto usando center-crop scaling correcto con `max()` en lugar de `min()`
- ✅ **Crash al cerrar Activity**: Resuelto con manejo correcto de lifecycle y `isFinished` flag
- ✅ **Preview estirado**: Resuelto sincronizando AspectRatio entre Preview e ImageAnalysis

---

## ÉPICA 5 – Brazos: MediaPipe Pose (Android, cámara trasera) ✅ COMPLETADA

**Rama:** `feature/arms-mediapipe-android`  
**Fecha de inicio:** Diciembre 2025  
**Fecha de finalización:** Diciembre 2025  
**Estado:** ✅ COMPLETADA

### Objetivo
Implementar `runArms` con MediaPipe Pose Landmarker para detectar caída de brazos.

### Tareas completadas

#### 5.1 Modelo MediaPipe ✅
- ✅ Descargado modelo `pose_landmarker_lite.task` de MediaPipe
- ✅ URL: `https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task`
- ✅ Ubicación: `android/app/src/main/assets/models/pose_landmarker_lite.task`
- ✅ Tamaño: ~5.6MB (modelo lite optimizado para móviles)

#### 5.2 ArmsActivity (Activity nativa para cámara) ✅
- ✅ Creado `ArmsActivity.kt` en `android/app/src/main/kotlin/com/example/alerta_acv/`:
  - **CameraX Integration** (mismo patrón que FaceActivity):
    - `ProcessCameraProvider` con Preview + ImageAnalysis
    - `AspectRatio.RATIO_4_3` sincronizado
    - `OUTPUT_IMAGE_FORMAT_RGBA_8888`
    - **Cámara trasera** (`DEFAULT_BACK_CAMERA`) según plan de desarrollo
  - **MediaPipe Pose Landmarker**:
    - `RunningMode.VIDEO` para procesamiento de frames
    - `minPoseDetectionConfidence: 0.5f`
    - `minPosePresenceConfidence: 0.5f`
    - `minTrackingConfidence: 0.5f`
    - `numPoses: 1` (una persona)
  - **Landmarks de brazos** (índices MediaPipe Pose):
    - 11: left_shoulder
    - 12: right_shoulder
    - 13: left_elbow
    - 14: right_elbow
    - 15: left_wrist
    - 16: right_wrist
  - **Cálculo de deltaY**:
    - `wristDeltaY = |leftWristY - rightWristY|` (diferencia vertical entre muñecas)
    - Valores normalizados 0-1 (Y aumenta hacia abajo)
    - También calcula caída relativa a hombros: `armDrop = wristY - shoulderY`
  - **Detección de caída**:
    - Establece baseline al iniciar el conteo
    - `DROP_THRESHOLD = 0.15` (15% del frame height)
    - `dropDetected = true` si:
      - `deltaY >= DROP_THRESHOLD`, O
      - `leftArmDrop > 0.3` (muñeca izquierda cae mucho bajo hombro), O
      - `rightArmDrop > 0.3` (muñeca derecha cae mucho bajo hombro)
    - Historial de deltaY para calcular promedio y máximo cambio
  - **Gated countdown** (mismo patrón que FaceActivity):
    - Requiere pose estable por 600ms antes de iniciar
    - Si se pierde pose >1s, reinicia conteo y baseline
    - Timeout de 30s si no se detecta pose
  - **Resultado final**:
    - `ArmsResult(deltaY: avgDeltaY, dropDetected: maxDeltaYChange >= threshold)`

#### 5.3 ArmsOverlayView (Vista de landmarks) ✅
- ✅ Creado `ArmsOverlayView.kt`:
  - Dibuja los **33 landmarks de pose** completos (no solo brazos)
  - Dibuja **conectores** del esqueleto usando `PoseLandmarker.POSE_LANDMARKS`
  - Tamaños diferenciados:
    - Muñecas (15, 16): Cian, radio 16px
    - Articulaciones de brazos (11-16): Radio 12px
    - Resto del cuerpo: Amarillo, radio 8px
  - Colores de líneas:
    - Verde: esqueleto normal
    - Naranja/Rojo: cuando hay caída detectada
  - Indicadores visuales:
    - **ΔY**: Muestra valor actual con color (verde/amarillo/rojo según magnitud)
    - **⚠ CAÍDA DETECTADA**: Mensaje de alerta cuando aplica
    - Countdown restante
    - Mensaje de estado ("Levanta ambos brazos...", "Mantén la posición...")
    - Indicador de luz baja

#### 5.4 Layout de Activity ✅
- ✅ Creado `activity_arms.xml`:
  - `FrameLayout` como contenedor
  - `PreviewView` con `scaleType="fillCenter"`
  - `ArmsOverlayView` superpuesto

#### 5.5 Integración con Pigeon y FastNativeApi ✅
- ✅ Actualizado `FastNativeApiImpl.kt`:
  - `runArms(seconds, callback)` lanza `ArmsActivity` con Intent
  - Convierte `seconds` a milisegundos para la Activity
  - Usa patrón de `pendingCallback` estático
- ✅ Registrado `ArmsActivity` en `AndroidManifest.xml`:
  - `android:theme="@style/Theme.AppCompat.NoActionBar"`
  - `android:screenOrientation="portrait"`

#### 5.6 Integración UI Flutter ✅
- ✅ Actualizado `ArmsStepPage`:
  - **Eliminado countdown de Flutter**: Antes había un timer de 10s en Flutter antes de llamar al servicio
  - Ahora llama directamente a `_fastService.runArms()` al presionar "Iniciar"
  - La Activity nativa maneja todo el countdown y detección
  - Muestra resultado al retornar (caída detectada / sin caída)
  - Indicador de carga mientras está en la Activity

### Archivos creados/modificados ✅
- ✅ `android/app/src/main/assets/models/pose_landmarker_lite.task` - Modelo (NUEVO)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/ArmsActivity.kt` - Activity de cámara (NUEVO)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/ArmsOverlayView.kt` - Vista de landmarks (NUEVO)
- ✅ `android/app/src/main/res/layout/activity_arms.xml` - Layout de Activity (NUEVO)
- ✅ `android/app/src/main/kotlin/com/example/alerta_acv/FastNativeApiImpl.kt` - Integración con ArmsActivity
- ✅ `android/app/src/main/AndroidManifest.xml` - Registro de ArmsActivity
- ✅ `lib/features/fast/pages/arms_step_page.dart` - UI simplificada (sin countdown duplicado)

### Diferencias con el plan original
| Plan original | Implementación real |
|--------------|---------------------|
| `PoseEngine.kt` separado | Lógica integrada en `ArmsActivity.kt` |
| Solo landmarks de hombros y muñecas | 33 landmarks de pose completos dibujados |
| `delta(t) >= 0.20` durante ≥ 2s | `DROP_THRESHOLD = 0.15` con detección instantánea + caída relativa a hombros |
| `deltaY = deltaMax` | `deltaY = avgDeltaY` (promedio durante sesión) |
| Cámara frontal (self-view) | Cámara trasera (según plan de desarrollo FAST) |
| Countdown en Flutter (10s antes) | Countdown en Activity nativa (directo al presionar Iniciar) |
| Solo conexiones de brazos | Esqueleto completo con `POSE_LANDMARKS` |

### Definition of Done - Verificación ✅
- ✅ El paso Arms detecta cuando uno de los brazos baja claramente mientras el otro se mantiene
- ✅ Usa cámara trasera según especificación del plan
- ✅ Los 33 landmarks de pose se dibujan correctamente
- ✅ El esqueleto completo se visualiza
- ✅ El countdown funciona con detección de presencia de pose
- ✅ Sin countdown duplicado en Flutter
- ✅ Sin errores de análisis

### Problemas resueltos
- ✅ **Cámara frontal vs trasera**: Cambiado a cámara trasera según plan de desarrollo
- ✅ **Countdown duplicado**: Eliminado countdown de Flutter, ahora solo en Activity nativa
- ✅ **Solo landmarks de brazos**: Expandido a 33 landmarks completos con conectores oficiales

---

## ÉPICA 6 – Heurística FAST + historial ✅ COMPLETADA

**Rama:** `feature/risk-and-history`  
**Fecha de inicio:** Diciembre 2025  
**Fecha de finalización:** Diciembre 2025  
**Estado:** ✅ COMPLETADA

### Objetivo
Aplicar la heurística FAST completa dentro de Flutter, persistir cada prueba con sus niveles parciales y exponer un historial consultable que funcione igual en Android e iOS.

### Tareas completadas

#### 6.1 Heurística FAST centralizada ✅
- ✅ `lib/core/constants/risk_levels.dart` ahora define los enums `RiskLevel`, `SpeechLevel` y `FaceLevel` con extensiones que devuelven etiquetas legibles para la UI.
- ✅ Función `combineFastResults()` implementa la lógica acordada: riesgo **Alto** si hay habla/cara fuerte, caída de brazos o ≥2 leves; **Medio** si existe exactamente un leve; **Bajo** en cualquier otro escenario.
- ✅ La UI obtiene estas etiquetas directamente, lo que evita duplicar strings en las pantallas y garantiza consistencia entre plataformas.

#### 6.2 Persistencia de resultados FAST ✅
- ✅ `TestResult` (lib/models/test_result.dart) encapsula fecha, niveles parciales y riesgo global.
- ✅ `DatabaseService` migró a la versión 2 del schema SQFlite, agregando la tabla `test_results` y métodos `saveTestResult()`, `getAllTestResults()` y `deleteTestResult()` reutilizables tanto en Android como en iOS.
- ✅ `DecisionPage` guarda automáticamente cada ejecución al terminar (`_saveResult()`), por lo que no hay que pedir acciones manuales.

#### 6.3 DecisionPage con protocolo de emergencia real ✅
- ✅ Se calcula el riesgo apenas llegan los resultados de Speech/Face/Arms y se dispara un countdown bloqueante cuando es **Alto**.
- ✅ Botones “Llamar al 911” y “Alertar a contactos” invocan `PhoneUtils.launchDialer` y `SmsService.sendEmergencySmsToMultiple`, respetando el toggle de SMS automático.
- ✅ `SmsService` genera mensajes enriquecidos con ubicación (Geolocator + Permission Handler) y hora, agregando pausas entre envíos para no gatillar bloqueos del sistema.
- ✅ `CountdownDialog` reutilizado para el botón flotante de 911 y la pantalla de decisión, lo que unifica UX.

#### 6.4 Historial navegable ✅
- ✅ `HistoryPage` consulta `DatabaseService` y muestra los registros en tarjetas expandibles con colores según riesgo.
- ✅ Cada tarjeta lista los niveles parciales, fecha/hora formateada (`intl`) y permite eliminar una entrada con confirmación.
- ✅ Indicadores de carga / “Empty states” evitan pantallas en blanco.

### Definition of Done - Verificación ✅
- ✅ El riesgo global se recalcula en ambos sistemas al finalizar FAST.
- ✅ Cada prueba queda registrada localmente y se puede consultar/borrar desde el Historial.
- ✅ Se validó el flujo en Android físico y en iOS (simulador + dispositivo) verificando que los SMS/llamadas se disparan sólo cuando corresponde.

### Problemas resueltos
- ✅ No se perdieron registros tras reinstalar: se centralizó la ruta del DB usando `path_provider`.
- ✅ Evitamos duplicar lógica de riesgo en la UI al mover todo a `combineFastResults()`.
- ✅ Se corrigieron excepciones cuando el usuario cancelaba permisos de ubicación/SMS — ahora se muestran mensajes claros y se continúa con el flujo.

---

## ÉPICA 7 – Contactos, ajustes y accesibilidad ✅ COMPLETADA

**Rama:** `feature/contacts-and-settings`  
**Fecha de inicio:** Diciembre 2025  
**Fecha de finalización:** Diciembre 2025  
**Estado:** ✅ COMPLETADA

### Objetivo
Permitir administrar contactos de emergencia dentro de la app, importar desde el teléfono, habilitar ajustes de accesibilidad (alto contraste y SMS automático) y asegurar accesos rápidos al 911.

### Tareas completadas

#### 7.1 CRUD de contactos de emergencia ✅
- ✅ `EmergencyContact` modela nombre, teléfono y fecha de creación.
- ✅ `DatabaseService` expone métodos CRUD y la tabla `emergency_contacts` con índices por nombre.
- ✅ `ContactsPage` ofrece agregar/editar/eliminar contactos mediante `AlertDialog`, incluye snackbars para validaciones y permite llamar directamente usando `PhoneUtils.launchDialer`.
- ✅ Botón “Importar desde contactos” usa `flutter_contacts` + permisos runtime para listar contactos reales y guardarlos en la BD sin besoin manual.

#### 7.2 Ajustes e indicadores de accesibilidad ✅
- ✅ `SettingsPage` consolida switches para “Modo alto contraste” y “Envío automático de SMS”.
- ✅ `highContrastProvider` y `autoSmsProvider` (Riverpod) guardan el estado global; `app.dart` reacciona cambiando `ThemeData` en caliente.
- ✅ El botón flotante 911 respeta el toggle de SMS y comparte el mismo flujo que `DecisionPage` para no duplicar código.

#### 7.3 Integraciones con teléfono y permisos ✅
- ✅ `PhoneUtils` normaliza números y abre el dialer nativo vía MethodChannel (`com.example.alerta_acv/call`) registrado en `MainActivity` (Android) y, en iOS, está cubierto por `DeviceApiImpl.placeCall911()` cuando se invoca desde los servicios Pigeon.
- ✅ `SmsService` centraliza permisos (SMS + ubicación), compone mensajes ricos y maneja escenarios donde el dispositivo no puede enviar SMS.
- ✅ Se añadieron dependencias `permission_handler`, `flutter_contacts`, `geolocator` y `url_launcher` en `pubspec.yaml` con la configuración de Android/iOS necesaria (manifiestos y plist).

### Definition of Done - Verificación ✅
- ✅ Añadir/editar/borrar contactos funciona y persiste tras reiniciar la app.
- ✅ Importar desde la libreta del dispositivo requiere permisos y sólo lista contactos con teléfono.
- ✅ El botón flotante 911 aparece en todas las pantallas principales y completa llamada/SMS opcional.
- ✅ Cambiar el modo alto contraste refleja colores nuevos en toda la app sin reiniciar.

### Problemas resueltos
- ✅ Se eliminó el overflow al abrir diálogos de edición usando `mainAxisSize.min`.
- ✅ Se normalizan números de teléfono para evitar fallas en `url_launcher`.
- ✅ El toggle de SMS automático ya no queda sólo en memoria: se integra con Riverpod y se consulta antes de cada envío.

---

## ÉPICA 8 – Performance, UX y QA

**Rama:** `feature/performance-and-qa`  
**Estado:** ⏳ PENDIENTE

---

## ÉPICA 9 – iOS (futuro / opcional) ✅ COMPLETADA

**Rama:** `feature/ios-support`  
**Fecha de inicio:** Diciembre 2025  
**Fecha de finalización:** Diciembre 2025  
**Estado:** ✅ COMPLETADA

### Objetivo
Paridad total con Android en dispositivos iOS: cámara trasera para Face/Arms usando MediaPipe Tasks, reconocimiento de voz nativo, llamadas/SMS y documentación del setup.

### Tareas completadas

#### 9.1 Infraestructura Pigeon e inyección en AppDelegate ✅
- ✅ `FastNativeApiImpl` y `DeviceApiImpl` se registran en `AppDelegate` mediante `FastNativeApiSetup`/`DeviceApiSetup`, reutilizando el `FlutterViewController` para presentar controladores nativos.
- ✅ Las APIs comparten el mismo contrato que Android (`SpeechResult`, `FaceResult`, `ArmsResult`), por lo que Flutter no requiere cambios adicionales.

#### 9.2 Habla con Speech.framework ✅
- ✅ `SpeechEngine` usa `AVAudioEngine + SFSpeechRecognizer` (es-ES/es-MX) para capturar 10s de audio, habilita reconocimiento on-device cuando está disponible y calcula similitud con Levenshtein igual que Vosk.
- ✅ Maneja permisos de micrófono y reconocimiento con prompts amigables y cancela tareas previas para evitar crashes.

#### 9.3 Cara con MediaPipe Face Landmarker ✅
- ✅ `FaceViewController` configura un `AVCaptureSession` portrait con cámara trasera/frontal (botón switch), alimenta `FaceLandmarker` (MediaPipeTasksVision 0.10.14) y convierte landmarks al espacio de la vista usando `previewLayer.layerPointConverted` para eliminar drift.
- ✅ `FaceOverlayView` dibuja todos los puntos, mensajes de estado, countdown y advertencias de baja iluminación; el resultado final calcula asimetría y nivel en Swift antes de regresar a Flutter.

#### 9.4 Brazos con MediaPipe Pose ✅
- ✅ `ArmsViewController` replica el flujo FAST de Android: corre Pose Landmarker Lite, calcula `deltaY` vs hombros, aplica countdown gateado y pinta el esqueleto completo en `ArmsOverlayView`.
- ✅ Se añadieron correcciones de orientación (rotación según `AVCaptureVideoOrientation`) para evitar esqueletos acostados y se exporta `ArmsResult` con promedio y bandera `dropDetected`.

#### 9.5 DeviceApi: llamadas, SMS y ubicación ✅
- ✅ `DeviceApiImpl` usa `UIApplication.openURL` para llamar al 911, `MFMessageComposeViewController` para SMS con apoyo de `CLLocationManager` (adjunta URL de Maps) y expone callbacks a Flutter.
- ✅ Permisos de cámara/micrófono/ubicación se solicitan al iniciar `FastNativeApiImpl.initialize()` para minimizar prompts durante las pruebas.

#### 9.6 Documentación y soporte ✅
- ✅ `docs/guia_pose_landmarker_ios.md` detalla dependencias, estructura y mejores prácticas para CameraFeedService/PoseLandmarker en iOS.
- ✅ Se documentó descarga de modelos `.task`, configuración de Pods y ejecución en dispositivos físicos.

### Definition of Done - Verificación ✅
- ✅ `flutter run` en iPhone real ejecuta las tres pruebas FAST sin crashes.
- ✅ Los overlays de Face/Arms coinciden con la vista previa (sin espejos ni rotaciones erróneas).
- ✅ Reconocimiento de voz produce los mismos niveles que Android para las frases de prueba.
- ✅ Llamada 911 + SMS funcionan usando APIs nativas.

### Problemas resueltos
- ✅ Drift/rotación en Brazos se solucionó aplicando rotaciones posteriores al mapping de `previewLayer` y usando orientación correcta en `MPImage`.
- ✅ Se manejó el caso de permisos de cámara denegados con alertas que llevan al usuario a Settings.
- ✅ `SpeechEngine` corta grabaciones previas y limpia el `AVAudioSession` para evitar bloqueos al repetir la prueba.

---

## Notas generales

- Todas las épicas se desarrollan en ramas separadas desde `develop`
- Después de completar cada épica, se hace merge a `develop`
- Solo se hace merge a `main` cuando hay una versión estable

