# 📖 Guía Completa: MediaPipe Face Landmarker en Android

## Tabla de Contenidos
1. [Introducción](#introducción)
2. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
3. [Dependencias y Configuración](#dependencias-y-configuración)
4. [Archivos Principales](#archivos-principales)
5. [Flujo de Datos](#flujo-de-datos)
6. [Código Fuente Completo](#código-fuente-completo)
7. [Cómo Funciona la Detección](#cómo-funciona-la-detección)
8. [Personalización](#personalización)

---

## Introducción

**Face Landmarker** es una solución de MediaPipe que detecta **478 puntos faciales (landmarks)** en tiempo real. Estos puntos permiten:

- 🎭 Detectar expresiones faciales (blendshapes)
- 👁️ Rastrear ojos, cejas, nariz, labios
- 📐 Estimar la pose de la cabeza
- 🎨 Aplicar filtros AR (como los de Instagram/Snapchat)

### ¿Qué son los Face Landmarks?

Son coordenadas 3D normalizadas (x, y, z) que representan puntos específicos del rostro:

```
Puntos 0-16:    Contorno de la cara (jawline)
Puntos 17-21:   Ceja izquierda
Puntos 22-26:   Ceja derecha
Puntos 27-35:   Nariz
Puntos 36-41:   Ojo izquierdo
Puntos 42-47:   Ojo derecho
Puntos 48-67:   Labios
...y muchos más hasta 478 puntos
```

---

## Arquitectura del Proyecto

```
app/src/main/java/com/google/mediapipe/examples/facelandmarker/
├── FaceLandmarkerHelper.kt   ← 🧠 Motor de detección (MediaPipe)
├── MainActivity.kt           ← 🚀 Punto de entrada
├── MainViewModel.kt          ← 💾 Estado/configuración
├── OverlayView.kt            ← 🎨 Dibuja landmarks en pantalla
└── fragment/
    ├── CameraFragment.kt     ← 📷 Detección en tiempo real
    ├── GalleryFragment.kt    ← 🖼️ Detección en imágenes/videos
    ├── PermissionsFragment.kt← 🔐 Manejo de permisos
    └── FaceBlendshapesResultAdapter.kt ← 📊 UI de blendshapes
```

### Diagrama de Flujo

```
┌──────────────┐     ┌─────────────────────┐     ┌──────────────┐
│   CameraX    │────▶│ FaceLandmarkerHelper │────▶│  OverlayView │
│   (frames)   │     │   (MediaPipe API)    │     │   (Canvas)   │
└──────────────┘     └─────────────────────┘     └──────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │ FaceLandmarkerResult │
                     │ • 478 landmarks     │
                     │ • 52 blendshapes    │
                     │ • Face matrices     │
                     └─────────────────┘
```

---

## Dependencias y Configuración

### build.gradle (app)

```gradle
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
    id 'de.undercouch.download'  // Para descargar el modelo
}

android {
    namespace 'com.google.mediapipe.examples.facelandmarker'
    compileSdk 34

    defaultConfig {
        applicationId "com.google.mediapipe.examples.facelandmarker"
        minSdk 24        // Android 7.0+
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildFeatures {
        viewBinding true  // Para acceso seguro a views
    }
}

dependencies {
    // CameraX - Para captura de cámara
    def camerax_version = '1.4.2'
    implementation "androidx.camera:camera-core:$camerax_version"
    implementation "androidx.camera:camera-camera2:$camerax_version"
    implementation "androidx.camera:camera-lifecycle:$camerax_version"
    implementation "androidx.camera:camera-view:$camerax_version"

    // Navigation - Para navegación entre fragments
    def nav_version = "2.5.3"
    implementation "androidx.navigation:navigation-fragment-ktx:$nav_version"
    implementation "androidx.navigation:navigation-ui-ktx:$nav_version"

    // ⭐ MediaPipe - La librería principal de detección
    implementation 'com.google.mediapipe:tasks-vision:0.10.29'
}
```

### AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Requiere cámara -->
    <uses-feature android:name="android.hardware.camera" />
    
    <!-- Permiso de cámara -->
    <uses-permission android:name="android.permission.CAMERA" />

    <application
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/AppTheme">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

---

## Archivos Principales

### 1. FaceLandmarkerHelper.kt - El Corazón de la Detección

Este archivo encapsula toda la lógica de MediaPipe. Es el más importante.

**¿Por qué existe?**
- Separa la lógica de ML de la UI
- Permite cambiar configuración sin tocar fragments
- Maneja los 3 modos: imagen, video y livestream

**Funciones clave:**

| Función | Propósito |
|---------|-----------|
| `setupFaceLandmarker()` | Inicializa el modelo con opciones |
| `detectLiveStream()` | Procesa frames de cámara |
| `detectImage()` | Procesa una imagen estática |
| `detectVideoFile()` | Procesa frames de video |
| `returnLivestreamResult()` | Callback con resultados |

---

### 2. OverlayView.kt - Visualización

**¿Por qué existe?**
- Es una View personalizada que se superpone a la cámara
- Convierte coordenadas normalizadas (0-1) a píxeles
- Dibuja puntos y líneas de conexión

**Funciones clave:**

| Función | Propósito |
|---------|-----------|
| `drawFaceLandmarks()` | Dibuja los 478 puntos |
| `drawFaceConnectors()` | Dibuja líneas entre puntos relacionados |
| `setResults()` | Recibe resultados y calcula escala |

---

### 3. CameraFragment.kt - Captura en Tiempo Real

**¿Por qué existe?**
- Configura CameraX para capturar frames
- Envía cada frame al FaceLandmarkerHelper
- Actualiza la UI con resultados
- Maneja controles de configuración (sliders)

---

### 4. MainViewModel.kt - Estado de la App

**¿Por qué existe?**
- Persiste configuración entre cambios de fragment
- Sobrevive rotaciones de pantalla
- Patrón MVVM de Android

---

## Flujo de Datos

### Paso 1: Captura de Frame (CameraFragment)
```kotlin
// CameraX captura un frame
imageAnalyzer = ImageAnalysis.Builder()
    .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
    .build()
    .also {
        it.setAnalyzer(backgroundExecutor) { image ->
            detectFace(image)  // Envía al helper
        }
    }
```

### Paso 2: Procesamiento (FaceLandmarkerHelper)
```kotlin
fun detectLiveStream(imageProxy: ImageProxy, isFrontCamera: Boolean) {
    // 1. Convierte ImageProxy a Bitmap
    val bitmapBuffer = Bitmap.createBitmap(...)
    
    // 2. Rota/voltea si es cámara frontal
    val matrix = Matrix().apply {
        postRotate(rotationDegrees)
        if (isFrontCamera) postScale(-1f, 1f, ...)
    }
    
    // 3. Convierte a MPImage (formato MediaPipe)
    val mpImage = BitmapImageBuilder(rotatedBitmap).build()
    
    // 4. Ejecuta detección asíncrona
    faceLandmarker?.detectAsync(mpImage, frameTime)
}
```

### Paso 3: Recepción de Resultados
```kotlin
private fun returnLivestreamResult(result: FaceLandmarkerResult, input: MPImage) {
    if (result.faceLandmarks().size > 0) {
        faceLandmarkerHelperListener?.onResults(
            ResultBundle(result, inferenceTime, input.height, input.width)
        )
    }
}
```

### Paso 4: Visualización (OverlayView)
```kotlin
override fun draw(canvas: Canvas) {
    results?.faceLandmarks()?.forEach { faceLandmarks ->
        // Dibuja cada punto
        faceLandmarks.forEach { landmark ->
            val x = landmark.x() * imageWidth * scaleFactor + offsetX
            val y = landmark.y() * imageHeight * scaleFactor + offsetY
            canvas.drawPoint(x, y, pointPaint)
        }
        
        // Dibuja conexiones
        FaceLandmarker.FACE_LANDMARKS_CONNECTORS.forEach { connector ->
            canvas.drawLine(startX, startY, endX, endY, linePaint)
        }
    }
}
```

---

## Código Fuente Completo

### FaceLandmarkerHelper.kt

```kotlin
package com.google.mediapipe.examples.facelandmarker

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.SystemClock
import android.util.Log
import androidx.annotation.VisibleForTesting
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult

class FaceLandmarkerHelper(
    var minFaceDetectionConfidence: Float = DEFAULT_FACE_DETECTION_CONFIDENCE,
    var minFaceTrackingConfidence: Float = DEFAULT_FACE_TRACKING_CONFIDENCE,
    var minFacePresenceConfidence: Float = DEFAULT_FACE_PRESENCE_CONFIDENCE,
    var maxNumFaces: Int = DEFAULT_NUM_FACES,
    var currentDelegate: Int = DELEGATE_CPU,
    var runningMode: RunningMode = RunningMode.IMAGE,
    val context: Context,
    val faceLandmarkerHelperListener: LandmarkerListener? = null
) {

    private var faceLandmarker: FaceLandmarker? = null

    init {
        setupFaceLandmarker()
    }

    fun clearFaceLandmarker() {
        faceLandmarker?.close()
        faceLandmarker = null
    }

    fun isClose(): Boolean {
        return faceLandmarker == null
    }

    // Inicializa el Face Landmarker con las opciones configuradas
    fun setupFaceLandmarker() {
        val baseOptionBuilder = BaseOptions.builder()

        // Selecciona CPU o GPU para inferencia
        when (currentDelegate) {
            DELEGATE_CPU -> baseOptionBuilder.setDelegate(Delegate.CPU)
            DELEGATE_GPU -> baseOptionBuilder.setDelegate(Delegate.GPU)
        }

        // Carga el modelo .task desde assets
        baseOptionBuilder.setModelAssetPath(MP_FACE_LANDMARKER_TASK)

        // Valida que LIVE_STREAM tenga listener
        when (runningMode) {
            RunningMode.LIVE_STREAM -> {
                if (faceLandmarkerHelperListener == null) {
                    throw IllegalStateException(
                        "faceLandmarkerHelperListener must be set when runningMode is LIVE_STREAM."
                    )
                }
            }
            else -> { /* no-op */ }
        }

        try {
            val baseOptions = baseOptionBuilder.build()
            
            val optionsBuilder = FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setMinFaceDetectionConfidence(minFaceDetectionConfidence)
                .setMinTrackingConfidence(minFaceTrackingConfidence)
                .setMinFacePresenceConfidence(minFacePresenceConfidence)
                .setNumFaces(maxNumFaces)
                .setOutputFaceBlendshapes(true)  // Habilita blendshapes
                .setRunningMode(runningMode)

            // Solo para LIVE_STREAM: callbacks asíncronos
            if (runningMode == RunningMode.LIVE_STREAM) {
                optionsBuilder
                    .setResultListener(this::returnLivestreamResult)
                    .setErrorListener(this::returnLivestreamError)
            }

            val options = optionsBuilder.build()
            faceLandmarker = FaceLandmarker.createFromOptions(context, options)
            
        } catch (e: IllegalStateException) {
            faceLandmarkerHelperListener?.onError(
                "Face Landmarker failed to initialize. See error logs for details"
            )
            Log.e(TAG, "MediaPipe failed to load the task with error: " + e.message)
        } catch (e: RuntimeException) {
            faceLandmarkerHelperListener?.onError(
                "Face Landmarker failed to initialize. See error logs for details",
                GPU_ERROR
            )
            Log.e(TAG, "Face Landmarker failed to load model with error: " + e.message)
        }
    }

    // Detecta landmarks en frames de cámara en tiempo real
    fun detectLiveStream(imageProxy: ImageProxy, isFrontCamera: Boolean) {
        if (runningMode != RunningMode.LIVE_STREAM) {
            throw IllegalArgumentException(
                "Attempting to call detectLiveStream while not using RunningMode.LIVE_STREAM"
            )
        }
        val frameTime = SystemClock.uptimeMillis()

        // Copia los bits RGB del frame a un bitmap
        val bitmapBuffer = Bitmap.createBitmap(
            imageProxy.width,
            imageProxy.height,
            Bitmap.Config.ARGB_8888
        )
        imageProxy.use { bitmapBuffer.copyPixelsFromBuffer(imageProxy.planes[0].buffer) }
        imageProxy.close()

        val matrix = Matrix().apply {
            // Rota el frame según la orientación
            postRotate(imageProxy.imageInfo.rotationDegrees.toFloat())
            
            // Voltea horizontalmente si es cámara frontal
            if (isFrontCamera) {
                postScale(-1f, 1f, imageProxy.width.toFloat(), imageProxy.height.toFloat())
            }
        }
        
        val rotatedBitmap = Bitmap.createBitmap(
            bitmapBuffer, 0, 0, bitmapBuffer.width, bitmapBuffer.height,
            matrix, true
        )

        // Convierte a MPImage para MediaPipe
        val mpImage = BitmapImageBuilder(rotatedBitmap).build()
        detectAsync(mpImage, frameTime)
    }

    @VisibleForTesting
    fun detectAsync(mpImage: MPImage, frameTime: Long) {
        faceLandmarker?.detectAsync(mpImage, frameTime)
    }

    // Detecta landmarks en un video
    fun detectVideoFile(videoUri: Uri, inferenceIntervalMs: Long): VideoResultBundle? {
        if (runningMode != RunningMode.VIDEO) {
            throw IllegalArgumentException(
                "Attempting to call detectVideoFile while not using RunningMode.VIDEO"
            )
        }

        val startTime = SystemClock.uptimeMillis()
        var didErrorOccurred = false

        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(context, videoUri)
        
        val videoLengthMs = retriever.extractMetadata(
            MediaMetadataRetriever.METADATA_KEY_DURATION
        )?.toLong()

        val firstFrame = retriever.getFrameAtTime(0)
        val width = firstFrame?.width
        val height = firstFrame?.height

        if ((videoLengthMs == null) || (width == null) || (height == null)) return null

        val resultList = mutableListOf<FaceLandmarkerResult>()
        val numberOfFrameToRead = videoLengthMs.div(inferenceIntervalMs)

        for (i in 0..numberOfFrameToRead) {
            val timestampMs = i * inferenceIntervalMs

            retriever.getFrameAtTime(
                timestampMs * 1000,
                MediaMetadataRetriever.OPTION_CLOSEST
            )?.let { frame ->
                val argb8888Frame = if (frame.config == Bitmap.Config.ARGB_8888) frame
                    else frame.copy(Bitmap.Config.ARGB_8888, false)

                val mpImage = BitmapImageBuilder(argb8888Frame).build()

                faceLandmarker?.detectForVideo(mpImage, timestampMs)?.let { detectionResult ->
                    resultList.add(detectionResult)
                } ?: {
                    didErrorOccurred = true
                    faceLandmarkerHelperListener?.onError(
                        "ResultBundle could not be returned in detectVideoFile"
                    )
                }
            } ?: run {
                didErrorOccurred = true
                faceLandmarkerHelperListener?.onError(
                    "Frame at specified time could not be retrieved when detecting in video."
                )
            }
        }

        retriever.release()

        val inferenceTimePerFrameMs = (SystemClock.uptimeMillis() - startTime).div(numberOfFrameToRead)

        return if (didErrorOccurred) null 
        else VideoResultBundle(resultList, inferenceTimePerFrameMs, height, width)
    }

    // Detecta landmarks en una imagen estática
    fun detectImage(image: Bitmap): ResultBundle? {
        if (runningMode != RunningMode.IMAGE) {
            throw IllegalArgumentException(
                "Attempting to call detectImage while not using RunningMode.IMAGE"
            )
        }

        val startTime = SystemClock.uptimeMillis()
        val mpImage = BitmapImageBuilder(image).build()

        faceLandmarker?.detect(mpImage)?.also { landmarkResult ->
            val inferenceTimeMs = SystemClock.uptimeMillis() - startTime
            return ResultBundle(landmarkResult, inferenceTimeMs, image.height, image.width)
        }

        faceLandmarkerHelperListener?.onError("Face Landmarker failed to detect.")
        return null
    }

    // Callback para resultados de LIVE_STREAM
    private fun returnLivestreamResult(result: FaceLandmarkerResult, input: MPImage) {
        if (result.faceLandmarks().size > 0) {
            val finishTimeMs = SystemClock.uptimeMillis()
            val inferenceTime = finishTimeMs - result.timestampMs()

            faceLandmarkerHelperListener?.onResults(
                ResultBundle(result, inferenceTime, input.height, input.width)
            )
        } else {
            faceLandmarkerHelperListener?.onEmpty()
        }
    }

    private fun returnLivestreamError(error: RuntimeException) {
        faceLandmarkerHelperListener?.onError(
            error.message ?: "An unknown error has occurred"
        )
    }

    companion object {
        const val TAG = "FaceLandmarkerHelper"
        private const val MP_FACE_LANDMARKER_TASK = "face_landmarker.task"

        const val DELEGATE_CPU = 0
        const val DELEGATE_GPU = 1
        const val DEFAULT_FACE_DETECTION_CONFIDENCE = 0.5F
        const val DEFAULT_FACE_TRACKING_CONFIDENCE = 0.5F
        const val DEFAULT_FACE_PRESENCE_CONFIDENCE = 0.5F
        const val DEFAULT_NUM_FACES = 1
        const val OTHER_ERROR = 0
        const val GPU_ERROR = 1
    }

    // Contenedor de resultados para imagen/livestream
    data class ResultBundle(
        val result: FaceLandmarkerResult,
        val inferenceTime: Long,
        val inputImageHeight: Int,
        val inputImageWidth: Int,
    )

    // Contenedor de resultados para video
    data class VideoResultBundle(
        val results: List<FaceLandmarkerResult>,
        val inferenceTime: Long,
        val inputImageHeight: Int,
        val inputImageWidth: Int,
    )

    // Interface para comunicar resultados
    interface LandmarkerListener {
        fun onError(error: String, errorCode: Int = OTHER_ERROR)
        fun onResults(resultBundle: ResultBundle)
        fun onEmpty() {}
    }
}
```

---

### OverlayView.kt

```kotlin
package com.google.mediapipe.examples.facelandmarker

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.util.AttributeSet
import android.view.View
import androidx.core.content.ContextCompat
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import kotlin.math.max
import kotlin.math.min

class OverlayView(context: Context?, attrs: AttributeSet?) :
    View(context, attrs) {

    private var results: FaceLandmarkerResult? = null
    private var linePaint = Paint()
    private var pointPaint = Paint()

    private var scaleFactor: Float = 1f
    private var imageWidth: Int = 1
    private var imageHeight: Int = 1

    init {
        initPaints()
    }

    fun clear() {
        results = null
        linePaint.reset()
        pointPaint.reset()
        invalidate()
        initPaints()
    }

    private fun initPaints() {
        // Color de las líneas de conexión
        linePaint.color = ContextCompat.getColor(context!!, R.color.mp_color_primary)
        linePaint.strokeWidth = LANDMARK_STROKE_WIDTH
        linePaint.style = Paint.Style.STROKE

        // Color de los puntos (amarillo)
        pointPaint.color = Color.YELLOW
        pointPaint.strokeWidth = LANDMARK_STROKE_WIDTH
        pointPaint.style = Paint.Style.FILL
    }

    override fun draw(canvas: Canvas) {
        super.draw(canvas)

        // Si no hay landmarks, limpia
        if (results?.faceLandmarks().isNullOrEmpty()) {
            clear()
            return
        }

        results?.let { faceLandmarkerResult ->
            // Calcula dimensiones escaladas
            val scaledImageWidth = imageWidth * scaleFactor
            val scaledImageHeight = imageHeight * scaleFactor

            // Calcula offsets para centrar la imagen
            val offsetX = (width - scaledImageWidth) / 2f
            val offsetY = (height - scaledImageHeight) / 2f

            // Itera sobre cada cara detectada
            faceLandmarkerResult.faceLandmarks().forEach { faceLandmarks ->
                drawFaceLandmarks(canvas, faceLandmarks, offsetX, offsetY)
                drawFaceConnectors(canvas, faceLandmarks, offsetX, offsetY)
            }
        }
    }

    // Dibuja los 478 puntos de la cara
    private fun drawFaceLandmarks(
        canvas: Canvas,
        faceLandmarks: List<NormalizedLandmark>,
        offsetX: Float,
        offsetY: Float
    ) {
        faceLandmarks.forEach { landmark ->
            // Convierte coordenadas normalizadas (0-1) a píxeles
            val x = landmark.x() * imageWidth * scaleFactor + offsetX
            val y = landmark.y() * imageHeight * scaleFactor + offsetY
            canvas.drawPoint(x, y, pointPaint)
        }
    }

    // Dibuja las líneas que conectan los puntos
    private fun drawFaceConnectors(
        canvas: Canvas,
        faceLandmarks: List<NormalizedLandmark>,
        offsetX: Float,
        offsetY: Float
    ) {
        // FACE_LANDMARKS_CONNECTORS es una lista de pares (start, end)
        FaceLandmarker.FACE_LANDMARKS_CONNECTORS.filterNotNull().forEach { connector ->
            val startLandmark = faceLandmarks.getOrNull(connector.start())
            val endLandmark = faceLandmarks.getOrNull(connector.end())

            if (startLandmark != null && endLandmark != null) {
                val startX = startLandmark.x() * imageWidth * scaleFactor + offsetX
                val startY = startLandmark.y() * imageHeight * scaleFactor + offsetY
                val endX = endLandmark.x() * imageWidth * scaleFactor + offsetX
                val endY = endLandmark.y() * imageHeight * scaleFactor + offsetY

                canvas.drawLine(startX, startY, endX, endY, linePaint)
            }
        }
    }

    // Recibe resultados y calcula el factor de escala
    fun setResults(
        faceLandmarkerResults: FaceLandmarkerResult,
        imageHeight: Int,
        imageWidth: Int,
        runningMode: RunningMode = RunningMode.IMAGE
    ) {
        results = faceLandmarkerResults
        this.imageHeight = imageHeight
        this.imageWidth = imageWidth

        scaleFactor = when (runningMode) {
            RunningMode.IMAGE, RunningMode.VIDEO -> {
                // Escala para que la imagen quepa en la view
                min(width * 1f / imageWidth, height * 1f / imageHeight)
            }
            RunningMode.LIVE_STREAM -> {
                // PreviewView usa FILL_START, necesitamos escalar hacia arriba
                max(width * 1f / imageWidth, height * 1f / imageHeight)
            }
        }
        invalidate()  // Fuerza redibujado
    }

    companion object {
        private const val LANDMARK_STROKE_WIDTH = 8F
    }
}
```

---

### CameraFragment.kt

```kotlin
package com.google.mediapipe.examples.facelandmarker.fragment

import android.annotation.SuppressLint
import android.content.res.Configuration
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.Toast
import androidx.camera.core.Preview
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Camera
import androidx.camera.core.AspectRatio
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.navigation.Navigation
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.viewpager2.widget.ViewPager2.SCROLL_STATE_DRAGGING
import com.google.mediapipe.examples.facelandmarker.FaceLandmarkerHelper
import com.google.mediapipe.examples.facelandmarker.MainViewModel
import com.google.mediapipe.examples.facelandmarker.R
import com.google.mediapipe.examples.facelandmarker.databinding.FragmentCameraBinding
import com.google.mediapipe.tasks.vision.core.RunningMode
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class CameraFragment : Fragment(), FaceLandmarkerHelper.LandmarkerListener {

    companion object {
        private const val TAG = "Face Landmarker"
    }

    private var _fragmentCameraBinding: FragmentCameraBinding? = null
    private val fragmentCameraBinding get() = _fragmentCameraBinding!!

    private lateinit var faceLandmarkerHelper: FaceLandmarkerHelper
    private val viewModel: MainViewModel by activityViewModels()
    private val faceBlendshapesResultAdapter by lazy { FaceBlendshapesResultAdapter() }

    private var preview: Preview? = null
    private var imageAnalyzer: ImageAnalysis? = null
    private var camera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var cameraFacing = CameraSelector.LENS_FACING_FRONT  // Cámara frontal por defecto

    // Executor para operaciones de ML en background
    private lateinit var backgroundExecutor: ExecutorService

    override fun onResume() {
        super.onResume()
        // Verifica permisos
        if (!PermissionsFragment.hasPermissions(requireContext())) {
            Navigation.findNavController(requireActivity(), R.id.fragment_container)
                .navigate(R.id.action_camera_to_permissions)
        }

        // Reinicia el helper cuando vuelve al foreground
        backgroundExecutor.execute {
            if (faceLandmarkerHelper.isClose()) {
                faceLandmarkerHelper.setupFaceLandmarker()
            }
        }
    }

    override fun onPause() {
        super.onPause()
        if (this::faceLandmarkerHelper.isInitialized) {
            // Guarda configuración en ViewModel
            viewModel.setMaxFaces(faceLandmarkerHelper.maxNumFaces)
            viewModel.setMinFaceDetectionConfidence(faceLandmarkerHelper.minFaceDetectionConfidence)
            viewModel.setMinFaceTrackingConfidence(faceLandmarkerHelper.minFaceTrackingConfidence)
            viewModel.setMinFacePresenceConfidence(faceLandmarkerHelper.minFacePresenceConfidence)
            viewModel.setDelegate(faceLandmarkerHelper.currentDelegate)

            // Libera recursos
            backgroundExecutor.execute { faceLandmarkerHelper.clearFaceLandmarker() }
        }
    }

    override fun onDestroyView() {
        _fragmentCameraBinding = null
        super.onDestroyView()

        backgroundExecutor.shutdown()
        backgroundExecutor.awaitTermination(Long.MAX_VALUE, TimeUnit.NANOSECONDS)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _fragmentCameraBinding = FragmentCameraBinding.inflate(inflater, container, false)
        return fragmentCameraBinding.root
    }

    @SuppressLint("MissingPermission")
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Configura RecyclerView para blendshapes
        with(fragmentCameraBinding.recyclerviewResults) {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = faceBlendshapesResultAdapter
        }

        backgroundExecutor = Executors.newSingleThreadExecutor()

        // Configura cámara cuando la view esté lista
        fragmentCameraBinding.viewFinder.post {
            setUpCamera()
        }

        // Crea el FaceLandmarkerHelper en background
        backgroundExecutor.execute {
            faceLandmarkerHelper = FaceLandmarkerHelper(
                context = requireContext(),
                runningMode = RunningMode.LIVE_STREAM,
                minFaceDetectionConfidence = viewModel.currentMinFaceDetectionConfidence,
                minFaceTrackingConfidence = viewModel.currentMinFaceTrackingConfidence,
                minFacePresenceConfidence = viewModel.currentMinFacePresenceConfidence,
                maxNumFaces = viewModel.currentMaxFaces,
                currentDelegate = viewModel.currentDelegate,
                faceLandmarkerHelperListener = this
            )
        }

        initBottomSheetControls()
    }

    // Configura los controles del bottom sheet (sliders)
    private fun initBottomSheetControls() {
        fragmentCameraBinding.bottomSheetLayout.maxFacesValue.text =
            viewModel.currentMaxFaces.toString()
        fragmentCameraBinding.bottomSheetLayout.detectionThresholdValue.text =
            String.format(Locale.US, "%.2f", viewModel.currentMinFaceDetectionConfidence)
        
        // ... más configuraciones de sliders
        
        // Cambio de CPU/GPU
        fragmentCameraBinding.bottomSheetLayout.spinnerDelegate.onItemSelectedListener =
            object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(p0: AdapterView<*>?, p1: View?, p2: Int, p3: Long) {
                    try {
                        faceLandmarkerHelper.currentDelegate = p2
                        updateControlsUi()
                    } catch (e: UninitializedPropertyAccessException) {
                        Log.e(TAG, "FaceLandmarkerHelper has not been initialized yet.")
                    }
                }
                override fun onNothingSelected(p0: AdapterView<*>?) { }
            }
    }

    // Actualiza UI y reinicia el detector
    private fun updateControlsUi() {
        fragmentCameraBinding.bottomSheetLayout.maxFacesValue.text =
            faceLandmarkerHelper.maxNumFaces.toString()
        
        // Reinicia el detector en background
        backgroundExecutor.execute {
            faceLandmarkerHelper.clearFaceLandmarker()
            faceLandmarkerHelper.setupFaceLandmarker()
        }
        fragmentCameraBinding.overlay.clear()
    }

    // Inicializa CameraX
    private fun setUpCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(requireContext())
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            bindCameraUseCases()
        }, ContextCompat.getMainExecutor(requireContext()))
    }

    // Configura casos de uso de la cámara
    @SuppressLint("UnsafeOptInUsageError")
    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider
            ?: throw IllegalStateException("Camera initialization failed.")

        val cameraSelector = CameraSelector.Builder()
            .requireLensFacing(cameraFacing)
            .build()

        // Preview con ratio 4:3 (mejor para modelos de ML)
        preview = Preview.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setTargetRotation(fragmentCameraBinding.viewFinder.display.rotation)
            .build()

        // Analizador de imágenes para detección
        imageAnalyzer = ImageAnalysis.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setTargetRotation(fragmentCameraBinding.viewFinder.display.rotation)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
            .also {
                it.setAnalyzer(backgroundExecutor) { image ->
                    detectFace(image)
                }
            }

        cameraProvider.unbindAll()

        try {
            camera = cameraProvider.bindToLifecycle(
                this, cameraSelector, preview, imageAnalyzer
            )
            preview?.setSurfaceProvider(fragmentCameraBinding.viewFinder.surfaceProvider)
        } catch (exc: Exception) {
            Log.e(TAG, "Use case binding failed", exc)
        }
    }

    // Envía frame al detector
    private fun detectFace(imageProxy: ImageProxy) {
        faceLandmarkerHelper.detectLiveStream(
            imageProxy = imageProxy,
            isFrontCamera = cameraFacing == CameraSelector.LENS_FACING_FRONT
        )
    }

    // Callback cuando hay resultados
    override fun onResults(resultBundle: FaceLandmarkerHelper.ResultBundle) {
        activity?.runOnUiThread {
            if (_fragmentCameraBinding != null) {
                // Actualiza adapter de blendshapes
                if (fragmentCameraBinding.recyclerviewResults.scrollState != SCROLL_STATE_DRAGGING) {
                    faceBlendshapesResultAdapter.updateResults(resultBundle.result)
                    faceBlendshapesResultAdapter.notifyDataSetChanged()
                }

                // Muestra tiempo de inferencia
                fragmentCameraBinding.bottomSheetLayout.inferenceTimeVal.text =
                    String.format("%d ms", resultBundle.inferenceTime)

                // Actualiza OverlayView
                fragmentCameraBinding.overlay.setResults(
                    resultBundle.result,
                    resultBundle.inputImageHeight,
                    resultBundle.inputImageWidth,
                    RunningMode.LIVE_STREAM
                )
                fragmentCameraBinding.overlay.invalidate()
            }
        }
    }

    override fun onEmpty() {
        fragmentCameraBinding.overlay.clear()
        activity?.runOnUiThread {
            faceBlendshapesResultAdapter.updateResults(null)
            faceBlendshapesResultAdapter.notifyDataSetChanged()
        }
    }

    override fun onError(error: String, errorCode: Int) {
        activity?.runOnUiThread {
            Toast.makeText(requireContext(), error, Toast.LENGTH_SHORT).show()
            if (errorCode == FaceLandmarkerHelper.GPU_ERROR) {
                fragmentCameraBinding.bottomSheetLayout.spinnerDelegate.setSelection(
                    FaceLandmarkerHelper.DELEGATE_CPU, false
                )
            }
        }
    }
}
```

---

### MainViewModel.kt

```kotlin
package com.google.mediapipe.examples.facelandmarker

import androidx.lifecycle.ViewModel

/**
 * ViewModel para almacenar configuración del Face Landmarker.
 * Sobrevive cambios de configuración (rotación de pantalla).
 */
class MainViewModel : ViewModel() {

    private var _delegate: Int = FaceLandmarkerHelper.DELEGATE_CPU
    private var _minFaceDetectionConfidence: Float = FaceLandmarkerHelper.DEFAULT_FACE_DETECTION_CONFIDENCE
    private var _minFaceTrackingConfidence: Float = FaceLandmarkerHelper.DEFAULT_FACE_TRACKING_CONFIDENCE
    private var _minFacePresenceConfidence: Float = FaceLandmarkerHelper.DEFAULT_FACE_PRESENCE_CONFIDENCE
    private var _maxFaces: Int = FaceLandmarkerHelper.DEFAULT_NUM_FACES

    val currentDelegate: Int get() = _delegate
    val currentMinFaceDetectionConfidence: Float get() = _minFaceDetectionConfidence
    val currentMinFaceTrackingConfidence: Float get() = _minFaceTrackingConfidence
    val currentMinFacePresenceConfidence: Float get() = _minFacePresenceConfidence
    val currentMaxFaces: Int get() = _maxFaces

    fun setDelegate(delegate: Int) { _delegate = delegate }
    fun setMinFaceDetectionConfidence(confidence: Float) { _minFaceDetectionConfidence = confidence }
    fun setMinFaceTrackingConfidence(confidence: Float) { _minFaceTrackingConfidence = confidence }
    fun setMinFacePresenceConfidence(confidence: Float) { _minFacePresenceConfidence = confidence }
    fun setMaxFaces(maxResults: Int) { _maxFaces = maxResults }
}
```

---

### MainActivity.kt

```kotlin
package com.google.mediapipe.examples.facelandmarker

import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupWithNavController
import com.google.mediapipe.examples.facelandmarker.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    private lateinit var activityMainBinding: ActivityMainBinding
    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        activityMainBinding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(activityMainBinding.root)

        // Configura navegación con BottomNavigationView
        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.fragment_container) as NavHostFragment
        val navController = navHostFragment.navController
        activityMainBinding.navigation.setupWithNavController(navController)
        
        activityMainBinding.navigation.setOnNavigationItemReselectedListener {
            // Ignora re-selección del mismo tab
        }
    }

    override fun onBackPressed() {
        finish()
    }
}
```

---

### fragment_camera.xml (Layout)

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.coordinatorlayout.widget.CoordinatorLayout 
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/camera_container"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <!-- Vista previa de la cámara -->
    <androidx.camera.view.PreviewView
        android:id="@+id/view_finder"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

    <!-- Overlay para dibujar los landmarks encima de la cámara -->
    <com.google.mediapipe.examples.facelandmarker.OverlayView
        android:id="@+id/overlay"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

    <!-- Bottom sheet con controles -->
    <include
        android:id="@+id/bottom_sheet_layout"
        layout="@layout/info_bottom_sheet" />

    <!-- RecyclerView para mostrar blendshapes -->
    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerview_results"
        android:layout_width="match_parent"
        android:layout_height="75dp"
        android:layout_gravity="top"
        android:background="@color/bottom_sheet_background"
        app:layout_anchor="@id/bottom_sheet_layout"
        app:layout_anchorGravity="top" />
</androidx.coordinatorlayout.widget.CoordinatorLayout>
```

---

## Cómo Funciona la Detección

### Paso a Paso

1. **Carga del Modelo**
   - `face_landmarker.task` se descarga automáticamente
   - Se carga en `setupFaceLandmarker()` usando `setModelAssetPath()`

2. **Captura de Frame**
   - CameraX captura frames en formato RGBA_8888
   - Se procesan en un executor de background

3. **Preprocesamiento**
   - El frame se convierte a `Bitmap`
   - Se rota según la orientación del dispositivo
   - Se voltea si usa cámara frontal

4. **Inferencia**
   - Se convierte a `MPImage` (formato MediaPipe)
   - Se ejecuta `detectAsync()` para livestream
   - El resultado llega vía callback

5. **Post-procesamiento**
   - Los landmarks vienen en coordenadas normalizadas (0-1)
   - Se escalan a píxeles según el tamaño de la view
   - Se dibujan en el Canvas de OverlayView

---

## Personalización

### Cambiar el color de los landmarks

En `OverlayView.kt`:
```kotlin
private fun initPaints() {
    // Cambia el color de los puntos
    pointPaint.color = Color.RED  // Era YELLOW
    
    // Cambia el color de las líneas
    linePaint.color = Color.BLUE  // Era mp_color_primary
}
```

### Aumentar el número máximo de caras

En `FaceLandmarkerHelper.kt`:
```kotlin
companion object {
    const val DEFAULT_NUM_FACES = 2  // Era 1
}
```

### Cambiar umbrales de confianza

```kotlin
val faceLandmarkerHelper = FaceLandmarkerHelper(
    minFaceDetectionConfidence = 0.7f,  // Más estricto
    minFaceTrackingConfidence = 0.7f,
    minFacePresenceConfidence = 0.7f,
    // ...
)
```

### Usar solo GPU

```kotlin
val faceLandmarkerHelper = FaceLandmarkerHelper(
    currentDelegate = FaceLandmarkerHelper.DELEGATE_GPU,
    // ...
)
```

---

## Recursos Adicionales

- [MediaPipe Face Landmarker Docs](https://developers.google.com/mediapipe/solutions/vision/face_landmarker)
- [Face Mesh Model Card](https://developers.google.com/mediapipe/solutions/vision/face_landmarker/model_card)
- [CameraX Documentation](https://developer.android.com/training/camerax)

---

## Conclusión

Esta aplicación demuestra cómo integrar MediaPipe Face Landmarker en Android usando:

✅ **CameraX** para captura de video en tiempo real
✅ **MediaPipe Tasks Vision** para detección de landmarks
✅ **Custom View (OverlayView)** para visualización
✅ **MVVM** con ViewModel para manejo de estado
✅ **Navigation Component** para navegación entre pantallas

La separación de responsabilidades permite:
- Modificar la UI sin tocar la lógica de ML
- Cambiar el modelo sin afectar la captura de cámara
- Reutilizar componentes en otros proyectos
