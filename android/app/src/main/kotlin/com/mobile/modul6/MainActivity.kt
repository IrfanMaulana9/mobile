package com.mobile.modul6

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mobile.modul6/notification"
    private var initialNotificationData: Map<String, String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        initialNotificationData = getNotificationDataFromIntent(intent)
        if (initialNotificationData != null) {
            android.util.Log.d("MainActivity", "Initial notification data captured: $initialNotificationData")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialNotification" -> {
                    android.util.Log.d("MainActivity", "Flutter requesting initial notification")
                    result.success(initialNotificationData)
                    initialNotificationData = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        val notificationData = getNotificationDataFromIntent(intent)
        if (notificationData != null) {
            android.util.Log.d("MainActivity", "New intent notification data: $notificationData")
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod("onNotificationTapped", notificationData)
            }
        }
    }

    private fun getNotificationDataFromIntent(intent: Intent?): Map<String, String>? {
        if (intent == null) {
            android.util.Log.d("MainActivity", "Intent is null")
            return null
        }
        
        val extras = intent.extras
        if (extras == null) {
            android.util.Log.d("MainActivity", "Intent extras is null")
            return null
        }
        
        val data = mutableMapOf<String, String>()
        
        for (key in extras.keySet()) {
            val value = extras.get(key)
            if (value != null) {
                data[key] = value.toString()
                android.util.Log.d("MainActivity", "Extracted: $key = $value")
            }
        }
        
        val filteredData = data.filter { (key, _) ->
            !key.startsWith("google.") && 
            !key.startsWith("gcm.") &&
            !key.startsWith("from") &&
            key != "collapse_key"
        }
        
        return if (filteredData.isNotEmpty()) {
            android.util.Log.d("MainActivity", "Returning filtered data: $filteredData")
            filteredData
        } else {
            android.util.Log.d("MainActivity", "No custom data found")
            null
        }
    }
}
