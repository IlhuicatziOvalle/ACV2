# Alerta ACV – Development Plan (MVP)

## 0. Visión del MVP

**Alerta ACV** es una app móvil Flutter (Android/iOS) que ayuda a un tercero a detectar posibles signos tempranos de ACV usando FAST:

* **Face** (cara, con cámara trasera) – 5s de video.
* **Arms** (brazos, con cámara trasera) – 10s de video.
* **Speech** (habla, micrófono) – 8–10s de audio con la frase:

  > “Hoy es un buen día para ayudar.”

La app:

* Funciona **100% offline**.
* Está optimizada para **Android gama media/baja**.
* Usa solo **cámara trasera**.
* Da un nivel de riesgo (Bajo/Medio/Alto) y facilita la **llamada al 911**.
* NO es diagnóstico médico (solo apoyo educativo).

---

## 1. Git & ramas

* `main` → rama estable.
* `develop` → integración del MVP.
* `feature/...` → ramas por épica/feature.

Sugerencias de ramas:

* `feature/architecture-and-ui`
* `feature/pigeon-and-stubs`
* `feature/voice-vosk-android`
* `feature/face-mediapipe-android`
* `feature/arms-mediapipe-android`
* `feature/risk-and-history`
* `feature/contacts-and-settings`
* `feature/performance-and-qa`
* `feature/ios-support` (futuro / opcional)

---

## 2. Constantes clave (FAST versión app)

Centralizar en un archivo Dart (ej. `lib/core/constants/fast_constants.dart`):

* Duraciones:

  * `faceSeconds = 5`
  * `armsSeconds = 10`
  * `speechSeconds = 10`
* Umbrales habla (similaridad 0–1):

  * `>= 0.80` → sin dificultad
  * `0.60–0.79` → leve
  * `< 0.60` → fuerte
* Umbrales cara (asimetría 0–1):

  * `< 0.08` → sin asimetría
  * `0.08–0.14` → leve
  * `>= 0.15` → fuerte
* Brazos:

  * `delta(t) ≥ 0.20` durante ≥ 2s → caída detectada
* Riesgo global:

  * **ALTO** si:

    * habla fuerte, o
    * cara fuerte, o
    * caída detectada, o
    * ≥ 2 leves
  * **MEDIO** si exactamente 1 leve
  * **BAJO** si 0 leves/fuertes

---

## ÉPICA 1 – Arquitectura base + UI FAST con mocks

**Rama sugerida:** `feature/architecture-and-ui`
**Objetivo:** tener toda la UI y flujo FAST funcional, pero con datos mock (sin nativo todavía).

### 1.1 Setup Flutter & dependencias

* Añadir a `pubspec.yaml`:

  * `go_router`
  * `flutter_riverpod`
  * `flutter_tts`
  * `permission_handler`
  * `url_launcher`
  * `isar` o `sqflite` + `path_provider`
  * `flutter_secure_storage`
  * `intl`
* Crear estructura:

```text
lib/
  main.dart
  app.dart
  core/
    routing/
    theme/
    di/
    constants/
  features/
    fast/
    history/
    contacts/
    settings/
    help/
  services/
    device/
  l10n/
```

* Configurar:

  * `app_router.dart` con rutas:

    * `/` (Home)
    * `/fast/face`
    * `/fast/arms`
    * `/fast/speech`
    * `/fast/decision`
    * `/history`
    * `/contacts`
    * `/settings`
    * `/help`
  * `app_theme.dart` con tema claro + modo alto contraste opcional.
  * `intl_es.arb` con textos críticos (disclaimer, mensajes de riesgo, etc.).

### 1.2 UI FAST (mock)

* **HomePage**

  * Botón “Iniciar prueba FAST”.
  * Botón 911 permanente (usa `url_launcher` con `tel:911`).
  * Accesos a Historial, Contactos, Ajustes, Ayuda.
  * Disclaimer visible: “Esta app no proporciona diagnóstico médico. Ante cualquier duda, llama al 911.”

* **FaceStepPage (mock)**

  * Instrucciones para usar cámara trasera:

    * “Coloca a la persona en cuadro y pídele que sonría por 5 segundos.”
  * Temporizador de 5 s (solo animación).
  * Resultado mock: enum `FaceLevel { sin, leve, fuerte }` (por ahora hardcode).

* **ArmsStepPage (mock)**

  * Instrucciones:

    * “Pídele que levante ambos brazos al frente y los mantenga arriba mientras contamos 10.”
  * Temporizador 10 s.
  * Resultado mock: `dropDetected = true/false`.

* **SpeechStepPage (mock)**

  * Muestra frase: “Hoy es un buen día para ayudar.”
  * Botón de grabar (solo flujo visual).
  * Resultado mock: `SpeechLevel { sin, leve, fuerte }`.

