package com.example.alerta_acv

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View

/**
 * Vista overlay para mostrar landmarks de pose (brazos) y estado de detección.
 */
class ArmsOverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    // Paint para líneas del esqueleto
    private val linePaint = Paint().apply {
        color = Color.parseColor("#4CAF50")  // Verde
        style = Paint.Style.STROKE
        strokeWidth = 8f
        isAntiAlias = true
    }

    // Paint para líneas cuando hay caída detectada
    private val lineWarningPaint = Paint().apply {
        color = Color.parseColor("#FF5722")  // Naranja/Rojo
        style = Paint.Style.STROKE
        strokeWidth = 8f
        isAntiAlias = true
    }

    // Paint para puntos de landmarks
    private val pointPaint = Paint().apply {
        color = Color.YELLOW
        style = Paint.Style.FILL
        isAntiAlias = true
    }

    // Paint para puntos de muñecas (más visibles)
    private val wristPaint = Paint().apply {
        color = Color.CYAN
        style = Paint.Style.FILL
        isAntiAlias = true
    }

    // Paint para texto de fondo
    private val textBgPaint = Paint().apply {
        color = Color.parseColor("#80000000")
        style = Paint.Style.FILL
        isAntiAlias = true
    }

    // Paint para texto
    private val textPaint = Paint().apply {
        color = Color.WHITE
        textSize = 42f
        isAntiAlias = true
    }

    // Paint para indicador de deltaY
    private val deltaPaint = Paint().apply {
        color = Color.CYAN
        textSize = 36f
        isAntiAlias = true
    }

    // Landmarks de pose (solo los relevantes para brazos)
    // Formato: List<Pair<x, y>> en coordenadas de view
    private var landmarks: List<Pair<Float, Float>>? = null
    
    // Conexiones para dibujar el esqueleto de brazos
    // Índices de MediaPipe Pose: 
    // 11=left_shoulder, 12=right_shoulder, 13=left_elbow, 14=right_elbow, 15=left_wrist, 16=right_wrist
    private var connections: List<Pair<Int, Int>>? = null

    // Estado de detección
    private var poseDetected: Boolean = false
    private var dropDetected: Boolean = false
    private var currentDeltaY: Double = 0.0
    private var countdownMillis: Long? = null
    private var message: String? = null
    private var lowLight: Boolean = false

    fun update(
        landmarks: List<Pair<Float, Float>>?,
        connections: List<Pair<Int, Int>>?,
        poseDetected: Boolean,
        dropDetected: Boolean,
        deltaY: Double,
        lowLight: Boolean,
        countdownMillis: Long?,
        message: String?
    ) {
        this.landmarks = landmarks
        this.connections = connections
        this.poseDetected = poseDetected
        this.dropDetected = dropDetected
        this.currentDeltaY = deltaY
        this.lowLight = lowLight
        this.countdownMillis = countdownMillis
        this.message = message
        postInvalidateOnAnimation()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val pts = landmarks
        val conns = connections

        // Dibujar conexiones (esqueleto)
        if (pts != null && conns != null && pts.isNotEmpty()) {
            val paint = if (dropDetected) lineWarningPaint else linePaint
            for ((startIdx, endIdx) in conns) {
                if (startIdx < pts.size && endIdx < pts.size) {
                    val (x1, y1) = pts[startIdx]
                    val (x2, y2) = pts[endIdx]
                    canvas.drawLine(x1, y1, x2, y2, paint)
                }
            }
        }

        // Dibujar landmarks
        pts?.forEachIndexed { index, (x, y) ->
            // Muñecas más grandes (índices 15=left_wrist, 16=right_wrist en MediaPipe Pose)
            // También destacar hombros (11, 12) y codos (13, 14)
            val isWrist = index == 15 || index == 16
            val isArmJoint = index in listOf(11, 12, 13, 14, 15, 16)
            val paint = if (isWrist) wristPaint else pointPaint
            val radius = when {
                isWrist -> 16f
                isArmJoint -> 12f
                else -> 8f
            }
            canvas.drawCircle(x, y, radius, paint)
        }

        // Indicador de deltaY en la parte superior
        if (poseDetected) {
            val deltaText = String.format("ΔY: %.2f", currentDeltaY)
            val deltaColor = when {
                currentDeltaY >= 0.20 -> Color.RED
                currentDeltaY >= 0.10 -> Color.YELLOW
                else -> Color.GREEN
            }
            deltaPaint.color = deltaColor
            canvas.drawText(deltaText, 20f, 80f, deltaPaint)
            
            if (dropDetected) {
                deltaPaint.color = Color.RED
                canvas.drawText("⚠ CAÍDA DETECTADA", 20f, 130f, deltaPaint)
            }
        }

        // Barra de información en la parte inferior
        val infoLines = mutableListOf<String>()
        if (lowLight) infoLines.add("⚠ Luz baja")
        countdownMillis?.let {
            val s = (it / 1000).toInt()
            val ds = ((it % 1000) / 100).toInt()
            infoLines.add("Tiempo: ${s}.${ds}s")
        }
        message?.let { if (it.isNotBlank()) infoLines.add(it) }

        if (infoLines.isNotEmpty()) {
            val padding = 24f
            val lineHeight = textPaint.textSize + 10f
            val blockHeight = padding * 2 + lineHeight * infoLines.size
            val bgTop = height - blockHeight
            canvas.drawRect(0f, bgTop, width.toFloat(), height.toFloat(), textBgPaint)
            infoLines.forEachIndexed { i, line ->
                canvas.drawText(line, padding, bgTop + padding + lineHeight * (i + 1) - 10f, textPaint)
            }
        }
    }
}
