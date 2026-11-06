package com.example.alerta_acv

import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import android.widget.ImageButton
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
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

class FaceActivity : AppCompatActivity() {
    private val TAG = "FaceActivity"
    private lateinit var viewFinder: PreviewView
    private lateinit var overlay: FaceOverlayView
    private lateinit var cameraSwitchButton: ImageButton

    private var faceLandmarker: FaceLandmarker? = null
    private var backgroundExecutor: ExecutorService? = null
    private var cameraProvider: ProcessCameraProvider? = null
    
    // Flag para cámara frontal (afecta el flip horizontal)
    private var isFrontCamera = false

    // Analysis state (New Logic)
    private val votingWindow = ArrayDeque<Boolean>() // true = Asymmetric, false = Symmetric
    private val votingWindowSize = 20
    private var facesFoundCount = 0
    private var framesProcessed = 0
    private var lowLightFrames = 0
    private var isFinished = false

    // EMA State
    private var smileLeftSmoothed = 0.0f
    private var smileRightSmoothed = 0.0f
    private val alpha = 0.2f

    // Gated countdown state
    private var facePresent = false
    private var faceBecameStableAt: Long? = null
    private var countdownDurationMs: Long = 5000L
    private var countdownEndAt: Long? = null
    private var pauseStartedAt: Long? = null
    private var startedOnce = false
    private var sessionStartMs: Long = 0L
    private var noFaceTimeoutMs: Long = 30000L
    private var lastLogMs: Long = 0L
    private var frameSkip = 0
    private var lastFpsLogMs: Long = 0L
    private var lastFpsFrames: Int = 0

    // Last detection info for overlay
    private var lastRect: android.graphics.RectF? = null
    private var lastNose: Pair<Float, Float>? = null
    private var lastLeftMouth: Pair<Float, Float>? = null
    private var lastRightMouth: Pair<Float, Float>? = null
    private var lastLowLight = false

    companion object {
        var pendingCallback: ((Result<FaceResult>) -> Unit)? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_face)

        viewFinder = findViewById(R.id.viewFinder)
        overlay = findViewById(R.id.faceOverlay)
        cameraSwitchButton = findViewById(R.id.cameraSwitchButton)

        cameraSwitchButton.setOnClickListener {
            toggleCamera()
        }

        backgroundExecutor = Executors.newSingleThreadExecutor()

        countdownDurationMs = intent.getLongExtra("DURATION", 5000L)
        noFaceTimeoutMs = intent.getLongExtra("NO_FACE_TIMEOUT", 30000L)
        sessionStartMs = SystemClock.elapsedRealtime()

        setupFaceLandmarker()
        startCamera()

