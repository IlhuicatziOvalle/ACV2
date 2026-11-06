package com.example.alerta_acv

import android.content.Context
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Log
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.StorageService
import java.io.IOException

/**
 * Motor de reconocimiento de voz offline usando Vosk y AudioRecord directo.
 * Esta implementación es síncrona y bloqueante, ideal para ser llamada desde un hilo de trabajo.
 */
class AsrEngine(private val context: Context) {
    private val TAG = "AsrEngine"
    
    private var model: Model? = null
    private var isModelLoading = false
    
    // Configuración de audio requerida por Vosk
    private val SAMPLE_RATE = 16000
    private val BUFFER_SIZE = 4096
    
    // Umbrales FAST
    private val SPEECH_NO_DIFFICULTY = 0.80
    private val SPEECH_MILD_THRESHOLD = 0.60
    
    /**
     * Carga el modelo de forma asíncrona. No bloquea el hilo.
     * Retorna inmediatamente y carga el modelo en background.
     */
    fun init() {
        if (model != null) return
        if (isModelLoading) return
        
        isModelLoading = true
        
        // Cargar el modelo en un hilo separado para no bloquear
        Thread {
            try {
                StorageService.unpack(
                    context,
                    "vosk-model-small-es-0.42",
                    "models",
                    { loadedModel ->
                        model = loadedModel
                        isModelLoading = false
                        Log.d(TAG, "Vosk model loaded")
                    },
                    { exception ->
                        isModelLoading = false
                        Log.e(TAG, "Error loading model", exception)
                    }
                )
            } catch (e: Exception) {
                isModelLoading = false
                Log.e(TAG, "Exception in init thread", e)
            }
        }.start()
    }
    
    /**
     * Espera a que el modelo esté cargado. Bloquea el hilo actual.
     * Usar solo desde un hilo de trabajo, nunca desde el hilo principal.
     */
    fun waitForModel(timeoutSeconds: Int = 30): Boolean {
        if (model != null) return true
        
        val startTime = System.currentTimeMillis()
        val timeoutMillis = timeoutSeconds * 1000L
        
        while (model == null && (System.currentTimeMillis() - startTime) < timeoutMillis) {
            Thread.sleep(100) // Esperar 100ms antes de verificar de nuevo
        }
        
        return model != null
    }
    
    /**
     * Graba audio y reconoce voz.
     * Bloquea el hilo durante 'seconds'.
     * Si el modelo no está cargado, espera hasta que esté listo (máx 30s).
     */
    fun recognize(seconds: Int): Pair<String, Double>? {
        // Si el modelo no está listo, esperar (desde un hilo de trabajo)
        if (model == null) {
            Log.d(TAG, "Model not ready, waiting...")
            val ready = waitForModel(30)
            if (!ready) {
                Log.w(TAG, "Model loading timeout")
                return Pair("", 0.0)
            }
        }
        
        var recorder: AudioRecord? = null
        var recognizer: Recognizer? = null
        
        try {
            recognizer = Recognizer(model, SAMPLE_RATE.toFloat())
            recognizer.setWords(true)
            
            recorder = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                SAMPLE_RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                BUFFER_SIZE * 2
            )
            
            if (recorder.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord init failed")
                return null
            }
            
            val buffer = ByteArray(BUFFER_SIZE)
            val maxSamples = seconds * SAMPLE_RATE * 2 // bytes totales aprox
            var bytesReadTotal = 0
            
            recorder.startRecording()
            Log.d(TAG, "Recording started...")
            
            val startTime = System.currentTimeMillis()
            val maxDuration = seconds * 1000L
            
            while (System.currentTimeMillis() - startTime < maxDuration) {
                val read = recorder.read(buffer, 0, buffer.size)
                if (read > 0) {
                    recognizer.acceptWaveForm(buffer, read)
                    bytesReadTotal += read
                } else {
                    // Error o buffer vacío
                    Thread.sleep(10)
                }
            }
            
            recorder.stop()
            Log.d(TAG, "Recording finished. Processing final result...")
            
            val finalResultJson = recognizer.finalResult
            val text = extractTextFromJson(finalResultJson)
            
            return Pair(text, 0.0)
            
        } catch (e: Exception) {
            Log.e(TAG, "Recognition error", e)
            return null
        } finally {
            recorder?.release()
            recognizer?.close()
        }
    }
    
    private fun extractTextFromJson(json: String): String {
        val textPattern = "\"text\"\\s*:\\s*\"([^\"]*)\"".toRegex()
        val match = textPattern.find(json)
        return match?.groupValues?.get(1)?.trim() ?: ""
    }
    
    fun calculateSimilarity(str1: String, str2: String): Double {
        if (str1.isEmpty() && str2.isEmpty()) return 1.0
        if (str1.isEmpty() || str2.isEmpty()) return 0.0
        val n1 = normalize(str1)
        val n2 = normalize(str2)
        if (n1.isEmpty() && n2.isEmpty()) return 1.0
        if (n1.isEmpty() || n2.isEmpty()) return 0.0
        val dist = levenshtein(n1, n2)
        val maxLen = maxOf(n1.length, n2.length)
        return (1.0 - dist.toDouble() / maxLen).coerceIn(0.0, 1.0)
    }
    
    private fun normalize(text: String): String {
        return text.lowercase()
            .replace("á", "a").replace("é", "e").replace("í", "i")
            .replace("ó", "o").replace("ú", "u").replace("ñ", "n")
            .replace(Regex("[^a-z0-9\\s]"), "")
            .replace(Regex("\\s+"), " ")
            .trim()
    }
    
    private fun levenshtein(s1: String, s2: String): Int {
        val m = s1.length
        val n = s2.length
        val dp = Array(m + 1) { IntArray(n + 1) }
        for (i in 0..m) dp[i][0] = i
        for (j in 0..n) dp[0][j] = j
        for (i in 1..m) {
            for (j in 1..n) {
                dp[i][j] = if (s1[i-1] == s2[j-1]) dp[i-1][j-1] 
                           else minOf(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]) + 1
            }
        }
        return dp[m][n]
    }
    
    fun classifyLevel(similarity: Double): String {
        return when {
            similarity >= SPEECH_NO_DIFFICULTY -> "Sin"
            similarity >= SPEECH_MILD_THRESHOLD -> "Leve"
            else -> "Fuerte"
        }
    }
    
    fun dispose() {
        model?.close()
        model = null
        isModelLoading = false
    }
}
