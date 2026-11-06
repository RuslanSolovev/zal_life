package com.example.zal_life

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.zal_life/boot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAfterBoot" -> {
                        result.success(wasRebootedSinceLastRun())
                    }
                    "markBootChecked" -> {
                        saveCurrentBootTime()
                        result.success(true)
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("BATTERY", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Проверяем, был ли ребут с последнего запуска приложения.
     * Логика: если текущее время загрузки системы больше, чем
     * сохранённое ранее — значит, телефон перезагружался.
     */
    private fun wasRebootedSinceLastRun(): Boolean {
        val prefs = getSharedPreferences("boot_prefs", Context.MODE_PRIVATE)
        val previousBoot = prefs.getLong("last_boot", 0L)
        val currentBoot = currentBootTime()
        // Если разница > 10 сек — был ребут (защита от погрешности)
        return previousBoot > 0 && (currentBoot - previousBoot) > 10_000L
    }

    private fun saveCurrentBootTime() {
        val prefs = getSharedPreferences("boot_prefs", Context.MODE_PRIVATE)
        prefs.edit().putLong("last_boot", currentBootTime()).apply()
    }

    private fun currentBootTime(): Long {
        // Время загрузки системы = текущее время - uptime
        return System.currentTimeMillis() - SystemClock.elapsedRealtime()
    }
}