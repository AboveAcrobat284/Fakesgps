package com.example.fakesgps

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fakesgps/detect"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isMockLocation") {
                val isMock = isMockLocationEnabled()
                result.success(isMock)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isMockLocationEnabled(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            try {
                val locationManager = getSystemService(LOCATION_SERVICE) as android.location.LocationManager
                val providers = locationManager.getProviders(true)
                for (provider in providers) {
                    val location = locationManager.getLastKnownLocation(provider)
                    if (location != null && location.isFromMockProvider) {
                        return true
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            false
        } else {
            android.provider.Settings.Secure.getString(contentResolver, "mock_location") != "0"
        }
    }
}
