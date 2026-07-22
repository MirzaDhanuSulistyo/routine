import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/routine_repository.dart';
import '../domain/routine_item.dart';

const _doneAction = 'routine_done';
const _snoozeAction = 'routine_snooze';
const _addNoteAction = 'routine_add_note';
const _category = 'routine_reminder';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(ReminderNotificationService.handleResponse(response));
}

class ReminderSchedule {
  final DateTime dateTime;
  final DateTimeComponents? recurrenceComponents;

  const ReminderSchedule({
    required this.dateTime,
    required this.recurrenceComponents,
  });
}

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  static final StreamController<NotificationResponse> _responseController =
      StreamController<NotificationResponse>.broadcast();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Stream<NotificationResponse> get responses => _responseController.stream;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // The timezone plugin is unavailable in unit tests. tz.local remains usable.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _category,
          actions: [
            DarwinNotificationAction.plain(_doneAction, 'Done'),
            DarwinNotificationAction.plain(_snoozeAction, 'Snooze 10m'),
            DarwinNotificationAction.plain(
              _addNoteAction,
              'Add Note',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );

    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: (response) {
          unawaited(handleResponse(response));
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _initialized = true;
    } catch (error) {
      debugPrint('Notification initialization unavailable: $error');
    }
  }

  Future<bool> requestPermissions() async {
    await initialize();
    if (kIsWeb) return false;

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          final notifications =
              await android?.requestNotificationsPermission() ?? true;
          final exactAlarms =
              await android?.requestExactAlarmsPermission() ?? true;
          return notifications && exactAlarms;
        case TargetPlatform.iOS:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin
                  >()
                  ?.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
        case TargetPlatform.macOS:
          return await _plugin
                  .resolvePlatformSpecificImplementation<
                    MacOSFlutterLocalNotificationsPlugin
                  >()
                  ?.requestPermissions(alert: true, badge: true, sound: true) ??
              false;
        default:
          return true;
      }
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
      return false;
    }
  }

  Future<void> schedule(RoutineItem item, {DateTime? now}) async {
    if (!item.notificationsEnabled || item.isCompleted) {
      await cancel(item.id);
      return;
    }

    final schedule = scheduleFor(item, now: now);
    if (schedule == null) {
      await cancel(item.id);
      return;
    }

    await initialize();
    if (!_initialized || kIsWeb) return;

    final scheduledDate = tz.TZDateTime.from(schedule.dateTime, tz.local);
    final notificationDetails = _notificationDetails();
    final id = notificationIdFor(item.id);

    await _plugin.cancel(id: id);
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: item.title,
        body: _notificationBody(item),
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        payload: item.id,
        matchDateTimeComponents: schedule.recurrenceComponents,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (error) {
      debugPrint(
        'Exact reminder scheduling failed, using inexact mode: $error',
      );
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: item.title,
          body: _notificationBody(item),
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          payload: item.id,
          matchDateTimeComponents: schedule.recurrenceComponents,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (fallbackError) {
        debugPrint('Reminder scheduling failed: $fallbackError');
      }
    }
  }

  Future<void> rescheduleAll(List<RoutineItem> items) async {
    await initialize();
    for (final item in items.where((item) => item.notificationsEnabled)) {
      await schedule(item);
    }
  }

  Future<void> cancel(String itemId) async {
    if (!_initialized) await initialize();
    if (!_initialized || kIsWeb) return;
    try {
      await _plugin.cancel(id: notificationIdFor(itemId));
    } catch (error) {
      debugPrint('Reminder cancellation failed: $error');
    }
  }

  Future<int> pendingCount() async {
    await initialize();
    if (!_initialized || kIsWeb) return 0;
    try {
      return (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {
      return 0;
    }
  }

  static ReminderSchedule? scheduleFor(RoutineItem item, {DateTime? now}) {
    if (item.scheduledDate == null) return null;
    final date = DateTime.tryParse(item.scheduledDate!);
    final time = _parseTime(item.scheduledTime);
    if (date == null || time == null) return null;

    final current = now ?? DateTime.now();
    var scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.$1,
      time.$2,
    ).subtract(Duration(minutes: item.prepOffsetMinutes ?? 0));

    DateTimeComponents? components;
    switch (item.recurrenceRule) {
      case 'daily':
        while (!scheduled.isAfter(current)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        components = DateTimeComponents.time;
      case 'weekly':
        while (!scheduled.isAfter(current)) {
          scheduled = scheduled.add(const Duration(days: 7));
        }
        components = DateTimeComponents.dayOfWeekAndTime;
      default:
        if (!scheduled.isAfter(current)) return null;
    }

    return ReminderSchedule(
      dateTime: scheduled,
      recurrenceComponents: components,
    );
  }

  static int notificationIdFor(String itemId) {
    var hash = 0x811c9dc5;
    for (final unit in itemId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static Future<void> handleResponse(NotificationResponse response) async {
    final itemId = response.payload;
    if (itemId == null || itemId.isEmpty) return;

    final repository = RoutineRepository();
    switch (response.actionId) {
      case _doneAction:
        final item = await repository.getItemById(itemId);
        if (item == null) return;
        if (item.recurrenceRule == 'none') {
          await repository.updateItemCompletion(itemId, true);
        } else {
          final now = DateTime.now();
          final occurrenceDate = occurrenceDateForAction(item, now: now);
          await repository.setOccurrenceCompletion(
            itemId: itemId,
            occurrenceDate: occurrenceDate,
            isCompleted: true,
            eventTime: now,
          );
        }
        if (!_responseController.isClosed) _responseController.add(response);
        break;
      case _snoozeAction:
        final item = await repository.getItemById(itemId);
        if (item != null) await instance._scheduleSnooze(item);
        break;
      case _addNoteAction:
      default:
        if (!_responseController.isClosed) _responseController.add(response);
    }
  }

  Future<void> _scheduleSnooze(RoutineItem item) async {
    await initialize();
    if (!_initialized || kIsWeb) return;
    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 10));
    await _plugin.zonedSchedule(
      id: notificationIdFor(item.id),
      title: item.title,
      body: 'Snoozed reminder',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      payload: item.id,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static String occurrenceDateForAction(RoutineItem item, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (item.recurrenceRule == 'none') {
      return item.scheduledDate ?? _dateKey(current);
    }

    final start = DateTime.tryParse(item.scheduledDate ?? '');
    final time = _parseTime(item.scheduledTime);
    if (start == null || time == null) return _dateKey(current);

    DateTime? closestOccurrence;
    Duration? closestDistance;
    for (var offset = -8; offset <= 8; offset++) {
      final day = DateTime(current.year, current.month, current.day + offset);
      final difference = day
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
      if (difference < 0) continue;
      final occurs =
          item.recurrenceRule == 'daily' ||
          (item.recurrenceRule == 'weekly' && difference % 7 == 0);
      if (!occurs) continue;

      final occurrence = DateTime(
        day.year,
        day.month,
        day.day,
        time.$1,
        time.$2,
      );
      final trigger = occurrence.subtract(
        Duration(minutes: item.prepOffsetMinutes ?? 0),
      );
      final distance = trigger.difference(current).abs();
      if (closestDistance == null || distance < closestDistance) {
        closestDistance = distance;
        closestOccurrence = occurrence;
      }
    }
    return _dateKey(closestOccurrence ?? current);
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static (int, int)? _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 12 || minute > 59) return null;
    if (hour == 12) hour = 0;
    if (match.group(3)!.toUpperCase() == 'PM') hour += 12;
    return (hour, minute);
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'routine_reminders',
        'Routine reminders',
        channelDescription: 'Scheduled routine items and preparation alerts',
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          AndroidNotificationAction(_doneAction, 'Done'),
          AndroidNotificationAction(
            _snoozeAction,
            'Snooze 10m',
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            _addNoteAction,
            'Add Note',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: _category),
      macOS: DarwinNotificationDetails(categoryIdentifier: _category),
    );
  }

  String _notificationBody(RoutineItem item) {
    if (item.prepOffsetMinutes != null && item.prepOffsetMinutes! > 0) {
      return '${item.prepOffsetMinutes} minutes of preparation time starts now.';
    }
    return 'Scheduled for ${item.scheduledTime} • ${item.category}';
  }
}
