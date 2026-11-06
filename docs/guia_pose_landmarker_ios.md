# Guía completa: Pose Landmarker para iOS

Referencia integral para el ejemplo `PoseLandmarker` en `examples/pose_landmarker/ios`. Incluye dependencias, servicios, controladores, vistas, scripts auxiliares y pruebas con fragmentos reales del código para comprender y extender la app.

## 1. Requisitos previos
- **Xcode 15+** apuntando a iOS 15 o superior.
- **CocoaPods** (`sudo gem install cocoapods`).
- **Dispositivo iOS físico** recomendado (el modo cámara se omite en simulador via `#if !targetEnvironment(simulator)`).
- **Acceso a internet** para descargar los modelos `.task` la primera vez.

## 2. Estructura relevante
| Ruta | Descripción |
| --- | --- |
| `PoseLandmarker/AppDelegate.swift`, `SceneDelegate.swift`, `Info.plist` | Ciclo de vida base y storyboard principal. |
| `PoseLandmarker/Base.lproj/Main.storyboard` | Contiene `RootViewController`, pestañas (Cámara/Galería) y el bottom sheet incrustado. |
| `PoseLandmarker/Configurations/` | `DefaultConstants.swift` + `InferenceConfigurationManager.swift` definen y propagan parámetros de inferencia/modelo. |
| `PoseLandmarker/Services/` | `CameraFeedService.swift` (AVCaptureSession) y `PoseLandmarkerService.swift` (MediaPipeTasksVision). |
| `PoseLandmarker/ViewContoller/` | `Root`, `Camera`, `MediaLibrary`, `BottomSheet` coordinan la UI. |
| `PoseLandmarker/Views/PoseOverlay.swift` | Renderiza puntos y esqueletos. |
| `PoseLandmarker/*.task` | Modelos lite/full/heavy descargados por `RunScripts/download_models.sh`. |
| `Podfile` | Declara la dependencia `MediaPipeTasksVision` `0.10.14`. |
| `PoseLandmarkerTests/` | Tests con `XCTest` y `test_image.jpg`. |

## 3. Descarga de modelos
Ejecuta una sola vez desde `examples/pose_landmarker/ios/`:

```bash
sh RunScripts/download_models.sh
```

El script verifica y descarga las variantes `pose_landmarker_lite/full/heavy` en `PoseLandmarker/`.

## 4. Dependencias e instalación
1. Instala pods:
   ```bash
   cd examples/pose_landmarker/ios
   pod install
   ```
2. Abre `PoseLandmarker.xcworkspace` en Xcode.
3. Selecciona el esquema `PoseLandmarker` y un dispositivo.
4. Otorga permisos de cámara (de lo contrario `CameraViewController` mostrará una alerta desde `presentCameraPermissionsDeniedAlert()`).

## 5. Configuración de inferencia
### 5.1 Valores por defecto y selección de modelo (`Configurations/DefaultConstants.swift`)
Se exponen parámetros iniciales y la enumeración `Model` que enlaza los `.task` incluidos:
```swift
static var numPoses: Int = 1
static var minPoseDetectionConfidence: Float = 0.5
static var minPosePresenceConfidence: Float = 0.5
static var minTrackingConfidence: Float = 0.5
static let model: Model = .pose_landmarker_lite

enum Model: Int, CaseIterable {
  case pose_landmarker_lite
  case pose_landmarker_full
  case pose_landmarker_heavy

  var modelPath: String? {
    switch self {
    case .pose_landmarker_lite:
      return Bundle.main.path(forResource: "pose_landmarker_lite", ofType: "task")
    case .pose_landmarker_full:
      return Bundle.main.path(forResource: "pose_landmarker_full", ofType: "task")
    case .pose_landmarker_heavy:
      return Bundle.main.path(forResource: "pose_landmarker_heavy", ofType: "task")
    }
  }
}
```

### 5.2 Singleton compartido (`Configurations/InferenceConfigurationManager.swift`)
- Mantiene `model`, `delegate (CPU/GPU)`, `numPoses` y los umbrales de confianza.
- Cada setter publica la notificación `com.google.mediapipe.inferenceConfigChanged` para que los controladores reconstruyan los servicios con la configuración actual.

## 6. Servicios clave
### 6.1 Cámara (`Services/CameraFeedService.swift`)
- Inicializa `AVCaptureSession` (frontal, `AVLayerVideoGravity.resizeAspectFill`).
- Exposición vía `CameraFeedServiceDelegate.didOutput(sampleBuffer:orientation:)`.
- Maneja permisos, interrupciones del sistema y errores (`sessionWasInterrupted`, `didEncounterSessionRuntimeError`).
- Usa una cola dedicada `sessionQueue` y ajusta la vista preliminar en `updateVideoPreviewLayer(toFrame:)`.

### 6.2 MediaPipe Pose (`Services/PoseLandmarkerService.swift`)
- Contiene constructores estáticos para modos `.image`, `.video`, `.liveStream`.
- Configura `PoseLandmarkerOptions` con los valores del singleton y delega callbacks a `PoseLandmarkerServiceLiveStreamDelegate` o `PoseLandmarkerServiceVideoDelegate`.
- Métodos públicos:
  - `detect(image:)` → procesamiento síncrono de fotos.
  - `detect(videoAsset:durationInMilliseconds:inferenceIntervalInMilliseconds:)` → genera frames con `AVAssetImageGenerator` y notifica progreso.
  - `detectAsync(sampleBuffer:orientation:timeStamps:)` → alimenta el modo streaming.
- Agrupa resultados en `ResultBundle` (tiempo promedio + `PoseLandmarkerResult` + tamaño del frame).

