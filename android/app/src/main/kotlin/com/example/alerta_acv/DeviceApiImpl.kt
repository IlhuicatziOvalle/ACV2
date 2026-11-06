package com.example.alerta_acv

import android.content.Intent
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

/**
 * Implementación stub de DeviceApi
 */
class DeviceApiImpl(private val activity: FlutterActivity) : DeviceApi {
    private val TAG = "DeviceApiImpl"

    override fun placeCall911(): Boolean {
        Log.d(TAG, "placeCall911 called")
        return makePhoneCall("911")
    }
    
    fun makePhoneCall(phoneNumber: String): Boolean {
        try {
            val intent = Intent(Intent.ACTION_DIAL).apply {
                data = Uri.parse("tel:$phoneNumber")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            activity.startActivity(intent)
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error calling $phoneNumber", e)
            return false
        }
    }

    override fun sendEmergencySms(message: String, includeLocation: Boolean): Boolean {
        Log.d(TAG, "sendEmergencySms called: message=$message, includeLocation=$includeLocation")
        
        // Stub: por ahora solo loguea, no envía SMS real
        // La implementación real se hará en épicas futuras
        Log.d(TAG, "SMS stub - would send: $message")
        return true
    }
}

