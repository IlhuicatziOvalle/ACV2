# Alerta ACV

Aplicación móvil Flutter para ayudar a detectar posibles signos tempranos de Accidente Cerebrovascular (ACV) usando la prueba FAST (Face, Arms, Speech, Time) y facilitar la activación rápida del protocolo de emergencia (llamada 911 + SMS a contactos con ubicación).

> **Aviso importante:** Esta app **no es un dispositivo médico ni reemplaza un diagnóstico profesional**. Es una herramienta educativa y de apoyo. Ante cualquier sospecha de ACV, **llama inmediatamente al 911 o al número de emergencias local**.

---

## 🏛️ Créditos y colaboradores

Este proyecto es desarrollado por la **Universidad Autónoma de Baja California (UABC)** en colaboración con **Cruz Roja Mexicana Delegación Tijuana**.

### Equipo de Desarrollo
- **Jorge Alejandro Sandoval Romo** - jorge.sandoval.romo@uabc.edu.mx
- **Jesús Alonso Reyes Castro**
- **César Córdova Contreras**

---

## 🧭 Visión general

**Alerta ACV** guía a un tercero (familiar, testigo, cuidador) para realizar una prueba FAST estructurada:

- **F – Face (Cara):** Análisis de asimetría facial con cámara trasera.
- **A – Arms (Brazos):** Detección de caída de brazos con cámara trasera.
- **S – Speech (Habla):** Análisis de dificultad en el habla con reconocimiento de voz.
- **T – Time (Tiempo):** Recomendaciones de urgencia y acciones inmediatas.

Al final del flujo, la app:

- Calcula un **nivel de riesgo global** (Bajo / Medio / Alto) combinando los tres pasos.
- Permite **llamar al 911** (o número equivalente) desde varias pantallas.
- Puede preparar un **SMS a contactos de emergencia**, incluyendo **ubicación y hora**, para que el usuario lo envíe.

Funciona en **Android** y **iOS**, con lógica de heurísticas, historial y UI compartida en Flutter y componentes nativos para cámara, voz y llamadas/SMS.

---

## 🎯 Características principales

- ✅ **100% offline**: Funciona sin conexión a internet (voz con Vosk en Android, Speech.framework en iOS).
- ✅ **Android e iOS**: Soporte completo en ambas plataformas.
- ✅ **Cámara trasera**: Usa la cámara trasera para análisis de cara y brazos.
- ✅ **Botón 911 permanente**: Acceso rápido a emergencias desde cualquier pantalla.
- ✅ **SMS con ubicación**: Prepara mensajes a contactos de emergencia incluyendo coordenadas GPS.
- ✅ **Historial de pruebas**: Guarda cada evaluación FAST localmente.
- ✅ **Contactos de emergencia**: Gestiona contactos e importa desde la libreta del teléfono.
- ✅ **Modo alto contraste**: Accesibilidad mejorada.
- ✅ **Instrucciones habladas**: Guía por voz configurable.
- ✅ **Interfaz intuitiva**: Diseño claro y fácil de usar.

---

## 🔍 Qué hace cada paso FAST

### Cara (Face)

- Usa la **cámara trasera** y **MediaPipe Face Landmarker** (Android / iOS).
- **Lógica de detección**:
  - Analiza **Blendshapes** (coeficientes de activación muscular) para `mouthSmileLeft` y `mouthSmileRight`.
  - Aplica suavizado exponencial (EMA) para reducir ruido.
  - Utiliza una **ventana de votación** (Voting Window) para determinar si la asimetría es sostenida en el tiempo, evitando falsos positivos por movimientos rápidos.
- **Cálculo de asimetría**:
  - Se compara la activación de ambos lados de la sonrisa.
  - Si la diferencia (delta) supera un umbral (0.12) mientras hay sonrisa detectada, se considera asimétrico.
- **Clasificación**:
  - `FaceLevel.sin` → Simetría normal.
  - `FaceLevel.fuerte` → Asimetría detectada consistentemente.
  - (El nivel `leve` se reserva para casos intermedios o incertidumbre en la medición).

### Brazos (Arms)

- Usa la **cámara trasera** y **MediaPipe Pose Landmarker**.
- **Lógica de detección**:
  - Rastrea landmarks de hombros (11, 12) y muñecas (15, 16).
  - Calcula la posición vertical relativa (Y) de cada muñeca respecto a su hombro.
- **Criterios de caída**:
  - **Diferencia entre muñecas**: Si la diferencia vertical entre la muñeca izquierda y derecha supera el **15% de la altura del frame**.
  - **Caída absoluta**: Si una muñeca cae significativamente por debajo de la línea de los hombros mientras la otra se mantiene arriba.
- Devuelve `dropDetected` (sí/no).

### Habla (Speech)