* **DecisionPage**

  * Combina los niveles mock usando la heurística.
  * Muestra riesgo global (Bajo/Medio/Alto).
  * Si ALTO:

    * Cuenta regresiva 10 s.
    * Sonido suave (opcional).
    * Botón “Cancelar”.
    * Al terminar, botón para llamar al 911 (o llamado directo con permiso).

* **Botón 911 global**

  * Crear widget `Floating911Button` y colocarlo en un `Stack` o `Scaffold` común para todas las pantallas.

### 1.3 Modo alto contraste (básico)

* Añadir en Settings un toggle “Modo alto contraste”.
* Cambiar ThemeData para mayor contraste (ej. fondo oscuro + texto claro).

**Definition of Done Épica 1:**

* App corre en Android.
* Se puede completar todo el flujo FAST con datos mock.
* Botón 911 siempre visible.
* UI entendible y accesible (texto ≥ 16sp).

---

## ÉPICA 2 – Pigeon + servicios nativos (stubs)

**Rama:** `feature/pigeon-and-stubs`
**Objetivo:** tener la interfaz Flutter ↔ nativo lista, aunque la lógica nativa aún sea stub.

### 2.1 Definir APIs Pigeon

Crear `pigeons/fast_api.dart`:

* Clases:

  * `SpeechResult { String transcript; double similarity; String level; }`
  * `FaceResult { double asymmetry; String level; bool faceFound; bool lowLight; }`
  * `ArmsResult { double deltaY; bool dropDetected; }`
* Host APIs:

  * `FastNativeApi`:

    * `void init()`
    * `SpeechResult runSpeech(String targetPhrase, int maxSeconds)`
    * `FaceResult runFace(int maxMillis)`
    * `ArmsResult runArms(int seconds)`
    * `void dispose()`
  * `DeviceApi`:

    * `bool placeCall911()`
    * `bool sendEmergencySms(String message, bool includeLocation)`

Generar código para Dart/Kotlin/Swift.

### 2.2 Stubs nativos Android

* Implementar `FastNativeApi` en Kotlin con retornos simulados:

  * `runSpeech` → transcript “hoy es un buen dia para ayudar”, similarity 0.9, level “Sin”.
  * `runFace` → asymmetry 0.05, level “Sin”.
  * `runArms` → deltaY 0.1, dropDetected false.

### 2.3 Servicio Flutter

* Crear `FastService` en Dart que wrappee las clases generadas por Pigeon.
* Conectar la UI (épica 1) para que llame a `FastService` en vez de mocks hardcoded.

**DoD Épica 2:**

* UI sigue funcionando igual, pero ahora los datos vienen de Pigeon (stubs nativos).
* No hay lógica ML real aún.

---

## ÉPICA 3 – Voz offline con Vosk (Android)

**Rama:** `feature/voice-vosk-android`
**Objetivo:** implementar `runSpeech` real en Android usando Vosk.

### 3.1 Integración Vosk

* En `android/app/build.gradle`:

```gradle
implementation "org.vosk:android:0.3.38"
```

* Modelo:

  * Descargar `vosk-model-small-es-0.42`.
  * Colocar en:

    * `android/app/src/main/assets/models/vosk-model-small-es-0.42/`.

### 3.2 AsrEngine

Crear `AsrEngine.kt`:

* Carga perezosa del modelo Vosk.
* Graba audio con `AudioRecord` (16kHz mono, PCM16) por `maxSeconds`.
* Procesa con `Recognizer`.
* Obtiene `transcript`.
* Calcula `similaridad` con la frase objetivo usando Levenshtein/CER.
* Clasifica `level` (“Sin”, “Leve”, “Fuerte”) según constantes compartidas (puedes duplicar lógicamente en nativo o devolver solo `similarity` y clasificar en Dart).

### 3.3 Integración

* Modificar `FastNativeApiImpl.runSpeech` para usar `AsrEngine`.
* En Flutter, mostrar transcript real y similarity para debug.

**DoD Épica 3:**

* En un Android físico, la app escucha la frase y entrega un nivel de dificultad según similitud.
* Las pruebas FAST ya usan audio real en la parte de Speech.

---

## ÉPICA 4 – Cara: MediaPipe Face (Android, cámara trasera)

**Rama:** `feature/face-mediapipe-android`
**Objetivo:** implementar `runFace` real con MediaPipe y CameraX.

### 4.1 Dependencias

En `android/app/build.gradle`:

```gradle
implementation "com.google.mediapipe:tasks-vision:0.20230726"
implementation "androidx.camera:camera-core:1.3.4"
implementation "androidx.camera:camera-camera2:1.3.4"
implementation "androidx.camera:camera-lifecycle:1.3.4"
implementation "androidx.camera:camera-view:1.3.4"
```

### 4.2 FaceEngine

