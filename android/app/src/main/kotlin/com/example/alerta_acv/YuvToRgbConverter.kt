package com.example.alerta_acv

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.media.Image
import androidx.camera.core.ImageProxy
import java.nio.ByteBuffer

/**
 * Lightweight YUV_420_888 to RGB converter.
 * Based on common CameraX samples; avoids heavy allocations compared to toBitmap().
 */
class YuvToRgbConverter(private val context: Context) {

    fun toBitmap(image: ImageProxy, reuse: Bitmap?): Bitmap {
        val width = image.width
        val height = image.height
        val out = reuse ?: Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        yuv420ToArgb8888(image.image!!, out)
        return out
    }

    private fun yuv420ToArgb8888(image: Image, output: Bitmap) {
        require(image.format == ImageFormat.YUV_420_888) { "Unsupported image format" }

        val yBuffer = image.planes[0].buffer // Y
        val uBuffer = image.planes[1].buffer // U
        val vBuffer = image.planes[2].buffer // V

        val yRowStride = image.planes[0].rowStride
        val yPixelStride = image.planes[0].pixelStride
        val uRowStride = image.planes[1].rowStride
        val uPixelStride = image.planes[1].pixelStride
        val vRowStride = image.planes[2].rowStride
        val vPixelStride = image.planes[2].pixelStride

        val width = image.width
        val height = image.height

        val argb = IntArray(width * height)

        var yp = 0
        for (j in 0 until height) {
            val pY = yRowStride * j
            val pUVRow = uRowStride * (j shr 1)
            val pVRow = vRowStride * (j shr 1)
            for (i in 0 until width) {
                val uvOffset = (i shr 1) * uPixelStride
                val vOffset = (i shr 1) * vPixelStride
                val y = 0xFF and yBuffer.get(pY + i * yPixelStride).toInt()
                val u = 0xFF and uBuffer.get(pUVRow + uvOffset).toInt()
                val v = 0xFF and vBuffer.get(pVRow + vOffset).toInt()

                // YUV to RGB conversion
                val y2 = y - 16
                val u2 = u - 128
                val v2 = v - 128
                var r = (1192 * y2 + 1634 * v2)
                var g = (1192 * y2 - 833 * v2 - 400 * u2)
                var b = (1192 * y2 + 2066 * u2)

                r = r.coerceIn(0, 262143)
                g = g.coerceIn(0, 262143)
                b = b.coerceIn(0, 262143)

                argb[yp++] = (-0x1000000
                        or ((r shr 10) shl 16)
                        or ((g shr 10) shl 8)
                        or (b shr 10))
            }
        }

        output.setPixels(argb, 0, width, 0, 0, width, height)
    }
}
