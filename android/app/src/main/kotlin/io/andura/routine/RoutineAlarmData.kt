package io.andura.routine

import android.content.Context
import android.content.Intent
import org.json.JSONObject

data class RoutineAlarmData(
    val notificationId: Int,
    val snoozeNotificationId: Int,
    val itemId: String,
    val title: String,
    val body: String,
    val triggerAtMillis: Long,
    val recurrence: String,
) {
    fun putInto(intent: Intent): Intent = intent.apply {
        putExtra(RoutineAlarmContract.EXTRA_NOTIFICATION_ID, notificationId)
        putExtra(RoutineAlarmContract.EXTRA_SNOOZE_NOTIFICATION_ID, snoozeNotificationId)
        putExtra(RoutineAlarmContract.EXTRA_ITEM_ID, itemId)
        putExtra(RoutineAlarmContract.EXTRA_TITLE, title)
        putExtra(RoutineAlarmContract.EXTRA_BODY, body)
        putExtra(RoutineAlarmContract.EXTRA_TRIGGER_AT, triggerAtMillis)
        putExtra(RoutineAlarmContract.EXTRA_RECURRENCE, recurrence)
    }

    fun toMap(): Map<String, Any> = mapOf(
        "notificationId" to notificationId,
        "snoozeNotificationId" to snoozeNotificationId,
        "itemId" to itemId,
        "title" to title,
        "body" to body,
        "triggerAtMillis" to triggerAtMillis,
        "recurrence" to recurrence,
    )

    fun toJson(): String = JSONObject().apply {
        put("notificationId", notificationId)
        put("snoozeNotificationId", snoozeNotificationId)
        put("itemId", itemId)
        put("title", title)
        put("body", body)
        put("triggerAtMillis", triggerAtMillis)
        put("recurrence", recurrence)
    }.toString()

    companion object {
        fun fromIntent(intent: Intent): RoutineAlarmData? {
            val itemId = intent.getStringExtra(RoutineAlarmContract.EXTRA_ITEM_ID)
                ?.takeIf { it.isNotBlank() } ?: return null
            return RoutineAlarmData(
                notificationId = intent.getIntExtra(
                    RoutineAlarmContract.EXTRA_NOTIFICATION_ID,
                    1,
                ).coerceAtLeast(1),
                snoozeNotificationId = intent.getIntExtra(
                    RoutineAlarmContract.EXTRA_SNOOZE_NOTIFICATION_ID,
                    2,
                ).coerceAtLeast(1),
                itemId = itemId,
                title = intent.getStringExtra(RoutineAlarmContract.EXTRA_TITLE)
                    ?: "Routine alarm",
                body = intent.getStringExtra(RoutineAlarmContract.EXTRA_BODY).orEmpty(),
                triggerAtMillis = intent.getLongExtra(
                    RoutineAlarmContract.EXTRA_TRIGGER_AT,
                    System.currentTimeMillis(),
                ),
                recurrence = intent.getStringExtra(RoutineAlarmContract.EXTRA_RECURRENCE)
                    ?: "none",
            )
        }

        fun fromMap(arguments: Map<*, *>): RoutineAlarmData {
            fun number(key: String): Number = arguments[key] as? Number
                ?: throw IllegalArgumentException("Missing alarm argument: $key")
            fun text(key: String): String = arguments[key] as? String
                ?: throw IllegalArgumentException("Missing alarm argument: $key")

            return RoutineAlarmData(
                notificationId = number("notificationId").toInt().coerceAtLeast(1),
                snoozeNotificationId = number("snoozeNotificationId").toInt()
                    .coerceAtLeast(1),
                itemId = text("itemId"),
                title = text("title"),
                body = (arguments["body"] as? String).orEmpty(),
                triggerAtMillis = number("triggerAtMillis").toLong(),
                recurrence = (arguments["recurrence"] as? String) ?: "none",
            )
        }

        fun fromJson(value: String): RoutineAlarmData? = try {
            val json = JSONObject(value)
            RoutineAlarmData(
                notificationId = json.getInt("notificationId").coerceAtLeast(1),
                snoozeNotificationId = json.getInt("snoozeNotificationId")
                    .coerceAtLeast(1),
                itemId = json.getString("itemId"),
                title = json.optString("title", "Routine alarm"),
                body = json.optString("body", ""),
                triggerAtMillis = json.getLong("triggerAtMillis"),
                recurrence = json.optString("recurrence", "none"),
            )
        } catch (_: Exception) {
            null
        }
    }
}