* Usar CameraX con cámara trasera, resolución baja (ej. 480p).
* Procesar frames 5s con MediaPipe Face Landmarker.
* Para cada frame:

  * Obtener landmarks de:

    * comisuras de boca izquierda/derecha,
    * nariz,
    * mentón.
  * Calcular `asymmetry` normalizada según la fórmula diseñada.
* Agregar:

  * `faceFound` = true si hay rostro.
  * `lowLight` = true si brillo del frame está por debajo de un umbral.
* Resumir en un valor final (`asymmetry` robusto, p. ej. promedio o percentil 75).

### 4.3 Integración

* `runFace(maxMillis)` llama a `FaceEngine`, procesa durante ~5s, devuelve `FaceResult`.
* En Flutter, se clasifica según `asymmetry` usando los umbrales.

**DoD Épica 4:**

* En un Android real, el paso Face usa cámara trasera y devuelve un índice de asimetría razonable.
* El resultado cambia si la expresión está “chueca”.

---

## ÉPICA 5 – Brazos: MediaPipe Pose (Android, cámara trasera)

**Rama:** `feature/arms-mediapipe-android`
**Objetivo:** implementar `runArms` con Pose Landmarker.

### 5.1 PoseEngine

* Reusar CameraX (cámara trasera).
* Durante 10s:

  * Para cada frame, obtener landmarks de:

    * hombros,
    * muñecas (izquierda y derecha).
  * Normalizar alturas respecto al torso.
  * Calcular `delta(t) = |yL - yR|`.
* Detectar:

  * `dropDetected = true` si hay ≥ 2s continuos con `delta(t) ≥ 0.20`.
* Devolver:

  * `deltaY` = `deltaMax`,
  * `dropDetected`.

### 5.2 Integración

* `runArms(seconds)` usa `PoseEngine`.
* UI de Arms muestra “Caída detectada” o no.

**DoD Épica 5:**

* El paso Arms detecta cuando uno de los brazos baja claramente mientras el otro se mantiene.

---

## ÉPICA 6 – Heurística FAST + historial

**Rama:** `feature/risk-and-history`
**Objetivo:** consolidar la lógica de riesgo y almacenar pruebas localmente.

### 6.1 Lógica en Dart

* Crear enums y modelos en `fast/domain`:

  * `SpeechLevel`, `FaceLevel`, `ArmsResult`, `RiskLevel`, `DecisionResult`.
* Implementar función `combineFastResults()` conforme a los umbrales.
* Llamar esta función en `DecisionPage` con los resultados reales.

### 6.2 Historial

* Elegir `isar` o `sqflite`.
* Modelo de historial:

  * id
  * fechaHora
  * riskLevel
  * speechLevel
  * faceLevel
  * dropDetected
  * similarity (opcional)
  * asymmetry (opcional)
  * deltaY (opcional)
* Repositorio + controlador Riverpod.
* UI de History:

  * Lista de pruebas.
  * Botón “Borrar historial”.

**DoD Épica 6:**

* Cada vez que terminas una prueba FAST, se guarda en el historial.
* La pantalla de historial muestra los resultados.

---

## ÉPICA 7 – Contactos, ajustes y accesibilidad

**Rama:** `feature/contacts-and-settings`
**Objetivo:** features secundarios pero importantes.

### 7.1 Contactos de emergencia

* Modelo:

  * nombre
  * teléfono
  * smsEnabled
  * locationEnabled
* CRUD local (sin SMS real todavía, si quieres dejarlo stub).

### 7.2 Ajustes

* Toggle:

  * modo alto contraste.
  * envío autom. de SMS (aunque backend SMS se implemente después o se quede en stub).
* Persistir en storage (shared prefs / isar).

### 7.3 Ayuda / Onboarding

* Explicar:

  * Qué es FAST.
  * Que la app NO diagnostica.
  * Que ante dudas, siempre llamar al 911.

**DoD Épica 7:**

* Contactos CRUD funciona.
* Modo alto contraste se aplica en toda la app.
* Onboarding accesible desde Home/Ajustes.

---

## ÉPICA 8 – Performance, UX y QA

**Rama:** `feature/performance-and-qa`
**Objetivo:** que el MVP sea usable en gama media/baja.

Tareas:

* Reducir resolución de cámara y/o procesar 1 de cada N frames.
* Verificar que el flujo completo FAST puede correrse en ~1 minuto sin trabes.
* Probar en mínimo:

  * 1 Android gama baja,
  * 1 Android gama media.
* Ajustar textos y mensajes de error:

  * baja luz,
  * sin rostro,
  * ruido alto,
  * fallos de modelo.

**DoD Épica 8:**

* App no se cuelga ni se sobrecalienta en pruebas razonables.
* UI responde bien.
* Mensajes claros y conservadores.

---

## ÉPICA 9 – iOS (futuro / opcional en tu semestre)

**Rama:** `feature/ios-support`

Replicar Vosk + MediaPipe en iOS con AVFoundation y Pods.
Puede quedar documentado como “Fase para generaciones futuras”.
