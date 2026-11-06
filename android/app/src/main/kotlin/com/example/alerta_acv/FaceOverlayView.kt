package com.example.alerta_acv

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View

class FaceOverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private val boxPaint = Paint().apply {
        color = Color.GREEN
        style = Paint.Style.STROKE
        strokeWidth = 6f
        isAntiAlias = true
    }

    private val boxLostPaint = Paint().apply {
        color = Color.RED
        style = Paint.Style.STROKE
        strokeWidth = 6f
        isAntiAlias = true
    }

    private val pointPaint = Paint().apply {
        color = Color.YELLOW
        style = Paint.Style.FILL
        isAntiAlias = true
    }

    private val multiPointPaint = Paint().apply {
        color = Color.YELLOW
        style = Paint.Style.FILL
        isAntiAlias = true
    }

    private val linePaint = Paint().apply {
        color = Color.parseColor("#66AAAAAA")  // Gris semi-transparente
        style = Paint.Style.STROKE
        strokeWidth = 2f
        isAntiAlias = true
    }

    private val textBgPaint = Paint().apply {
        color = Color.parseColor("#80000000")
        style = Paint.Style.FILL
        isAntiAlias = true
    }

    private val textPaint = Paint().apply {
        color = Color.WHITE
        textSize = 42f
        isAntiAlias = true
    }

    private val infoPaint = Paint().apply {
        color = Color.CYAN
        textSize = 36f
        isAntiAlias = true
    }

    private var faceRect: RectF? = null
    private var nosePoint: Pair<Float, Float>? = null
    private var leftMouthPoint: Pair<Float, Float>? = null
    private var rightMouthPoint: Pair<Float, Float>? = null
    private var hasFace: Boolean = false
    private var lowLight: Boolean = false
    private var countdownMillis: Long? = null
    private var message: String? = null
    private var landmarkPoints: List<Pair<Float, Float>>? = null
    private var connectorPairs: List<Pair<Int, Int>>? = null

    fun update(
        rect: RectF?,
        nose: Pair<Float, Float>?,
        leftMouth: Pair<Float, Float>?,
        rightMouth: Pair<Float, Float>?,
        hasFace: Boolean,
        lowLight: Boolean,
        countdownMillis: Long?,
        message: String?,
        landmarks: List<Pair<Float, Float>>? = null,
        connectors: List<Pair<Int, Int>>? = null
    ) {
        this.faceRect = rect
        this.nosePoint = nose
        this.leftMouthPoint = leftMouth
        this.rightMouthPoint = rightMouth
        this.hasFace = hasFace
        this.lowLight = lowLight
        this.countdownMillis = countdownMillis
        this.message = message
        this.landmarkPoints = landmarks
        this.connectorPairs = connectors
        postInvalidateOnAnimation()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        val rect = faceRect
        if (rect != null) {
            val paint = if (hasFace) boxPaint else boxLostPaint
            canvas.drawRect(rect, paint)
        }

        nosePoint?.let { (x, y) ->
            canvas.drawCircle(x, y, 8f, pointPaint)
        }
        leftMouthPoint?.let { (x, y) ->
            canvas.drawCircle(x, y, 8f, pointPaint)
        }
        rightMouthPoint?.let { (x, y) ->
            canvas.drawCircle(x, y, 8f, pointPaint)
        }

        // Dibujar conectores primero (detrás de los puntos)
        val pts = landmarkPoints
        val conns = connectorPairs
        if (pts != null && conns != null && pts.isNotEmpty()) {
            for ((startIdx, endIdx) in conns) {
                if (startIdx < pts.size && endIdx < pts.size) {
                    val (x1, y1) = pts[startIdx]
                    val (x2, y2) = pts[endIdx]
                    canvas.drawLine(x1, y1, x2, y2, linePaint)
                }
            }
        }
        
        // Dibujar todos los landmarks (478 puntos)
        pts?.let { points ->
            for ((x, y) in points) {
                canvas.drawCircle(x, y, 3f, multiPointPaint)
            }
        }

        // Bottom message bar
        val infoLines = mutableListOf<String>()
        if (lowLight) infoLines.add("Luz baja")
        countdownMillis?.let {
            val s = (it / 1000).toInt()
            val ds = ((it % 1000) / 100).toInt()
            infoLines.add("Cuenta: ${s}.${ds}s")
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
