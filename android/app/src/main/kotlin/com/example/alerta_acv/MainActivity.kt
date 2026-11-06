package com.example.alerta_acv

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var deviceApi: DeviceApiImpl
    private val CALL_CHANNEL = "com.example.alerta_acv/call"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        deviceApi = DeviceApiImpl(this)
        
        // Registrar FastNativeApi
        FastNativeApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            FastNativeApiImpl(this)
        )
        
        // Registrar DeviceApi
        DeviceApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            deviceApi
        )
        
        // Canal directo para llamadas (solución MIUI)
        io.flutter.plugin.common.MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "makeCall" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    val success = deviceApi.makePhoneCall(phoneNumber)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }
}
