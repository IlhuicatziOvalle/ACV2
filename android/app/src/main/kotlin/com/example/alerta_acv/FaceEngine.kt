package com.example.alerta_acv

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.util.Log
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
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
import kotlin.math.pow
import kotlin.math.sqrt

class FaceEngine(private val context: Context) {
    private val TAG = "FaceEngine"
    private var faceLandmarker: FaceLandmarker? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var backgroundExecutor: ExecutorService? = null
    
    // Accumulators for the session
    private val asymmetryScores = mutableListOf<Double>()
    private var facesFoundCount = 0
    private var framesProcessed = 0
    private var lowLightFrames = 0

    fun init() {
        backgroundExecutor = Executors.newSingleThreadExecutor()
        setupFaceLandmarker()
    }

    private fun setupFaceLandmarker() {
        val baseOptionsBuilder = BaseOptions.builder()
            .setModelAssetPath("models/face_landmarker.task")

        val baseOptions = baseOptionsBuilder.build()

        val optionsBuilder = FaceLandmarker.FaceLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setMinFaceDetectionConfidence(0.5f)
            .setRunningMode(RunningMode.IMAGE) // Using IMAGE mode for simplicity frame-by-frame

        val options = optionsBuilder.build()
        
        try {
            faceLandmarker = FaceLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            Log.e(TAG, "Face Landmarker failed to load: ${e.message}")
        }
    }

    fun startAnalysis(durationMillis: Long, callback: (FaceResult) -> Unit) {
        asymmetryScores.clear()
        facesFoundCount = 0
        framesProcessed = 0
        lowLightFrames = 0

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()
            bindCameraUseCases()
            
            // Stop after duration
            android.os.Handler(context.mainLooper).postDelayed({
                stopCamera()
                val result = calculateFinalResult()
                callback(result)
            }, durationMillis)
            
        }, ContextCompat.getMainExecutor(context))
    }

    private fun bindCameraUseCases() {
        val cameraProvider = cameraProvider ?: return
        val lifecycleOwner = context as? LifecycleOwner ?: return

        val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

        val imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()

        imageAnalysis.setAnalyzer(backgroundExecutor!!) { imageProxy ->
            processImage(imageProxy)
        }

        try {
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                imageAnalysis
            )
        } catch (exc: Exception) {
            Log.e(TAG, "Use case binding failed", exc)
        }
    }

    private fun processImage(imageProxy: ImageProxy) {
        framesProcessed++
        
        // Check low light (simple brightness check)
        if (isLowLight(imageProxy)) {
            lowLightFrames++
        }

        val mpImage = toMPImage(imageProxy)
        
        faceLandmarker?.let { landmarker ->
            val result = landmarker.detect(mpImage)
            processLandmarkerResult(result)
        }
        
        imageProxy.close()
    }
    
    private fun toMPImage(imageProxy: ImageProxy): MPImage {
        // Convert ImageProxy to Bitmap then to MPImage
        // Note: This is a simplified conversion. For production, YUV to RGB conversion is better.
        val bitmap = imageProxy.toBitmap()
        // Rotate if needed (CameraX handles rotation usually via targetRotation, but toBitmap handles it too)
        return BitmapImageBuilder(bitmap).build()
    }

    private fun isLowLight(imageProxy: ImageProxy): Boolean {
        // Simple average pixel intensity check from Y plane
        val buffer = imageProxy.planes[0].buffer
        val data = ByteArray(buffer.remaining())
        buffer.get(data)
        var sum = 0L
        for (b in data) {
            sum += (b.toInt() and 0xFF)
        }
        val average = sum / data.size
        return average < 50 // Threshold for low light (0-255)
    }

    private fun processLandmarkerResult(result: FaceLandmarkerResult) {
        if (result.faceLandmarks().isNotEmpty()) {
            facesFoundCount++
            val landmarks = result.faceLandmarks()[0]
            
            // Indices (approximate for MediaPipe Face Mesh):
            // Nose tip: 1
            // Left mouth corner: 61
            // Right mouth corner: 291
            
            val nose = landmarks[1]
            val leftMouth = landmarks[61]
            val rightMouth = landmarks[291]
            
            // Calculate distances from nose to mouth corners
            val distLeft = sqrt((nose.x() - leftMouth.x()).pow(2) + (nose.y() - leftMouth.y()).pow(2))
            val distRight = sqrt((nose.x() - rightMouth.x()).pow(2) + (nose.y() - rightMouth.y()).pow(2))
            
            val maxDist = max(distLeft, distRight)
            val asymmetry = if (maxDist > 0) abs(distLeft - distRight) / maxDist else 0.0
            
            asymmetryScores.add(asymmetry.toDouble())
        }
    }

    private fun stopCamera() {
        cameraProvider?.unbindAll()
    }

    private fun calculateFinalResult(): FaceResult {
        val faceFound = facesFoundCount > (framesProcessed * 0.1) // At least 10% of frames have face
        val isLowLight = lowLightFrames > (framesProcessed * 0.5) // >50% frames are dark
        
        var finalAsymmetry = 0.0
        if (asymmetryScores.isNotEmpty()) {
            finalAsymmetry = asymmetryScores.average()
        }
        
        // Level classification (simple logic here, can be refined in Dart)
        // < 0.08 -> sin
        // 0.08 - 0.14 -> leve
        // >= 0.15 -> fuerte
        val level = when {
            finalAsymmetry < 0.08 -> "Sin"
            finalAsymmetry < 0.15 -> "Leve"
            else -> "Fuerte"
        }

        return FaceResult(
            asymmetry = finalAsymmetry,
            level = level,
            faceFound = faceFound,
            lowLight = isLowLight
        )
    }
    
    fun dispose() {
        backgroundExecutor?.shutdown()
    }
}
