package com.example.alerta_acv

import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.AspectRatio
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.max

/**
 * ArmsActivity: Captura video, detecta pose con MediaPipe PoseLandmarker,
 * calcula deltaY (diferencia vertical entre muñecas) y detecta caída de brazos.
 */
class ArmsActivity : AppCompatActivity() {
    private val TAG = "ArmsActivity"
    private lateinit var viewFinder: PreviewView
    private lateinit var overlay: ArmsOverlayView

    private var poseLandmarker: PoseLandmarker? = null
    private var backgroundExecutor: ExecutorService? = null
    private var cameraProvider: ProcessCameraProvider? = null

    // Flag para cámara frontal (afecta el flip horizontal)
    private var isFrontCamera = false

    // Estado de análisis
    private var framesProcessed = 0
    private var poseFoundCount = 0
    private var lowLightFrames = 0
    private var isFinished = false

    // Índices de landmarks de MediaPipe Pose para brazos
    // https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker
    private val LEFT_SHOULDER = 11
    private val RIGHT_SHOULDER = 12
    private val LEFT_ELBOW = 13
    private val RIGHT_ELBOW = 14
    private val LEFT_WRIST = 15
    private val RIGHT_WRIST = 16

    // Detección de caída
    // Baseline: posición Y inicial de las muñecas (relativa a hombros)
    private var baselineDeltaY: Double? = null
    private var baselineSetAt: Long? = null
    private var currentDeltaY: Double = 0.0
    private var maxDeltaYChange: Double = 0.0  // Mayor cambio desde baseline
    private val deltaYHistory = mutableListOf<Double>()
    
    // Umbral para detectar caída (cambio significativo en Y)
    private val DROP_THRESHOLD = 0.15  // 15% del frame height

    // Gated countdown state
    private var posePresent = false
    private var poseBecameStableAt: Long? = null
    private var countdownDurationMs: Long = 5000L
    private var countdownEndAt: Long? = null
    private var pauseStartedAt: Long? = null
    private var startedOnce = false
    private var sessionStartMs: Long = 0L
    private var noPoseTimeoutMs: Long = 30000L
    private var lastLogMs: Long = 0L
    private var lastLowLight = false

    companion object {
        var pendingCallback: ((Result<ArmsResult>) -> Unit)? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_arms)

        viewFinder = findViewById(R.id.previewView)
        overlay = findViewById(R.id.armsOverlay)

        backgroundExecutor = Executors.newSingleThreadExecutor()

        countdownDurationMs = intent.getLongExtra("DURATION", 5000L)
        noPoseTimeoutMs = intent.getLongExtra("NO_POSE_TIMEOUT", 30000L)
        sessionStartMs = SystemClock.elapsedRealtime()

        setupPoseLandmarker()
        startCamera()

