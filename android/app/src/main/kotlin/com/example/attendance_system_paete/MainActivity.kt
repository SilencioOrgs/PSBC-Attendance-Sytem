package com.example.attendance_system_paete

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Build

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "classattend/background_attendance")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val uuid = call.argument<String>("serviceUuid")
                        if (uuid.isNullOrBlank()) {
                            result.error("invalid_uuid", "A BLE service UUID is required.", null)
                        } else {
                            val intent = Intent(this, BackgroundAttendanceService::class.java)
                                .setAction(BackgroundAttendanceService.ACTION_START)
                                .putExtra(BackgroundAttendanceService.EXTRA_UUID, uuid)
                            try {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent)
                                else startService(intent)
                                result.success(null)
                            } catch (error: Exception) {
                                result.error("service_start_failed", error.message, null)
                            }
                        }
                    }
                    "stop" -> {
                        startService(Intent(this, BackgroundAttendanceService::class.java).setAction(BackgroundAttendanceService.ACTION_STOP))
                        result.success(null)
                    }
                    "state" -> result.success(BackgroundAttendanceService.state(this))
                    else -> result.notImplemented()
                }
            }
    }
}
