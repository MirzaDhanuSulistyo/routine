package io.andura.routine

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.ContextCompat
import java.time.Instant
import java.time.ZoneId

object RoutineAlarmScheduler {
    private const val MISSED_ALARM_GRACE_MILLIS = 10 * 60 * 1000L

    fun schedule(context: Context, data: RoutineAlarmData) {
        val safeData = data.copy(
            notificationId = data.notificationId.coerceAtLeast(1),
            triggerAtMillis = data.triggerAtMillis.coerceAtLeast(
                System.currentTimeMillis() + 250,
            ),
        )
        cancelPendingIntent(context, safeData.notificationId)
        RoutineAlarmStore.saveScheduled(context, safeData)
        arm(context, safeData)
    }

    fun cancel(context: Context, notificationId: Int) {
        cancelPendingIntent(context, notificationId)
        RoutineAlarmStore.removeScheduled(context, notificationId)
    }

    fun pendingCount(context: Context): Int =
        RoutineAlarmStore.allScheduled(context).size

    /** Returns the alarm that should ring and prepares its next recurrence. */
    fun consume(context: Context, intent: Intent): RoutineAlarmData? {
        val incoming = RoutineAlarmData.fromIntent(intent) ?: return null
        val stored = RoutineAlarmStore.scheduled(context, incoming.notificationId)
            ?: return null
        if (stored.itemId != incoming.itemId) return null

        if (stored.recurrence == "daily" || stored.recurrence == "weekly") {
            val next = nextOccurrence(stored)
            schedule(context, next)
        } else {
            RoutineAlarmStore.removeScheduled(context, stored.notificationId)
        }
        return stored
    }

    fun restoreAfterBoot(context: Context) {
        // A foreground service cannot survive a reboot. Do not let its old
        // persisted state reopen a phantom full-screen alarm.
        RoutineAlarmStore.clearActive(context)
        val now = System.currentTimeMillis()
        RoutineAlarmStore.allScheduled(context).forEach { stored ->
            when {
                stored.triggerAtMillis > now -> arm(context, stored)
                stored.recurrence == "daily" || stored.recurrence == "weekly" -> {
                    schedule(context, nextOccurrence(stored, now))
                }
                now - stored.triggerAtMillis <= MISSED_ALARM_GRACE_MILLIS -> {
                    schedule(context, stored.copy(triggerAtMillis = now + 1_000))
                }
                else -> RoutineAlarmStore.removeScheduled(
                    context,
                    stored.notificationId,
                )
            }
        }
    }

    private fun nextOccurrence(
        data: RoutineAlarmData,
        nowMillis: Long = System.currentTimeMillis(),
    ): RoutineAlarmData {
        val days = if (data.recurrence == "weekly") 7L else 1L
        val zone = ZoneId.systemDefault()
        var next = Instant.ofEpochMilli(data.triggerAtMillis).atZone(zone).plusDays(days)
        val now = Instant.ofEpochMilli(nowMillis)
        while (!next.toInstant().isAfter(now)) {
            next = next.plusDays(days)
        }
        return data.copy(triggerAtMillis = next.toInstant().toEpochMilli())
    }

    private fun arm(context: Context, data: RoutineAlarmData) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val operation = alarmPendingIntent(context, data)
        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                    manager.canScheduleExactAlarms() -> manager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        data.triggerAtMillis,
                        operation,
                    )
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    data.triggerAtMillis,
                    operation,
                )
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                    manager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        data.triggerAtMillis,
                        operation,
                    )
                else -> manager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    data.triggerAtMillis,
                    operation,
                )
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    data.triggerAtMillis,
                    operation,
                )
            } else {
                manager.set(AlarmManager.RTC_WAKEUP, data.triggerAtMillis, operation)
            }
        }
    }

    private fun alarmPendingIntent(context: Context, data: RoutineAlarmData): PendingIntent {
        val intent = Intent(context, RoutineAlarmReceiver::class.java).apply {
            action = RoutineAlarmContract.ACTION_FIRE
            this.data = Uri.parse("routine://scheduled-alarm/${data.notificationId}")
        }
        data.putInto(intent)
        return PendingIntent.getBroadcast(
            context,
            data.notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun cancelPendingIntent(context: Context, notificationId: Int) {
        val intent = Intent(context, RoutineAlarmReceiver::class.java).apply {
            action = RoutineAlarmContract.ACTION_FIRE
            data = Uri.parse("routine://scheduled-alarm/$notificationId")
        }
        val operation = PendingIntent.getBroadcast(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        ) ?: return
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(operation)
        operation.cancel()
    }
}

class RoutineAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != RoutineAlarmContract.ACTION_FIRE) return
        val data = RoutineAlarmScheduler.consume(context, intent) ?: return
        try {
            ContextCompat.startForegroundService(
                context,
                RoutineAlarmService.startIntent(context, data),
            )
        } catch (_: Exception) {
            RoutineAlarmService.showFallbackNotification(context, data)
        }
    }
}

class RoutineAlarmBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" ->
                RoutineAlarmScheduler.restoreAfterBoot(context)
        }
    }
}