        // Mensaje inicial
        postOverlay(null, null, false, false, 0.0, false, null, "Levanta ambos brazos a la altura de los hombros")
    }

    private fun setupPoseLandmarker() {
        val baseOptionsBuilder = BaseOptions.builder()
            .setModelAssetPath("models/pose_landmarker_lite.task")

        val baseOptions = baseOptionsBuilder.build()

        val optionsBuilder = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinPoseDetectionConfidence(0.5f)
            .setMinPosePresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setRunningMode(RunningMode.VIDEO)
            .setNumPoses(1)

        val options = optionsBuilder.build()

        try {
            poseLandmarker = PoseLandmarker.createFromOptions(this, options)
        } catch (e: Exception) {
            Log.e(TAG, "Pose Landmarker failed to load: ${e.message}")
            finishWithError(e)
        }
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            if (viewFinder.width == 0 || viewFinder.height == 0) {
                viewFinder.post { bindCameraUseCases() }
            } else {
                bindCameraUseCases()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider ?: return
        // Usar cámara trasera como indica el plan de desarrollo
        val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
        isFrontCamera = false

        val preview = Preview.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setTargetRotation(viewFinder.display.rotation)
            .build()
            .also {
                it.setSurfaceProvider(viewFinder.surfaceProvider)
            }

        val imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setTargetRotation(viewFinder.display.rotation)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()

        imageAnalysis.setAnalyzer(backgroundExecutor!!) { imageProxy ->
            processImage(imageProxy)
        }

        try {
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(this, cameraSelector, preview, imageAnalysis)
        } catch (exc: Exception) {
            Log.e(TAG, "Use case binding failed", exc)
            finishWithError(exc)
        }
    }

    private fun processImage(imageProxy: ImageProxy) {
        if (isFinished) {
            imageProxy.close()
            return
        }

        try {
            framesProcessed++

            val lowLight = isLowLight(imageProxy)
            if (lowLight) lowLightFrames++
            lastLowLight = lowLight

            val rotationDegrees = imageProxy.imageInfo.rotationDegrees

            // Convertir y rotar bitmap ANTES de enviar a MediaPipe
            val rotatedBitmap = toRotatedBitmap(imageProxy, rotationDegrees, isFrontCamera)
            val mpImage = BitmapImageBuilder(rotatedBitmap).build()

            val imageWidth = rotatedBitmap.width.toFloat()
            val imageHeight = rotatedBitmap.height.toFloat()

            var detected = false
            var dropDetected = false
            var landmarks: List<Pair<Float, Float>>? = null
            var connections: List<Pair<Int, Int>>? = null

            poseLandmarker?.let { landmarker ->
                val ts = SystemClock.elapsedRealtime()
                val result = landmarker.detectForVideo(mpImage, ts)

                if (result.landmarks().isNotEmpty()) {
                    detected = true
                    poseFoundCount++
                    val poseLandmarks = result.landmarks()[0]

                    // Extraer landmarks de brazos
                    val leftShoulder = poseLandmarks[LEFT_SHOULDER]
                    val rightShoulder = poseLandmarks[RIGHT_SHOULDER]
                    val leftElbow = poseLandmarks[LEFT_ELBOW]
                    val rightElbow = poseLandmarks[RIGHT_ELBOW]
                    val leftWrist = poseLandmarks[LEFT_WRIST]
                    val rightWrist = poseLandmarks[RIGHT_WRIST]

                    // Calcular deltaY: diferencia vertical entre muñecas
                    // Normalizadas 0-1, Y aumenta hacia abajo
                    val leftWristY = leftWrist.y()
                    val rightWristY = rightWrist.y()
                    val shoulderY = (leftShoulder.y() + rightShoulder.y()) / 2f

                    // DeltaY = diferencia absoluta entre las posiciones Y de las muñecas
                    // normalizada respecto a la altura del frame
                    val wristDeltaY = abs(leftWristY - rightWristY).toDouble()
                    
                    // También calcular caída relativa a hombros
                    val leftArmDrop = (leftWristY - shoulderY).toDouble()  // Positivo = muñeca debajo de hombro
                    val rightArmDrop = (rightWristY - shoulderY).toDouble()
                    
                    // El deltaY que nos interesa es la diferencia entre brazos (asimetría)
                    currentDeltaY = wristDeltaY
                    deltaYHistory.add(currentDeltaY)

                    // Establecer baseline cuando se inicia el conteo
                    val now = SystemClock.elapsedRealtime()
                    if (baselineDeltaY == null && countdownEndAt != null) {
                        baselineDeltaY = currentDeltaY
                        baselineSetAt = now
                        Log.d(TAG, "Baseline establecido: deltaY=${String.format("%.3f", baselineDeltaY)}")
                    }

                    // Detectar caída: uno de los brazos cae significativamente
                    // o hay asimetría significativa
                    val baseline = baselineDeltaY
                    if (baseline != null) {
                        val change = currentDeltaY - baseline
                        if (change > maxDeltaYChange) {
                            maxDeltaYChange = change
                        }
                        // Caída detectada si la asimetría aumenta significativamente
                        // o si un brazo cae mucho respecto a los hombros
                        dropDetected = currentDeltaY >= DROP_THRESHOLD || 
                                       leftArmDrop > 0.3 || rightArmDrop > 0.3
                    }

                    // Mapear landmarks a coordenadas de view
                    fun mapToView(xn: Float, yn: Float): Pair<Float, Float> {
                        val px = xn * imageWidth
                        val py = yn * imageHeight

                        val vw = viewFinder.width.toFloat().coerceAtLeast(1f)
                        val vh = viewFinder.height.toFloat().coerceAtLeast(1f)
                        val scale = max(vw / imageWidth, vh / imageHeight)

                        val scaledW = imageWidth * scale
                        val scaledH = imageHeight * scale

                        val offX = (vw - scaledW) / 2f
                        val offY = (vh - scaledH) / 2f

                        val vx = px * scale + offX
                        val vy = py * scale + offY
                        return Pair(vx, vy)
                    }

                    // Mapear TODOS los 33 landmarks de pose
                    val allLandmarks = ArrayList<Pair<Float, Float>>(poseLandmarks.size)
                    for (lm in poseLandmarks) {
                        allLandmarks.add(mapToView(lm.x(), lm.y()))
                    }
                    landmarks = allLandmarks

                    // Usar conectores oficiales de MediaPipe PoseLandmarker
                    val connList = ArrayList<Pair<Int, Int>>()
                    PoseLandmarker.POSE_LANDMARKS.filterNotNull().forEach { conn ->
                        connList.add(Pair(conn.start(), conn.end()))
                    }
                    connections = connList
                }
            }

            // Actualizar estado de gating
            val now = SystemClock.elapsedRealtime()
            if (!startedOnce && now - sessionStartMs > noPoseTimeoutMs) {
                Log.w(TAG, "Timeout sin pose detectada. Finalizando.")
                runOnUiThread { 
                    postOverlay(null, null, false, false, 0.0, lastLowLight, null, "No se detectó la pose") 
                }
                finishAnalysis()
                return
            }

            if (detected) {
                if (!posePresent) {
                    posePresent = true
                    poseBecameStableAt = now
                }
            } else {
                if (posePresent) {
                    posePresent = false
                    pauseStartedAt = now
                }
            }

            // Iniciar countdown después de pose estable por 600ms
            if (posePresent && countdownEndAt == null) {
                val stableSince = poseBecameStableAt
                if (stableSince != null && now - stableSince >= 600L) {
                    countdownEndAt = now + countdownDurationMs
                    startedOnce = true
                    Log.d(TAG, "Iniciando conteo de ${countdownDurationMs}ms")
                }
            }

            // Pausa/Resumir
            val endAt = countdownEndAt
            if (endAt != null) {
                if (!posePresent) {
                    val pausedAt = pauseStartedAt
                    if (pausedAt != null && now - pausedAt > 1000L) {
                        Log.d(TAG, "Pose perdida >1s. Reiniciando conteo")
                        countdownEndAt = null
                        poseBecameStableAt = null
                        pauseStartedAt = null
                        baselineDeltaY = null  // Reset baseline también
                        maxDeltaYChange = 0.0
                    }
                } else {
                    val pausedAt = pauseStartedAt
                    if (pausedAt != null) {
                        val extra = now - pausedAt
                        countdownEndAt = endAt + extra
                        pauseStartedAt = null
                    }
                }
            }

            // Tiempo restante
            val remaining = countdownEndAt?.let { (it - now).coerceAtLeast(0L) }
            if (remaining != null && remaining == 0L) {
                Log.d(TAG, "Conteo finalizado. Cerrando análisis.")
                runOnUiThread { 
                    postOverlay(landmarks, connections, detected, dropDetected, currentDeltaY, lastLowLight, 0L, "Listo") 
                }
                finishAnalysis()
                return
            }

            // Actualizar overlay
            val msg = when {
                !detected -> if (!startedOnce) "Levanta ambos brazos..." else "Pose perdida, vuelve a posición"
                remaining == null -> "Mantén los brazos extendidos"
                dropDetected -> "⚠ Se detectó caída de brazo"
                else -> "Mantén la posición..."
            }
            runOnUiThread { 
                postOverlay(landmarks, connections, detected, dropDetected, currentDeltaY, lastLowLight, remaining, msg) 
            }

            // Logs throttled
            if (now - lastLogMs > 300L) {
                lastLogMs = now
                val dy = String.format("%.3f", currentDeltaY)
                val drop = if (dropDetected) "YES" else "no"
                val luma = if (lastLowLight) "low" else "ok"
                val rem = remaining?.let { "${it}ms" } ?: "--"
                Log.d(TAG, "pose=$detected, countdown=$rem, deltaY=$dy, drop=$drop, light=$luma")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing image", e)
        } finally {
            imageProxy.close()
        }
    }

    private fun postOverlay(
        landmarks: List<Pair<Float, Float>>?,
        connections: List<Pair<Int, Int>>?,
        poseDetected: Boolean,
        dropDetected: Boolean,
        deltaY: Double,
        lowLight: Boolean,
        countdownMillis: Long?,
        message: String?
    ) {
        overlay.update(landmarks, connections, poseDetected, dropDetected, deltaY, lowLight, countdownMillis, message)
    }

    /**
     * Convierte ImageProxy a Bitmap y aplica rotación + flip (para cámara frontal).
     */
    private fun toRotatedBitmap(imageProxy: ImageProxy, rotationDegrees: Int, isFrontCamera: Boolean): Bitmap {
        val originalBitmap: Bitmap = imageProxy.toBitmap()

        if (rotationDegrees == 0 && !isFrontCamera) {
            return originalBitmap
        }

        val matrix = Matrix()
        matrix.postRotate(rotationDegrees.toFloat())

        // Para cámara frontal, aplicar flip horizontal para efecto espejo
        if (isFrontCamera) {
            matrix.postScale(-1f, 1f, originalBitmap.width / 2f, originalBitmap.height / 2f)
        }

        return Bitmap.createBitmap(
            originalBitmap,
            0, 0,
            originalBitmap.width, originalBitmap.height,
            matrix,
            true
        )
    }

    private fun isLowLight(imageProxy: ImageProxy): Boolean {
        val buffer = imageProxy.planes[0].buffer
        val data = ByteArray(buffer.remaining())
        buffer.get(data)
        var sum = 0L
        for (b in data) {
            sum += (b.toInt() and 0xFF)
        }
        val average = sum / data.size
        return average < 50
    }

    private fun finishAnalysis() {
        if (isFinished) return
        isFinished = true

        val poseFound = poseFoundCount > (framesProcessed * 0.1)
        val isLowLight = lowLightFrames > (framesProcessed * 0.5)

        // Calcular deltaY promedio
        val avgDeltaY = if (deltaYHistory.isNotEmpty()) {
            deltaYHistory.average()
        } else {
            0.0
        }

        // Determinar si hubo caída basado en el máximo cambio observado
        val dropDetected = maxDeltaYChange >= DROP_THRESHOLD || avgDeltaY >= DROP_THRESHOLD

        Log.d(TAG, "Análisis completo: avgDeltaY=${String.format("%.3f", avgDeltaY)}, maxChange=${String.format("%.3f", maxDeltaYChange)}, drop=$dropDetected")

        val result = ArmsResult(
            deltaY = avgDeltaY,
            dropDetected = dropDetected
        )

        pendingCallback?.invoke(Result.success(result))
        pendingCallback = null
        finish()
    }

    private fun finishWithError(e: Exception) {
        if (isFinished) return
        isFinished = true
        pendingCallback?.invoke(Result.failure(e))
        pendingCallback = null
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        backgroundExecutor?.shutdown()
    }
}
