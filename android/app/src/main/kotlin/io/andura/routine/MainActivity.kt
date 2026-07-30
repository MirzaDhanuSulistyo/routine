package io.andura.routine

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var alarmChannel: MethodChannel? = null
    private var alarmStateReceiverRegistered = false

    private val alarmStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != RoutineAlarmContract.ACTION_STATE_CHANGED) return
            when (intent.getStringExtra(RoutineAlarmContract.EXTRA_EVENT)) {
                RoutineAlarmContract.EVENT_TRIGGERED -> {
                    applyAlarmWindowFlags(intent)
                    RoutineAlarmStore.active(this@MainActivity)?.let {
                        alarmChannel?.invokeMethod("alarmTriggered", it.toMap())
                    }
                }
                RoutineAlarmContract.EVENT_STOPPED -> {
                    clearAlarmWindowFlags()
                    alarmChannel?.invokeMethod(
                        "alarmStopped",
                        mapOf(
                            "itemId" to intent.getStringExtra(
                                RoutineAlarmContract.EXTRA_ITEM_ID,
                            ),
                        ),
                    )
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyAlarmWindowFlags(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        alarmChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RoutineAlarmContract.CHANNEL,
        ).apply {
            setMethodCallHandler { call, result ->
                try {
                    handleAlarmMethod(call, result)
                } catch (error: Exception) {
                    result.error("routine_alarm_error", error.message, null)
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        applyAlarmWindowFlags(intent)
        if (intent.action == RoutineAlarmContract.ACTION_SHOW) {
            val data = RoutineAlarmData.fromIntent(intent)
                ?: RoutineAlarmStore.active(this)
            data?.let { alarmChannel?.invokeMethod("alarmTriggered", it.toMap()) }
        }
    }

    override fun onStart() {
        super.onStart()
        if (!alarmStateReceiverRegistered) {
            val filter = IntentFilter(RoutineAlarmContract.ACTION_STATE_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(alarmStateReceiver, filter, RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(alarmStateReceiver, filter)
            }
            alarmStateReceiverRegistered = true
        }
    }

    override fun onStop() {
        if (alarmStateReceiverRegistered) {
            unregisterReceiver(alarmStateReceiver)
            alarmStateReceiverRegistered = false
        }
        super.onStop()
    }

    private fun handleAlarmMethod(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        when (call.method) {
            "scheduleAlarm" -> {
                val data = RoutineAlarmData.fromMap(
                    arguments ?: emptyMap<Any, Any>(),
                )
                RoutineAlarmScheduler.schedule(this, data)
                result.success(true)
            }
            "cancelScheduledAlarm" -> {
                val notificationId = arguments.number("notificationId").toInt()
                val snoozeNotificationId = arguments.number(
                    "snoozeNotificationId",
                ).toInt()
                val includeSnooze =
                    arguments?.get("includeSnooze") as? Boolean ?: true
                RoutineAlarmScheduler.cancel(this, notificationId)
                if (includeSnooze) {
                    RoutineAlarmScheduler.cancel(this, snoozeNotificationId)
                }
                result.success(true)
            }
            "cancelAlarm" -> {
                val itemId = arguments.text("itemId")
                RoutineAlarmScheduler.cancel(
                    this,
                    arguments.number("notificationId").toInt(),
                )
                RoutineAlarmScheduler.cancel(
                    this,
                    arguments.number("snoozeNotificationId").toInt(),
                )
                RoutineAlarmService.stop(this, itemId)
                clearAlarmWindowFlags()
                result.success(true)
            }
            "snoozeAlarm" -> {
                val data = RoutineAlarmData.fromMap(arguments ?: emptyMap<Any, Any>())
                    .copy(recurrence = "none")
                RoutineAlarmScheduler.schedule(this, data)
                RoutineAlarmService.stop(this, data.itemId)
                clearAlarmWindowFlags()
                result.success(true)
            }
            "stopAlarm" -> {
                RoutineAlarmService.stop(this, arguments.text("itemId"))
                clearAlarmWindowFlags()
                result.success(true)
            }
            "pendingAlarmCount" ->
                result.success(RoutineAlarmScheduler.pendingCount(this))
            "getActiveAlarm" ->
                result.success(RoutineAlarmStore.active(this)?.toMap())
            "isAlarmActive" -> {
                val itemId = arguments.text("itemId")
                result.success(RoutineAlarmStore.active(this)?.itemId == itemId)
            }
            else -> result.notImplemented()
        }
    }

    private fun applyAlarmWindowFlags(sourceIntent: Intent?) {
        if (sourceIntent?.action != RoutineAlarmContract.ACTION_SHOW &&
            RoutineAlarmStore.active(this) == null
        ) {
            clearAlarmWindowFlags()
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun clearAlarmWindowFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        }
        @Suppress("DEPRECATION")
        window.clearFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
        )
    }

    private fun Map<*, *>?.number(key: String): Number = this?.get(key) as? Number
        ?: throw IllegalArgumentException("Missing alarm argument: $key")

    private fun Map<*, *>?.text(key: String): String = this?.get(key) as? String
        ?: throw IllegalArgumentException("Missing alarm argument: $key")
}
