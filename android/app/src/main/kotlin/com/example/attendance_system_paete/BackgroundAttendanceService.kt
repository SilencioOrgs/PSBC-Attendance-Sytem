package com.example.attendance_system_paete

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.os.ParcelUuid
import java.util.UUID

class BackgroundAttendanceService : Service() {
    private var callback: AdvertiseCallback? = null
    private var receiverRegistered = false

    private val bluetoothReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != BluetoothAdapter.ACTION_STATE_CHANGED) return
            when (intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)) {
                BluetoothAdapter.STATE_OFF, BluetoothAdapter.STATE_TURNING_OFF -> setState(false, "Bluetooth is off")
                BluetoothAdapter.STATE_ON -> savedUuid()?.let(::beginAdvertising)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        if (!receiverRegistered) {
            registerReceiver(bluetoothReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
            receiverRegistered = true
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopAdvertising()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                val uuid = intent.getStringExtra(EXTRA_UUID)
                if (uuid.isNullOrBlank()) {
                    setState(false, "A BLE service UUID is required")
                    stopSelf()
                    return START_NOT_STICKY
                }
                getSharedPreferences(PREFERENCES, MODE_PRIVATE).edit().putString(UUID_KEY, uuid).apply()
                startForeground(NOTIFICATION_ID, notification())
                beginAdvertising(uuid)
            }
            else -> {
                val uuid = savedUuid()
                if (uuid == null) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                startForeground(NOTIFICATION_ID, notification())
                beginAdvertising(uuid)
            }
        }
        return START_STICKY
    }

    private fun beginAdvertising(value: String) {
        stopAdvertising()
        val uuid = try { UUID.fromString(value) } catch (_: IllegalArgumentException) {
            setState(false, "The BLE service UUID is invalid")
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            checkSelfPermission(android.Manifest.permission.BLUETOOTH_ADVERTISE) != PackageManager.PERMISSION_GRANTED) {
            setState(false, "Bluetooth advertising permission is required")
            return
        }
        val manager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = manager.adapter
        if (adapter == null || !adapter.isEnabled) {
            setState(false, "Bluetooth is off")
            return
        }
        val advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            setState(false, "BLE advertising is unsupported")
            return
        }
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_POWER)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_LOW)
            .setConnectable(false)
            .build()
        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(uuid))
            .setIncludeDeviceName(false)
            .build()
        callback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                setState(true, null)
            }

            override fun onStartFailure(errorCode: Int) {
                val message = when (errorCode) {
                    ADVERTISE_FAILED_ALREADY_STARTED -> "BLE advertising is already active"
                    ADVERTISE_FAILED_DATA_TOO_LARGE -> "BLE advertisement data is too large"
                    ADVERTISE_FAILED_FEATURE_UNSUPPORTED -> "BLE advertising is unsupported"
                    ADVERTISE_FAILED_INTERNAL_ERROR -> "Android could not start BLE advertising"
                    ADVERTISE_FAILED_TOO_MANY_ADVERTISERS -> "No BLE advertiser is available"
                    else -> "BLE advertising failed ($errorCode)"
                }
                setState(false, message)
            }
        }
        try {
            advertiser.startAdvertising(settings, data, callback)
        } catch (error: SecurityException) {
            setState(false, "Bluetooth advertising permission is required")
        } catch (error: Exception) {
            setState(false, error.message ?: "BLE advertising failed")
        }
    }

    private fun stopAdvertising() {
        val current = callback ?: return
        try {
            val adapter = (getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
            adapter?.bluetoothLeAdvertiser?.stopAdvertising(current)
        } catch (_: Exception) { }
        callback = null
        setState(false, null)
    }

    private fun setState(active: Boolean, error: String?) {
        getSharedPreferences(PREFERENCES, MODE_PRIVATE).edit()
            .putBoolean(ACTIVE_KEY, active)
            .putString(ERROR_KEY, error)
            .apply()
        if (isRunning) {
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .notify(NOTIFICATION_ID, notification())
        }
    }

    private fun savedUuid(): String? = getSharedPreferences(PREFERENCES, MODE_PRIVATE).getString(UUID_KEY, null)

    private fun notification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val prefs = getSharedPreferences(PREFERENCES, MODE_PRIVATE)
        val active = prefs.getBoolean(ACTIVE_KEY, false)
        val error = prefs.getString(ERROR_KEY, null)
        val message = when {
            active -> "Background attendance is active. Your device is available for classroom attendance."
            error != null -> error
            else -> "Background attendance service is starting."
        }
        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("ClassAttend")
            .setContentText(message)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Background attendance", NotificationManager.IMPORTANCE_LOW)
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // The explicit foreground service continues when the Flutter task is removed from recents.
    }

    override fun onDestroy() {
        stopAdvertising()
        if (receiverRegistered) unregisterReceiver(bluetoothReceiver)
        receiverRegistered = false
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        const val ACTION_START = "com.example.attendance_system_paete.START_BACKGROUND_ATTENDANCE"
        const val ACTION_STOP = "com.example.attendance_system_paete.STOP_BACKGROUND_ATTENDANCE"
        const val EXTRA_UUID = "serviceUuid"
        private const val CHANNEL_ID = "classattend_background_attendance"
        private const val NOTIFICATION_ID = 2401
        private const val PREFERENCES = "background_attendance"
        private const val UUID_KEY = "service_uuid"
        private const val ACTIVE_KEY = "active"
        private const val ERROR_KEY = "error"
        @Volatile private var isRunning = false

        fun state(context: Context): Map<String, Any?> {
            val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            val adapter = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter
            val active = isRunning && prefs.getBoolean(ACTIVE_KEY, false)
            val error = prefs.getString(ERROR_KEY, null)
            val status = when {
                error?.contains("permission", ignoreCase = true) == true -> "permissionRequired"
                error?.contains("unsupported", ignoreCase = true) == true -> "unsupported"
                adapter == null || !adapter.isEnabled -> "bluetoothOff"
                active -> "active"
                else -> "inactive"
            }
            return mapOf("status" to status, "error" to error)
        }
    }
}