- El usuario debe repetir la frase objetivo: **"Hoy es un buen día para ayudar."**
- **Tecnología**:
  - **Android**: **Vosk** (reconocimiento de voz offline con modelo ligero).
  - **iOS**: **Speech Framework** (`SFSpeechRecognizer` + `AVAudioEngine`) en modo on-device.
- **Cálculo de similitud**:
  - Se transcribe el audio a texto.
  - Se normaliza el texto (minúsculas, sin acentos, sin puntuación).
  - Se calcula la **Distancia de Levenshtein** entre la transcripción y la frase objetivo.
  - `Similitud = 1 - (Distancia / Longitud máxima)`.
- **Umbrales**:
  - `>= 0.80` → `SpeechLevel.sin` (Habla clara).
  - `0.60 – 0.79` → `SpeechLevel.leve` (Dificultad moderada).
  - `< 0.60` → `SpeechLevel.fuerte` (Dificultad severa o ininteligible).

### Heurística FAST global

Definida en `lib/core/constants/risk_levels.dart`:

- **Riesgo Alto** si:
  - Habla fuerte, **o**
  - Cara fuerte, **o**
  - Hay caída de brazos, **o**
  - Hay **2 o más** componentes en nivel leve.
- **Riesgo Medio** si hay exactamente **1 componente leve** y ninguno fuerte.
- **Riesgo Bajo** en cualquier otro escenario.

---

## 📊 Historial y datos persistidos

- Cada ejecución de FAST se persiste como `TestResult` en SQLite mediante `DatabaseService`.
- Campos guardados: fecha/hora, nivel de habla, nivel de cara, resultado de brazos, riesgo global.
- `HistoryPage` permite ver, consultar y eliminar registros.

---

## 🆘 Protocolo de emergencia

### Llamada al 911

- El botón flotante `Floating911Button` está disponible en pantallas clave.
- También se puede llamar desde `DecisionPage` cuando el riesgo es Alto.
- Usa integración nativa (`FastService.placeCall911()`) con fallback a dialer.

### SMS a contactos de emergencia

- Los contactos se gestionan en `ContactsPage` y se almacenan localmente.
- **Ubicación**:
  - Usa el paquete `geolocator` para obtener coordenadas GPS precisas.
  - En iOS, requiere permiso `NSLocationWhenInUseUsageDescription`.
  - Si no hay señal GPS, intenta obtener la última ubicación conocida o envía el mensaje sin ubicación indicando el error.
- **Generación del mensaje**:
  - `SmsService` crea un texto con: Alerta, Enlace a Google Maps y Hora.
  - En Android/iOS se abre la app de mensajes nativa pre-llenada para que el usuario confirme el envío.

---

## ⚙️ Arquitectura y tecnologías

| Componente | Tecnología |
|------------|------------|
| **UI compartida** | Flutter (Dart) |
| **Estado global** | Riverpod |
| **Navegación** | Go Router |
| **Flutter ↔ Nativo** | Pigeon |
| **Base de datos** | SQLite (sqflite) |
| **Voz (Android)** | Vosk |
| **Voz (iOS)** | Speech.framework |
| **Análisis facial** | MediaPipe Face Landmarker |
| **Análisis de pose** | MediaPipe Pose Landmarker |
| **Permisos** | permission_handler |
| **Ubicación** | geolocator |
| **Llamadas/SMS** | url_launcher, canales nativos |
| **TTS** | flutter_tts |

La [documentación técnica](docs/README.md) ofrece rutas separadas para consultar
versiones, preparar el entorno, entender las herramientas o revisar el historial
de configuración.

### Estructura del proyecto

```text
lib/
├── main.dart                 # Punto de entrada, permisos y pre-inicialización
├── app.dart                  # MaterialApp y temas
├── core/
│   ├── constants/            # FAST y risk_levels
│   ├── routing/              # GoRouter
│   ├── theme/                # Temas y estilos (incl. RiskStyles)
│   └── di/                   # Proveedores globales (Riverpod)
├── features/
│   ├── fast/                 # Flujo FAST (Home, Face, Arms, Speech, Decision)
│   ├── history/              # Historial de pruebas
│   ├── contacts/             # Contactos de emergencia
│   ├── settings/             # Ajustes y accesibilidad
│   └── help/                 # Ayuda y explicación del flujo
├── services/
│   ├── fast/                 # FastService (Pigeon wrapper)
│   ├── device/               # Botón 911 y utilitarios
│   ├── sms_service.dart      # Mensajes de emergencia con ubicación
│   └── phone_utils.dart      # Llamadas telefónicas
└── pigeons/                  # Código generado por Pigeon
```

---

## 📦 Requisitos y setup del entorno

### Requisitos generales