object RoutineAlarmContract {
    const val CHANNEL = "io.andura.routine/alarm"

    const val ACTION_FIRE = "io.andura.routine.action.FIRE_ALARM"
    const val ACTION_SHOW = "io.andura.routine.action.SHOW_ALARM"
    const val ACTION_STOP = "io.andura.routine.action.STOP_ALARM"
    const val ACTION_SNOOZE = "io.andura.routine.action.SNOOZE_ALARM"
    const val ACTION_STATE_CHANGED = "io.andura.routine.action.ALARM_STATE_CHANGED"

    const val EXTRA_NOTIFICATION_ID = "routine_notification_id"
    const val EXTRA_SNOOZE_NOTIFICATION_ID = "routine_snooze_notification_id"
    const val EXTRA_ITEM_ID = "routine_alarm_item_id"
    const val EXTRA_TITLE = "routine_alarm_title"
    const val EXTRA_BODY = "routine_alarm_body"
    const val EXTRA_TRIGGER_AT = "routine_alarm_trigger_at"
    const val EXTRA_RECURRENCE = "routine_alarm_recurrence"
    const val EXTRA_EVENT = "routine_alarm_event"

    const val EVENT_TRIGGERED = "triggered"
    const val EVENT_STOPPED = "stopped"
}

object RoutineAlarmStore {
    private const val PREFERENCES = "routine_native_alarms"
    private const val ALARM_PREFIX = "scheduled_alarm_"
    private const val ACTIVE_ALARM = "active_alarm"
    private const val ACTIVE_ALARM_MAX_AGE_MILLIS = 30 * 60 * 1000L

    @Synchronized
    fun saveScheduled(context: Context, data: RoutineAlarmData) {
        preferences(context).edit()
            .putString(ALARM_PREFIX + data.notificationId, data.toJson())
            .apply()
    }

    @Synchronized
    fun removeScheduled(context: Context, notificationId: Int) {
        preferences(context).edit().remove(ALARM_PREFIX + notificationId).apply()
    }

    @Synchronized
    fun scheduled(context: Context, notificationId: Int): RoutineAlarmData? {
        val value = preferences(context).getString(ALARM_PREFIX + notificationId, null)
            ?: return null
        return RoutineAlarmData.fromJson(value)
    }

    @Synchronized
    fun allScheduled(context: Context): List<RoutineAlarmData> = preferences(context)
        .all
        .filterKeys { it.startsWith(ALARM_PREFIX) }
        .values
        .mapNotNull { value -> (value as? String)?.let(RoutineAlarmData::fromJson) }

    @Synchronized
    fun setActive(context: Context, data: RoutineAlarmData) {
        preferences(context).edit().putString(ACTIVE_ALARM, data.toJson()).commit()
    }

    @Synchronized
    fun active(context: Context): RoutineAlarmData? {
        val value = preferences(context).getString(ACTIVE_ALARM, null) ?: return null
        val data = RoutineAlarmData.fromJson(value) ?: run {
            preferences(context).edit().remove(ACTIVE_ALARM).commit()
            return null
        }
        if (System.currentTimeMillis() - data.triggerAtMillis >
            ACTIVE_ALARM_MAX_AGE_MILLIS
        ) {
            preferences(context).edit().remove(ACTIVE_ALARM).commit()
            return null
        }
        return data
    }

    @Synchronized
    fun clearActive(context: Context, itemId: String? = null) {
        val active = active(context)
        if (itemId == null || active?.itemId == itemId) {
            preferences(context).edit().remove(ACTIVE_ALARM).commit()
        }
    }

    private fun preferences(context: Context) = context.applicationContext
        .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
}