        // Initial overlay message
        postOverlay(null, null, null, null, false, false, null, "Enfoca el rostro dentro del recuadro", null, null)
    }

    private fun setupFaceLandmarker() {
        val baseOptionsBuilder = BaseOptions.builder()
            .setModelAssetPath("models/face_landmarker.task")

        val baseOptions = baseOptionsBuilder.build()

        val optionsBuilder = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinFaceDetectionConfidence(0.5f)
            .setRunningMode(RunningMode.VIDEO)
            .setOutputFaceBlendshapes(true)

        val options = optionsBuilder.build()

        try {
            faceLandmarker = FaceLandmarker.createFromOptions(this, options)
        } catch (e: Exception) {
            Log.e(TAG, "Face Landmarker failed to load: ${e.message}")
            finishWithError(e)
        }
    }

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            // Ensure viewFinder has been laid out to get correct width/height for ViewPort
            if (viewFinder.width == 0 || viewFinder.height == 0) {
                viewFinder.post { bindCameraUseCases() }
            } else {
                bindCameraUseCases()
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun toggleCamera() {
        isFrontCamera = !isFrontCamera
        bindCameraUseCases()
    }

    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider ?: return
        val cameraSelector = if (isFrontCamera) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA

        // Usar el mismo AspectRatio para Preview e ImageAnalysis (como la guía)
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
            
            // 1) Convertir YUV a Bitmap y rotarlo ANTES de enviarlo a MediaPipe
            val rotatedBitmap = toRotatedBitmap(imageProxy, rotationDegrees, isFrontCamera)
            val mpImage = BitmapImageBuilder(rotatedBitmap).build()
            
            // El bitmap ya está rotado, así que imageWidth/imageHeight son las dimensiones finales
            val imageWidth = rotatedBitmap.width.toFloat()
            val imageHeight = rotatedBitmap.height.toFloat()

            var detected = false
            var asymmetry: Double? = null
            var rect: android.graphics.RectF? = null
            var kpNose: Pair<Float, Float>? = null
            var kpLeft: Pair<Float, Float>? = null
            var kpRight: Pair<Float, Float>? = null
            var allLandmarks: List<Pair<Float, Float>>? = null
            var connectors: List<Pair<Int, Int>>? = null

            faceLandmarker?.let { landmarker ->
                val ts = SystemClock.elapsedRealtime()
                
                // MediaPipe recibe el bitmap ya rotado, no necesita ImageProcessingOptions
                val result = landmarker.detectForVideo(mpImage, ts)
                if (result.faceLandmarks().isNotEmpty() && result.faceBlendshapes().isPresent) {
                    detected = true
                    facesFoundCount++
                    val landmarks = result.faceLandmarks()[0]
                    val blendshapes = result.faceBlendshapes().get()[0]

                    // 1. Extract Smile Blendshapes
                    // Indices based on MediaPipe documentation or iteration
                    // Typically: mouthSmileLeft, mouthSmileRight. 
                    // We iterate to find them by name if possible, or use known indices if fixed.
                    // For simplicity in this snippet, we assume we can access them by name or index.
                    // MediaPipe Java API usually provides a list of categories.
                    
                    var rawSmileLeft = 0.0f
                    var rawSmileRight = 0.0f

                    for (category in blendshapes) {
                        if (category.categoryName() == "mouthSmileLeft") rawSmileLeft = category.score()
                        if (category.categoryName() == "mouthSmileRight") rawSmileRight = category.score()
                    }

                    // 2. Apply EMA Smoothing
                    smileLeftSmoothed = alpha * rawSmileLeft + (1 - alpha) * smileLeftSmoothed
                    smileRightSmoothed = alpha * rawSmileRight + (1 - alpha) * smileRightSmoothed

                    // 3. Check Activation (Are they smiling?)
                    val maxSmile = max(smileLeftSmoothed, smileRightSmoothed)
                    val isSmiling = maxSmile >= 0.30f

                    // 4. Calculate Delta
                    val delta = abs(smileLeftSmoothed - smileRightSmoothed)
                    asymmetry = delta.toDouble()

                    // 5. Classify Frame
                    // Symmetric: Both > 0.28 AND Delta < 0.12
                    // Asymmetric: (One < 0.28 OR Delta >= 0.12) AND Activation met
                    
                    var isAsymmetricFrame = false
                    
                    if (isSmiling) {
                        val symmetric = (smileLeftSmoothed > 0.28 && smileRightSmoothed > 0.28 && delta < 0.12)
                        if (!symmetric) {
                            isAsymmetricFrame = true
                        }
                        
                        // Add to voting window
                        if (votingWindow.size >= votingWindowSize) {
                            votingWindow.removeFirst()
                        }
                        votingWindow.addLast(isAsymmetricFrame)
                    }

                    // --- Visualization Logic (Keep existing) ---
                    val nose = landmarks[1]
                    val leftMouth = landmarks[61]
                    val rightMouth = landmarks[291]

                    /**
                     * Mapea coordenadas normalizadas (0-1) del bitmap rotado al overlay.
                     */
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

                    fun mapX(xn: Float, yn: Float): Float = mapToView(xn, yn).first
                    fun mapY(xn: Float, yn: Float): Float = mapToView(xn, yn).second

                    // Bounding rect
                    var minX = Float.POSITIVE_INFINITY
                    var minY = Float.POSITIVE_INFINITY
                    var maxX = Float.NEGATIVE_INFINITY
                    var maxY = Float.NEGATIVE_INFINITY
                    for (lm in landmarks) {
                        val vx = mapX(lm.x(), lm.y())
                        val vy = mapY(lm.x(), lm.y())
                        if (vx < minX) minX = vx
                        if (vy < minY) minY = vy
                        if (vx > maxX) maxX = vx
                        if (vy > maxY) maxY = vy
                    }
                    rect = android.graphics.RectF(minX, minY, maxX, maxY)
                    kpNose = Pair(mapX(nose.x(), nose.y()), mapY(nose.x(), nose.y()))
                    kpLeft = Pair(mapX(leftMouth.x(), leftMouth.y()), mapY(leftMouth.x(), leftMouth.y()))
                    kpRight = Pair(mapX(rightMouth.x(), rightMouth.y()), mapY(rightMouth.x(), rightMouth.y()))

                    // Todos los 478 landmarks
                    val tmp = ArrayList<Pair<Float, Float>>(landmarks.size)
                    for (lm in landmarks) {
                        tmp.add(Pair(mapX(lm.x(), lm.y()), mapY(lm.x(), lm.y())))
                    }
                    allLandmarks = tmp
                    
                    // Conectores de MediaPipe
                    val connList = ArrayList<Pair<Int, Int>>()
                    FaceLandmarker.FACE_LANDMARKS_CONNECTORS.filterNotNull().forEach { conn ->
                        connList.add(Pair(conn.start(), conn.end()))
                    }
                    connectors = connList
                }
            }

            // Update gating state
            val now = SystemClock.elapsedRealtime()
            if (!startedOnce && now - sessionStartMs > noFaceTimeoutMs) {
                Log.w(TAG, "Timeout sin rostro detectado. Finalizando.")
                runOnUiThread { postOverlay(null, null, null, null, false, lastLowLight, null, "Sin rostro detectado", null, null) }
                finishAnalysis()
                return
            }

            if (detected) {
                if (!facePresent) {
                    facePresent = true
                    faceBecameStableAt = now
                }
            } else {
                if (facePresent) {
                    facePresent = false
                    pauseStartedAt = now
                }
            }

            // Start countdown only after stable face for 600ms
            if (facePresent && countdownEndAt == null) {
                val stableSince = faceBecameStableAt
                if (stableSince != null && now - stableSince >= 600L) {
                    countdownEndAt = now + countdownDurationMs
                    startedOnce = true
                    Log.d(TAG, "Iniciando conteo de ${countdownDurationMs}ms")
                }
            }

            // Pause/Resume behavior
            val endAt = countdownEndAt
            if (endAt != null) {
                if (!facePresent) {
                    val pausedAt = pauseStartedAt
                    // If face lost for more than 1000ms, reset countdown
                    if (pausedAt != null && now - pausedAt > 1000L) {
                        Log.d(TAG, "Rostro perdido >1s. Reiniciando conteo")
                        countdownEndAt = null
                        faceBecameStableAt = null
                        pauseStartedAt = null
                    }
                } else {
                    // If resuming shortly, extend end time by pause duration
                    val pausedAt = pauseStartedAt
                    if (pausedAt != null) {
                        val extra = now - pausedAt
                        countdownEndAt = endAt + extra
                        pauseStartedAt = null
                    }
                }
            }

            // Remaining countdown
            val remaining = countdownEndAt?.let { (it - now).coerceAtLeast(0L) }
            if (remaining != null && remaining == 0L) {
                Log.d(TAG, "Conteo finalizado. Cerrando análisis.")
                runOnUiThread { postOverlay(rect, kpNose, kpLeft, kpRight, detected, lastLowLight, 0L, "Listo", allLandmarks, connectors) }
                finishAnalysis()
                return
            }

            // Update overlay
            lastRect = rect
            lastNose = kpNose
            lastLeftMouth = kpLeft
            lastRightMouth = kpRight

            val msg = when {
                !detected -> if (!startedOnce) "Buscando rostro..." else "Rostro perdido, reencuadra"
                remaining == null -> "Mantén el rostro quieto"
                else -> "¡Sonríe mostrando los dientes!"
            }
            runOnUiThread { postOverlay(rect, kpNose, kpLeft, kpRight, detected, lastLowLight, remaining, msg, allLandmarks, connectors) }

            // Throttled logs
            if (now - lastLogMs > 300L) {
                lastLogMs = now
                val a = asymmetry?.let { String.format("%.3f", it) } ?: "-"
                val luma = if (lastLowLight) "low" else "ok"
                val rem = remaining?.let { "${it}ms" } ?: "--"
                Log.d(TAG, "face=$detected, countdown=$rem, asym=$a, light=$luma, frames=$framesProcessed")
            }

            // FPS logging roughly every second
            if (now - lastFpsLogMs > 1000L) {
                val dt = (now - lastFpsLogMs).coerceAtLeast(1L)
                val framesDelta = framesProcessed - lastFpsFrames
                val procFps = framesDelta * 1000.0 / dt
                Log.d(TAG, String.format("procFps=%.1f (all frames)", procFps))
                lastFpsLogMs = now
                lastFpsFrames = framesProcessed
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing image", e)
        } finally {
            imageProxy.close()
        }
    }

    private fun postOverlay(
        rect: android.graphics.RectF?,
        nose: Pair<Float, Float>?,
        leftMouth: Pair<Float, Float>?,
        rightMouth: Pair<Float, Float>?,
        hasFace: Boolean,
        lowLight: Boolean,
        countdownMillis: Long?,
        message: String?,
        landmarks: List<Pair<Float, Float>>?,
        connectors: List<Pair<Int, Int>>?
    ) {
        overlay.update(rect, nose, leftMouth, rightMouth, hasFace, lowLight, countdownMillis, message, landmarks, connectors)
    }

    /**
     * Convierte ImageProxy a Bitmap y aplica rotación + flip (para cámara frontal).
     * MediaPipe recibirá un bitmap ya orientado correctamente.
     */
    private fun toRotatedBitmap(imageProxy: ImageProxy, rotationDegrees: Int, isFrontCamera: Boolean): Bitmap {
        // Con OUTPUT_IMAGE_FORMAT_RGBA_8888, podemos usar toBitmap() directamente
        val originalBitmap: Bitmap = imageProxy.toBitmap()
        
        // Si no hay rotación ni flip, devolver el original
        if (rotationDegrees == 0 && !isFrontCamera) {
            return originalBitmap
        }
        
        // 2) Aplicar rotación y flip con Matrix (como muestra la guía)
        val matrix = Matrix()
        matrix.postRotate(rotationDegrees.toFloat())
        
        // Para cámara frontal, aplicar flip horizontal para efecto espejo
        if (isFrontCamera) {
            matrix.postScale(-1f, 1f, originalBitmap.width / 2f, originalBitmap.height / 2f)
        }
        
        // 3) Crear bitmap transformado
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

        val faceFound = facesFoundCount > (framesProcessed * 0.1)
        val isLowLight = lowLightFrames > (framesProcessed * 0.5)


        // Calculate final result based on voting
        var asymmetricVotes = 0
        for (vote in votingWindow) {
            if (vote) asymmetricVotes++
        }
        
        // Threshold: 12/20 (60%)
        val isAsymmetric = asymmetricVotes >= 12
        
        val finalAsymmetry = if (isAsymmetric) 1.0 else 0.0

        val level = if (isAsymmetric) "Fuerte" else "Sin"

        val result = FaceResult(
            asymmetry = finalAsymmetry,
            level = level,
            faceFound = faceFound,
            lowLight = isLowLight
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
