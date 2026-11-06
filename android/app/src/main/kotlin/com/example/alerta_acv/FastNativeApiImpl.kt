package com.example.alerta_acv

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine

/**
 * Implementación de FastNativeApi
 * Usa AsrEngine para reconocimiento de voz real con Vosk
 */
class FastNativeApiImpl(private val context: Context) : FastNativeApi {
    private val TAG = "FastNativeApiImpl"
    private var asrEngine: AsrEngine? = null
    private var faceEngine: FaceEngine? = null

    override fun initialize() {
        Log.d(TAG, "FastNativeApi initializing...")
        asrEngine = AsrEngine(context)
        asrEngine?.init()
        
        faceEngine = FaceEngine(context)
        faceEngine?.init()
        
        Log.d(TAG, "FastNativeApi initialized")
    }

    override fun runSpeech(targetPhrase: String, maxSeconds: Long, callback: (Result<SpeechResult>) -> Unit) {
        Log.d(TAG, "runSpeech called: targetPhrase=$targetPhrase, maxSeconds=$maxSeconds")
        
        val engine = asrEngine
        if (engine == null) {
            Log.w(TAG, "AsrEngine not initialized, using fallback")
            callback(Result.success(SpeechResult(
                transcript = "",
                similarity = 0.0,
                level = "Fuerte"
            )))
            return
        }
        
        // Ejecutar en un hilo secundario para no bloquear la UI
        Thread {
            try {
                // Grabar y reconocer audio
                val recognitionResult = engine.recognize(maxSeconds.toInt())
                
                if (recognitionResult == null) {
                    Log.e(TAG, "Recognition failed")
                    callback(Result.success(SpeechResult(
                        transcript = "",
                        similarity = 0.0,
                        level = "Fuerte"
                    )))
                    return@Thread
                }
                
                val (transcript, _) = recognitionResult
                
                // Calcular similitud con la frase objetivo
                val similarity = engine.calculateSimilarity(transcript, targetPhrase)
                
                // Clasificar el nivel
                val level = engine.classifyLevel(similarity)
                
                Log.d(TAG, "Recognition result: transcript='$transcript', similarity=$similarity, level=$level")
                
                callback(Result.success(SpeechResult(
                    transcript = transcript,
                    similarity = similarity,
                    level = level
                )))
            } catch (e: Exception) {
                Log.e(TAG, "Error in runSpeech thread", e)
                callback(Result.failure(e))
            }
        }.start()
    }

    override fun runFace(maxMillis: Long, callback: (Result<FaceResult>) -> Unit) {
        Log.d(TAG, "runFace called: maxMillis=$maxMillis")
        
        // Set the callback
        FaceActivity.pendingCallback = callback
        
        // Start the activity
        val intent = android.content.Intent(context, FaceActivity::class.java)
        intent.putExtra("DURATION", maxMillis)
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    override fun runArms(seconds: Long, callback: (Result<ArmsResult>) -> Unit) {
        Log.d(TAG, "runArms called: seconds=$seconds")
        
        // Set the callback
        ArmsActivity.pendingCallback = callback
        
        // Start the activity
        val intent = android.content.Intent(context, ArmsActivity::class.java)
        intent.putExtra("DURATION", seconds * 1000)  // Convertir a milisegundos
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    override fun dispose() {
        Log.d(TAG, "FastNativeApi disposing...")
        asrEngine?.dispose()
        asrEngine = null
        
        faceEngine?.dispose()
        faceEngine = null
        
        Log.d(TAG, "FastNativeApi disposed")
    }
}

