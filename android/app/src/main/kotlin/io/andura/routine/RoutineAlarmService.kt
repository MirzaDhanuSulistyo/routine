package io.andura.routine

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class RoutineAlarmService : Service() {
    private var activeData: RoutineAlarmData? = null
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private val audioFocusListener = AudioManager.OnAudioFocusChangeListener { }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == RoutineAlarmContract.ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        val data = intent?.let(RoutineAlarmData::fromIntent) ?: run {
            stopSelf()
            return START_NOT_STICKY
        }

        stopAlertOutputs()
        activeData?.takeIf { it.notificationId != data.notificationId }?.let {
            NotificationManagerCompat.from(this).cancel(it.notificationId)
        }
        activeData = data
        RoutineAlarmStore.setActive(this, data)
        acquireWakeLock()
        createChannels(this)
        startForeground(data.notificationId, buildNotification(this, data, false))
        broadcastState(this, RoutineAlarmContract.EVENT_TRIGGERED, data.itemId)
        startAlertForPhoneMode()
        return START_REDELIVER_INTENT
    }

    override fun onDestroy() {
        val stopped = activeData ?: RoutineAlarmStore.active(this)
        stopAlertOutputs()
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopped?.let { NotificationManagerCompat.from(this).cancel(it.notificationId) }
        RoutineAlarmStore.clearActive(this, stopped?.itemId)
        broadcastState(this, RoutineAlarmContract.EVENT_STOPPED, stopped?.itemId)
        activeData = null
        super.onDestroy()
    }

    private fun startAlertForPhoneMode() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        when (audioManager.ringerMode) {
            AudioManager.RINGER_MODE_NORMAL -> startRingtone()
            AudioManager.RINGER_MODE_VIBRATE -> startVibration()
            AudioManager.RINGER_MODE_SILENT -> Unit
        }
    }

    private fun startRingtone() {
        val uri = defaultAlarmUri() ?: return
        requestAudioFocus()
        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(alarmAudioAttributes())
                setDataSource(applicationContext, uri)
                isLooping = true
                setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                prepare()
                start()
            }
        } catch (_: Exception) {
            mediaPlayer?.release()
            mediaPlayer = null
            // A visible, vibrating alarm is safer than a silent failure when a
            // manufacturer exposes an unreadable alarm-tone URI.
            startVibration()
        }
    }

    private fun startVibration() {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        val alarmVibrator = vibrator ?: return
        if (!alarmVibrator.hasVibrator()) return
        val pattern = longArrayOf(0, 700, 500)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            alarmVibrator.vibrate(
                VibrationEffect.createWaveform(pattern, 0),
                alarmAudioAttributes(),
            )
        } else {
            @Suppress("DEPRECATION")
            alarmVibrator.vibrate(pattern, 0)
        }
    }

    private fun stopAlertOutputs() {
        try {
            mediaPlayer?.stop()
        } catch (_: IllegalStateException) {
            // The player may not have completed preparation.
        }
        mediaPlayer?.release()
        mediaPlayer = null
        vibrator?.cancel()
        vibrator = null
        abandonAudioFocus()
    }

    private fun requestAudioFocus() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE,
            )
                .setAudioAttributes(alarmAudioAttributes())
                .setOnAudioFocusChangeListener(audioFocusListener)
                .build()
            audioFocusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                audioFocusListener,
                AudioManager.STREAM_ALARM,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
            )
        }
    }

    private fun abandonAudioFocus() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let(audioManager::abandonAudioFocusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(audioFocusListener)
        }
        audioFocusRequest = null
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Routine:ActiveAlarm",
        ).apply {
            setReferenceCounted(false)
            acquire(30 * 60 * 1000L)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.takeIf { it.isHeld }?.release()
        wakeLock = null
    }

    companion object {
        private const val ACTIVE_CHANNEL_ID = "routine_active_alarms_v1"
        private const val FALLBACK_CHANNEL_ID = "routine_alarm_fallback_v1"

        fun startIntent(context: Context, data: RoutineAlarmData): Intent =
            data.putInto(Intent(context, RoutineAlarmService::class.java))

        fun stop(context: Context, itemId: String? = null) {
            val active = RoutineAlarmStore.active(context)
            if (itemId != null && active != null && active.itemId != itemId) return
            val stopped = context.stopService(Intent(context, RoutineAlarmService::class.java))
            if (!stopped) {
                active?.let { NotificationManagerCompat.from(context).cancel(it.notificationId) }
                RoutineAlarmStore.clearActive(context, itemId)
                broadcastState(
                    context,
                    RoutineAlarmContract.EVENT_STOPPED,
                    active?.itemId ?: itemId,
                )
            }
        }

        fun showFallbackNotification(context: Context, data: RoutineAlarmData) {
            createChannels(context)
            try {
                NotificationManagerCompat.from(context).notify(
                    data.notificationId,
                    buildNotification(context, data, true),
                )
                RoutineAlarmStore.setActive(context, data)
                broadcastState(context, RoutineAlarmContract.EVENT_TRIGGERED, data.itemId)
            } catch (_: SecurityException) {
                // Notification permission can be revoked after scheduling.
            }
        }

        private fun buildNotification(
            context: Context,
            data: RoutineAlarmData,
            fallback: Boolean,
        ): Notification {
            val fullScreenIntent = data.putInto(Intent(context, MainActivity::class.java).apply {
                action = RoutineAlarmContract.ACTION_SHOW
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                this.data = Uri.parse("routine://active-alarm/${data.notificationId}")
            })
            val fullScreenPendingIntent = PendingIntent.getActivity(
                context,
                data.notificationId,
                fullScreenIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val snoozeIntent = data.putInto(
                Intent(context, RoutineAlarmActionReceiver::class.java).apply {
                    action = RoutineAlarmContract.ACTION_SNOOZE
                    this.data = Uri.parse("routine://alarm-action/snooze/${data.notificationId}")
                },
            )
            val stopIntent = data.putInto(
                Intent(context, RoutineAlarmActionReceiver::class.java).apply {
                    action = RoutineAlarmContract.ACTION_STOP
                    this.data = Uri.parse("routine://alarm-action/stop/${data.notificationId}")
                },
            )
            val snoozePendingIntent = PendingIntent.getBroadcast(
                context,
                data.notificationId xor 0x13572468,
                snoozeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val stopPendingIntent = PendingIntent.getBroadcast(
                context,
                data.notificationId xor 0x24681357,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            return NotificationCompat.Builder(
                context,
                if (fallback) FALLBACK_CHANNEL_ID else ACTIVE_CHANNEL_ID,
            )
                .setSmallIcon(R.drawable.ic_alarm_notification)
                .setContentTitle(data.title)
                .setContentText(data.body)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .setAutoCancel(false)
                .setContentIntent(fullScreenPendingIntent)
                .setFullScreenIntent(fullScreenPendingIntent, true)
                .addAction(
                    R.drawable.ic_alarm_notification,
                    "Snooze 10m",
                    snoozePendingIntent,
                )
                .addAction(
                    R.drawable.ic_alarm_notification,
                    "Stop",
                    stopPendingIntent,
                )
                .build()
        }

        private fun createChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(NotificationManager::class.java)
            val active = NotificationChannel(
                ACTIVE_CHANNEL_ID,
                "Ringing routine alarms",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Full-screen alarms that are currently ringing"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val fallback = NotificationChannel(
                FALLBACK_CHANNEL_ID,
                "Routine alarm fallback",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Alarm alerts used when continuous ringing cannot start"
                val uri = defaultAlarmUri()
                setSound(uri, alarmAudioAttributes())
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 700, 500)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(active)
            manager.createNotificationChannel(fallback)
        }

        private fun defaultAlarmUri(): Uri? =
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

        private fun alarmAudioAttributes(): AudioAttributes =
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

        private fun broadcastState(context: Context, event: String, itemId: String?) {
            context.sendBroadcast(Intent(RoutineAlarmContract.ACTION_STATE_CHANGED).apply {
                setPackage(context.packageName)
                putExtra(RoutineAlarmContract.EXTRA_EVENT, event)
                putExtra(RoutineAlarmContract.EXTRA_ITEM_ID, itemId)
            })
        }
    }
}

class RoutineAlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val incoming = RoutineAlarmData.fromIntent(intent)
        val active = RoutineAlarmStore.active(context)
        val data = active?.takeIf { incoming == null || it.itemId == incoming.itemId }
            ?: incoming
            ?: return

        when (intent.action) {
            RoutineAlarmContract.ACTION_SNOOZE -> {
                RoutineAlarmScheduler.schedule(
                    context,
                    data.copy(
                        notificationId = data.snoozeNotificationId,
                        triggerAtMillis = System.currentTimeMillis() + 10 * 60 * 1000L,
                        recurrence = "none",
                        body = "Snoozed alarm • 10 minutes",
                    ),
                )
                RoutineAlarmService.stop(context, data.itemId)
            }
            RoutineAlarmContract.ACTION_STOP ->
                RoutineAlarmService.stop(context, data.itemId)
        }
    }
}