## 7. Controladores y flujo de UI
### 7.1 `RootViewController`
- Escena inicial del storyboard, contiene `UITabBar` para alternar entre cámara y galería.
- Inserta `BottomSheetViewController` mediante el segue `EMBED` y ajusta su altura (`Constants.inferenceBottomHeight = 356`).
- Implementa `InferenceResultDeliveryDelegate` para actualizar el tiempo de inferencia en el panel inferior.

### 7.2 Panel inferior (`ViewContoller/BottomSheetViewController.swift`)
- Expone steppers para `numPoses` y umbrales, más dos `UIButton` con `UIMenu` para elegir modelo y delegado (CPU/GPU).
- Cada cambio actualiza `InferenceConfigurationManager`:
```swift
let actions: [UIAction] = Model.allCases.compactMap { model in
  UIAction(title: model.name,
           state: (InferenceConfigurationManager.sharedInstance.model == model) ? .on : .off) { action in
    self.updateModel(modelTitle: action.title)
  }
}
```
- Controla la expansión del bottom sheet notificando a `BottomSheetViewControllerDelegate`.

### 7.3 Cámara en vivo (`ViewContoller/CameraViewController.swift`)
- Inicializa `CameraFeedService` y, en `didOutput`, envía frames a `PoseLandmarkerService.detectAsync` en `backgroundQueue`.
- Cuando llegan resultados, crea `poseOverlays` con `OverlayView.poseOverlays(...)` y los dibuja en `overlayView`.
- Reacciona a cambios en la configuración observando la notificación del singleton y reconstruyendo el servicio con:
```swift
poseLandmarkerService = PoseLandmarkerService.liveStreamPoseLandmarkerService(
  modelPath: InferenceConfigurationManager.sharedInstance.model.modelPath,
  numPoses: InferenceConfigurationManager.sharedInstance.numPoses,
  ...)
```

### 7.4 Biblioteca multimedia (`ViewContoller/MediaLibraryViewController.swift`)
- Usa `UIImagePickerController` para fotos o videos.
- Imágenes → ejecuta `PoseLandmarkerService.stillImageLandmarkerService`, muestra progreso y dibuja resultados estáticos.
- Videos → crea un servicio `.video`, ejecuta `detect(...)` cada 300 ms y sincroniza `OverlayView` con un `AVPlayer` mediante `addPeriodicTimeObserver`.
- Ajusta el botón “+” según la altura del bottom sheet (`layoutUIElements(withInferenceViewHeight:)`).

### 7.5 Sobreposición (`Views/PoseOverlay.swift`)
- Convierte landmarks normalizados a coordenadas de la vista considerando la orientación (`.left/.right/.up`).
- `PoseLandmarker.poseLandmarks` define las conexiones (esqueleto) que se dibujan con el color configurado.

### 7.6 Storyboards y assets
- `Main.storyboard` define las escenas mencionadas y los outlets (preview, overlay, botones, labels, steppers, etc.).
- `Assets.xcassets` agrupa íconos, colores y `LaunchScreen.storyboard` proporciona la pantalla inicial.

## 8. Flujo resumido
1. `AppDelegate/SceneDelegate` cargan `Main.storyboard`.
2. `RootViewController` presenta la pestaña de cámara por defecto e incrusta el bottom sheet.
3. `CameraViewController` arranca `CameraFeedService`; cada frame llega a `PoseLandmarkerService` en modo live stream.
4. `InferenceResultDeliveryDelegate` recibe `ResultBundle` y actualiza la UI inferior; el usuario puede moverse a “Gallery” para trabajar con medios locales reutilizando la misma configuración.

## 9. Pruebas automatizadas (`PoseLandmarkerTests/PoseLandmarkerTests.swift`)
- Ejecuta inferencia determinista sobre `test_image.jpg` para las tres variantes del modelo (`lite`, `full`, `heavy`).
- Verifica que cada resultado tenga un solo esqueleto (`assertPoseLandmarkResultHasOneHead`) y compara todos los `NormalizedLandmark` contra valores esperados (listas incluidas en el archivo).
- Corre desde Xcode con el esquema de tests o vía CLI:
  ```bash
  xcodebuild test -scheme PoseLandmarker -destination 'platform=iOS Simulator,name=iPhone 15'
  ```
  (Las pruebas usan imágenes estáticas, por lo que no requieren cámara física.)

## 10. Personalización y consejos
- **Selector de modelo**: puedes ampliar `Model` con rutas personalizadas o actualizar `RunScripts/download_models.sh` para descargar versiones propias.
- **Rendimiento/precisión**: combina `Model` (lite → heavy) con el delegado (CPU/GPU) desde el bottom sheet para comparar latencia vs calidad.
- **Más poses simultáneas**: incrementa `DefaultConstants.numPoses` y ajusta los límites de `numPosesStepper` en el storyboard.
- **Visualización**: modifica `DefaultConstants.lineColor`, `pointColor`, etc. para adaptar el overlay a tu UI.
- **Integración continua**: ejecuta `pod repo update && pod install` en CI antes de `xcodebuild` para asegurar la dependencia `MediaPipeTasksVision`.

## 11. Checklist para ejecutar
1. `sh RunScripts/download_models.sh` (solo la primera vez).
2. `pod install`.
3. Abrir `PoseLandmarker.xcworkspace`.
4. Seleccionar dispositivo físico, compilar y ejecutar.
5. Permitir acceso a la cámara al primer arranque.
6. Ajustar modelo/umbrales desde el bottom sheet según tus necesidades.

Con esta guía puedes navegar todos los archivos involucrados, entender cómo se conectan los servicios de MediaPipe con la UI nativa de iOS y extender el ejemplo de pose landmarking conforme a tus requisitos.