- Flutter SDK **3.47.5** con Dart **3.13.4**
- JDK **17**
- Android SDK 36, Build Tools 36.0.0 y NDK 28.2.13676358
- Xcode 26.x, iOS SDK 26+ y CocoaPods 1.17.0 para iOS

Consulta la [preparación del entorno](docs/preparacion_del_entorno.md) antes de
instalar o actualizar herramientas.

### Clonar y preparar el proyecto

```bash
git clone https://github.com/AlertaACV/alerta_acv.git
cd alerta_acv
fvm install       # Si utilizas FVM
flutter pub get   # O: fvm flutter pub get
```

### Modelos necesarios (Android)

#### Modelo Vosk (voz offline)

1. Descarga `vosk-model-small-es-0.42.zip` desde:
   - https://alphacephei.com/vosk/models
2. Extrae el contenido y coloca la carpeta `vosk-model-small-es-0.42` en:
   ```text
   android/app/src/main/assets/vosk-model-small-es-0.42/
   ```

#### Modelos MediaPipe (cara y brazos)

Ubicados en `android/app/src/main/assets/models/`:

- `face_landmarker.task`
- `pose_landmarker_lite.task`

Si no están presentes, descárgalos desde la documentación oficial de MediaPipe.

### Permisos en Android

En `android/app/src/main/AndroidManifest.xml`:

- `RECORD_AUDIO`
- `CAMERA`
- `CALL_PHONE`
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`
- `READ_CONTACTS`
- `SEND_SMS`

### Permisos en iOS

En `ios/Runner/Info.plist`:

- `NSCameraUsageDescription`: Para análisis de video en tiempo real (Cara/Brazos).
- `NSMicrophoneUsageDescription`: Para capturar audio en la prueba de habla.
- `NSSpeechRecognitionUsageDescription`: Para procesar el audio y convertirlo a texto.
- `NSLocationWhenInUseUsageDescription`: Para adjuntar la ubicación GPS en el SMS de emergencia.
- `NSContactsUsageDescription`: Para importar contactos de emergencia desde la agenda.

Los textos deben explicar en español para qué se usa cada permiso, ya que son visibles para el usuario final.

---

## ▶️ Cómo ejecutar la app

### Android

```bash
flutter run -d android
```

- **Nota**: La primera vez, Android pedirá permisos de micrófono, cámara, llamadas, contactos, SMS y ubicación.
- **Debugging**: Usa Logcat en Android Studio filtrando por `FaceActivity`, `ArmsActivity` o `flutter` para ver logs nativos.

### iOS

```bash
# Abrir workspace en Xcode para firma y configuración
open ios/Runner.xcworkspace

# Ejecutar desde terminal
flutter run -d ios
```

- **Requisito**: Se necesita un **dispositivo físico** (iPhone/iPad) ya que la cámara y el micrófono no funcionan correctamente en el simulador para estas pruebas.
- **Debugging**: Los logs nativos (Swift) aparecen en la consola de Xcode o en la terminal de Flutter. Busca `FaceViewController` o `SpeechEngine`.

---

## 🧩 Ajustes disponibles

- **Modo alto contraste:** Toggle en `SettingsPage`, afecta tema global.
- **Envío automático de SMS:** Si está activo, el flujo de emergencia prepara SMS a todos los contactos.
- **Instrucciones habladas:** Controla si se usa TTS para leer instrucciones en las pantallas FAST.

---

## 🏗️ Estado del proyecto

### ✅ Completado

- **Arquitectura base y UI FAST** – Estructura completa, routing, temas.
- **Comunicación Flutter ↔ Nativo** – Pigeon implementado para Android e iOS.
- **Voz offline** – Vosk (Android), Speech.framework (iOS).
- **Análisis de cara** – MediaPipe Face Landmarker.
- **Análisis de brazos** – MediaPipe Pose Landmarker.
- **Heurística FAST y historial** – Combinación de resultados, persistencia SQLite.
- **Contactos y ajustes** – CRUD de contactos, importación, modo alto contraste, SMS automático.
- **Soporte iOS** – Paridad total con Android.

### 🚧 En curso

- **Performance, UX y QA** – Optimizaciones, pruebas de campo, pulido de interfaz.

---

## 📚 Documentación adicional

- `development_execution.md`: Log detallado de implementación por épicas.
- `docs/`: Guías específicas de modelos, MediaPipe, etc.

---

## 🌿 Flujo de ramas

- `main`: Rama estable.
- `feature/*`: Ramas por épica o feature.

---

## 📝 Licencia

Por definir. Hasta entonces, el código se considera de uso restringido al equipo del proyecto UABC–Cruz Roja Tijuana.

---

## 👥 Contribuciones

Este proyecto es parte de una colaboración académica. Contribuciones externas se pueden discutir vía issues o PRs una vez abierta la colaboración pública.
