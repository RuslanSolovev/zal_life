package com.example.zal_life

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED) return

        Log.d(TAG, "BOOT_COMPLETED received")

        // Точное имя сервиса из logcat
        val started = startService(context, "com.example.accurate_step_counter.StepCounterService")
        Log.d(TAG, "Step service started: $started")

        if (!started) {
            launchAppSilently(context)
        }
    }

    private fun startService(context: Context, className: String): Boolean {
        return try {
            val i = Intent().setClassName(context.packageName, className)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(i)
            } else {
                context.startService(i)
            }
            Log.d(TAG, "✅ Started: $className")
            true
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start $className", e)
            false
        }
    }

    private fun launchAppSilently(context: Context) {
        try {
            val i = Intent(context, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP or
                            Intent.FLAG_ACTIVITY_NO_ANIMATION
                )
            }
            context.startActivity(i)
            Log.d(TAG, "Fallback: launched MainActivity")
        } catch (e: Exception) {
            Log.e(TAG, "Fallback failed", e)
        }
    }

    companion object {
        private const val TAG = "BootReceiver"
    }
}