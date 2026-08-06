import 'dart:async';

import 'package:flutter/material.dart';
import 'package:andura_ui/andura_ui.dart';
import 'data/routine_repository.dart';
import 'data/briefing_service.dart';
import 'data/anomaly_engine.dart';
import 'domain/routine_item.dart';
import 'domain/routine_occurrence.dart';
import 'services/reminder_notification_service.dart';

export 'domain/routine_item.dart';

/// Weekday display order from Sunday through Saturday using Dart's
/// `DateTime.weekday` numbering (Monday = 1 ... Sunday = 7).
const List<int> _weekdayOrder = [7, 1, 2, 3, 4, 5, 6];
const Map<int, String> _weekdayShort = {
  7: 'Sun',
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
};
const List<int> _allWeekdays = [1, 2, 3, 4, 5, 6, 7];

void main() {
  runApp(const RoutineApp());
}

class RoutineApp extends StatefulWidget {
  final ValueChanged<List<RoutineItem>>? onItemsLoaded;
  const RoutineApp({super.key, this.onItemsLoaded});

  @override
  State<RoutineApp> createState() => _RoutineAppState();
}

class _RoutineAppState extends State<RoutineApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Routine',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AnduraTheme.forSystem('linear-app', Brightness.light),
      darkTheme: AnduraTheme.forSystem('linear-app', Brightness.dark),
      home: MainNavigationScreen(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
        onItemsLoaded: widget.onItemsLoaded,
        initialIndex: 0,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<List<RoutineItem>>? onItemsLoaded;
  final List<RoutineItem>? initialItems;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    this.onItemsLoaded,
    this.initialItems,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex = widget.initialIndex;
  DateTime _selectedDate = DateTime.now();
  final RoutineRepository _repository = RoutineRepository();
  final BriefingService _briefingService = BriefingService();
  final AnomalyAnalyticsEngine _anomalyEngine = AnomalyAnalyticsEngine();
  final ReminderNotificationService _reminders =
      ReminderNotificationService.instance;

  List<RoutineItem> _items = [];
  Map<String, RoutineOccurrence> _occurrences = {};
  StreamSubscription? _notificationSubscription;
  int _pendingReminderCount = 0;
  bool? _alarmPermissionsGranted;
  bool _isLoading = true;
  String? _pendingAlarmItemId;
  Route<void>? _activeAlarmRoute;
  String? _activeAlarmItemId;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = _reminders.responses.listen((response) {
      if (!mounted) return;
      final actionId = response.actionId ?? '';
      if (actionId == alarmStoppedAction) {
        _dismissAlarmReminder(response.payload);
      } else if (actionId == 'routine_add_note') {
        _showFastLogSheet();
      } else if (actionId.isEmpty && response.payload != null) {
        final item = _items.cast<RoutineItem?>().firstWhere(
          (entry) => entry?.id == response.payload,
          orElse: () => null,
        );
        if (item != null) {
          unawaited(_showAlarmReminder(item));
        } else {
          _pendingAlarmItemId = response.payload;
          unawaited(_loadItems());
        }
      } else {
        _loadItems();
      }
    });
    if (widget.initialItems != null) {
      _items = List<RoutineItem>.from(widget.initialItems!);
      _isLoading = false;
    } else {
      _loadItems();
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      await _repository.seedDataIfEmpty();
      final items = await _repository.getAllItems();
      final occurrences = await _repository.getAllOccurrences();
      if (mounted) {
        setState(() {
          _items = items.isNotEmpty ? items : _repository.getSeedItems();
          _occurrences = {for (final entry in occurrences) entry.key: entry};
        });
        widget.onItemsLoaded?.call(_items);
        debugPrint('LOADED SQLITE ITEMS: ${_items.length}');
        final pendingAlarmId = _pendingAlarmItemId;
        if (pendingAlarmId != null) {
          final pendingItem = _items.cast<RoutineItem?>().firstWhere(
            (entry) => entry?.id == pendingAlarmId,
            orElse: () => null,
          );
          _pendingAlarmItemId = null;
          if (pendingItem != null) unawaited(_showAlarmReminder(pendingItem));
        }
        unawaited(_syncReminders(_items));
      }
    } catch (e) {
      debugPrint('Error loading items from SQLite: $e');
      if (mounted) {
        setState(() {
          _items = _repository.getSeedItems();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncReminders(List<RoutineItem> items) async {
    await _reminders.rescheduleAll(items);
    final pendingCount = await _reminders.pendingCount();
    if (mounted) setState(() => _pendingReminderCount = pendingCount);
    await _refreshAlarmPermissions();
  }

  Future<void> _refreshAlarmPermissions() async {
    final granted = await _reminders.hasPermission();
    if (mounted) setState(() => _alarmPermissionsGranted = granted);
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'work':
        return const Color(0xFF38BDF8);
      case 'family':
        return const Color(0xFFF472B6);
      case 'home':
        return const Color(0xFF34D399);
      case 'finance':
        return const Color(0xFFFBBF24);
      case 'personal':
      default:
        return const Color(0xFFA78BFA);
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  String _recurrenceLabel(RoutineItem item) {
    switch (item.recurrenceRule) {
      case 'daily':
        final days = item.repeatDays;
        if (days == null || days.isEmpty || days.length >= 7) {
          return 'Repeats daily';
        }
        final names = _weekdayOrder
            .where(days.contains)
            .map((day) => _weekdayShort[day])
            .join(', ');
        return 'Repeats on $names';
      case 'weekly':
        return 'Repeats weekly';
      case 'monthly':
        return 'Repeats monthly';
      default:
        return '';
    }
  }

  String _ordinal(int value) {
    final lastDigit = value % 10;
    final lastTwo = value % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${value}th';
    return switch (lastDigit) {
      1 => '${value}st',
      2 => '${value}nd',
      3 => '${value}rd',
      _ => '${value}th',
    };
  }

  String _formatTimestamp(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${_dateKey(parsed)} ${_formatTime(TimeOfDay.fromDateTime(parsed))}';
  }

  List<RoutineItem> get _selectedDateItems {
    final items = _items
        .where((item) => _occursOnDate(item, _selectedDate))
        .toList();
    items.sort(
      (a, b) => _scheduledTimeMinutes(
        a.scheduledTime,
      ).compareTo(_scheduledTimeMinutes(b.scheduledTime)),
    );
    return items;
  }

  bool _occursOnDate(RoutineItem item, DateTime date) =>
      item.occursOnDate(date);

  bool _isCompletedOnDate(RoutineItem item, DateTime date) {
    if (item.recurrenceRule == 'none') return item.isCompleted;
    final key = RoutineOccurrence.keyFor(item.id, _dateKey(date));
    return _occurrences[key]?.isCompleted ?? false;
  }

  Future<void> _setItemCompletion(
    RoutineItem item,
    bool isCompleted, {
    DateTime? occurrenceDate,
  }) async {
    final date = occurrenceDate ?? _selectedDate;
    if (item.recurrenceRule == 'none') {
      setState(() => item.isCompleted = isCompleted);
      await _repository.updateItemCompletion(item.id, isCompleted);
    } else {
      final dateKey = _dateKey(date);
      final now = DateTime.now();
      final eventTime = DateTime(
        date.year,
        date.month,
        date.day,
        now.hour,
        now.minute,
        now.second,
      );
      await _repository.setOccurrenceCompletion(
        itemId: item.id,
        occurrenceDate: dateKey,
        isCompleted: isCompleted,
        eventTime: eventTime,
      );
      if (!mounted) return;
      setState(() {
        final key = RoutineOccurrence.keyFor(item.id, dateKey);
        if (isCompleted) {
          _occurrences[key] = RoutineOccurrence(
            itemId: item.id,
            occurrenceDate: dateKey,
            isCompleted: true,
            eventTimestamp: eventTime.toIso8601String(),
            recordedAtTimestamp: now.toIso8601String(),
          );
        } else {
          _occurrences.remove(key);
        }
      });
    }

    await _reminders.schedule(item);
    final pendingCount = await _reminders.pendingCount();
    if (mounted) setState(() => _pendingReminderCount = pendingCount);
  }

  int _scheduledTimeMinutes(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return 24 * 60;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour == 12) hour = 0;
    if (match.group(3)!.toUpperCase() == 'PM') hour += 12;
    return hour * 60 + minute;
  }

  void _changeDate(int dayOffset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + dayOffset,
      );
    });
  }

  Future<void> _showItemBuilder({RoutineItem? existingItem}) async {
    final titleController = TextEditingController(text: existingItem?.title);
    final notesController = TextEditingController(text: existingItem?.notes);
    final prepController = TextEditingController(
      text: existingItem?.prepOffsetMinutes?.toString(),
    );
    var itemType = existingItem?.itemType ?? 'task';
    var category = existingItem?.category ?? 'personal';
    var recurrenceRule = existingItem?.recurrenceRule ?? 'none';
    var notificationsEnabled = existingItem?.notificationsEnabled ?? false;
    var repeatDays = existingItem?.repeatDays != null
        ? List<int>.from(existingItem!.repeatDays!)
        : List<int>.from(_allWeekdays);
    var date =
        DateTime.tryParse(existingItem?.scheduledDate ?? '') ?? _selectedDate;
    final initialMinutes = existingItem == null
        ? null
        : _scheduledTimeMinutes(existingItem.scheduledTime);
    var time = initialMinutes == null || initialMinutes >= 24 * 60
        ? TimeOfDay.now()
        : TimeOfDay(hour: initialMinutes ~/ 60, minute: initialMinutes % 60);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _TextEditingControllerOwner(
        controllers: [titleController, notesController, prepController],
        child: StatefulBuilder(
          builder: (context, setDialogState) => Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  existingItem == null
                      ? 'Create Routine Item'
                      : 'Edit Routine Item',
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnduraTextField(
                      controller: titleController,
                      labelText: 'Title',
                      hintText: 'What should happen?',
                    ),
                    const SizedBox(height: 12),
                    AnduraSelect<String>(
                      value: itemType,
                      labelText: 'Item type',
                      items: const [
                        DropdownMenuItem(
                          value: 'reminder',
                          child: Text('Reminder'),
                        ),
                        DropdownMenuItem(value: 'task', child: Text('Task')),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child: Text('Maintenance'),
                        ),
                        DropdownMenuItem(
                          value: 'deadline',
                          child: Text('Deadline'),
                        ),
                        DropdownMenuItem(
                          value: 'preparation',
                          child: Text('Preparation'),
                        ),
                        DropdownMenuItem(
                          value: 'briefing',
                          child: Text('Topic Briefing'),
                        ),
                        DropdownMenuItem(
                          value: 'log',
                          child: Text('Log Prompt'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => itemType = value!),
                    ),
                    const SizedBox(height: 12),
                    AnduraSelect<String>(
                      value: category,
                      labelText: 'Category',
                      items: const [
                        DropdownMenuItem(
                          value: 'personal',
                          child: Text('Personal'),
                        ),
                        DropdownMenuItem(value: 'work', child: Text('Work')),
                        DropdownMenuItem(
                          value: 'family',
                          child: Text('Family'),
                        ),
                        DropdownMenuItem(value: 'home', child: Text('Home')),
                        DropdownMenuItem(
                          value: 'finance',
                          child: Text('Finance'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => category = value!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _formatDate(date),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 3650),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );
                              if (selected != null) {
                                setDialogState(() => date = selected);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.schedule, size: 16),
                          label: Text(_formatTime(time)),
                          onPressed: () async {
                            final selected = await showTimePicker(
                              context: context,
                              initialTime: time,
                            );
                            if (selected != null) {
                              setDialogState(() => time = selected);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnduraSelect<String>(
                      value: recurrenceRule,
                      labelText: 'Repeat',
                      items: const [
                        DropdownMenuItem(
                          value: 'none',
                          child: Text('Does not repeat'),
                        ),
                        DropdownMenuItem(
                          value: 'daily',
                          child: Text('Daily (choose days)'),
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Weekly'),
                        ),
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Monthly'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          recurrenceRule = value!;
                          if (recurrenceRule == 'daily' && repeatDays.isEmpty) {
                            repeatDays = List<int>.from(_allWeekdays);
                          }
                        });
                      },
                    ),
                    if (recurrenceRule == 'daily') ...[
                      const SizedBox(height: 12),
                      Text(
                        'Repeat on',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _weekdayOrder.map((day) {
                          final selected = repeatDays.contains(day);
                          return FilterChip(
                            label: Text(_weekdayShort[day]!),
                            selected: selected,
                            onSelected: (value) {
                              setDialogState(() {
                                if (value) {
                                  if (!repeatDays.contains(day)) {
                                    repeatDays.add(day);
                                  }
                                } else if (repeatDays.length > 1) {
                                  repeatDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    if (recurrenceRule == 'monthly') ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Repeats on the ${_ordinal(date.day)} of every '
                          'month at ${_formatTime(time)}.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notify me'),
                      subtitle: const Text(
                        'Full-screen alarm with Stop and Snooze controls',
                      ),
                      value: notificationsEnabled,
                      onChanged: (value) =>
                          setDialogState(() => notificationsEnabled = value),
                    ),
                    if (itemType == 'preparation') ...[
                      const SizedBox(height: 12),
                      AnduraTextField(
                        controller: prepController,
                        keyboardType: TextInputType.number,
                        labelText: 'Lead time in minutes',
                        hintText: '10',
                      ),
                    ],
                    const SizedBox(height: 12),
                    AnduraTextArea(
                      controller: notesController,
                      labelText: 'Notes (optional)',
                      minLines: 2,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      var canNotify = notificationsEnabled;
                      if (canNotify) {
                        canNotify = await _reminders.requestPermissions();
                      }
                      final newItem = RoutineItem(
                        id:
                            existingItem?.id ??
                            DateTime.now().microsecondsSinceEpoch.toString(),
                        title: title,
                        itemType: itemType,
                        category: category,
                        timeOfDay: time.hour < 12
                            ? 'morning'
                            : time.hour < 18
                            ? 'afternoon'
                            : 'evening',
                        scheduledTime: _formatTime(time),
                        scheduledDate: _dateKey(date),
                        recurrenceRule: recurrenceRule,
                        repeatDays:
                            recurrenceRule == 'daily' && repeatDays.length < 7
                            ? List<int>.from(repeatDays)
                            : null,
                        notificationsEnabled: canNotify,
                        eventTimestamp: existingItem?.eventTimestamp,
                        recordedAtTimestamp: existingItem?.recordedAtTimestamp,
                        isCompleted: recurrenceRule == 'none'
                            ? existingItem?.isCompleted ?? false
                            : false,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        prepOffsetMinutes: itemType == 'preparation'
                            ? int.tryParse(prepController.text)
                            : null,
                        topicSources: itemType == 'briefing'
                            ? existingItem?.topicSources ??
                                  ['TechCrunch', 'Bloomberg', 'HackerNews']
                            : null,
                        briefStories: itemType == 'briefing'
                            ? existingItem?.briefStories ?? []
                            : null,
                      );
                      await _repository.insertItem(newItem);
                      await _reminders.schedule(newItem);
                      final pendingCount = await _reminders.pendingCount();
                      if (!mounted) return;
                      setState(() {
                        _pendingReminderCount = pendingCount;
                        final existingIndex = _items.indexWhere(
                          (item) => item.id == newItem.id,
                        );
                        if (existingIndex == -1) {
                          _items.add(newItem);
                        } else {
                          _items[existingIndex] = newItem;
                        }
                        _selectedDate = date;
                      });
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (notificationsEnabled && !canNotify && mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Item created, but alarm permissions were not fully granted.',
                            ),
                          ),
                        );
                      }
                      unawaited(_refreshAlarmPermissions());
                    },
                    child: Text(
                      existingItem == null ? 'Create Item' : 'Save Changes',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _snoozeItem(RoutineItem item) async {
    if (!item.notificationsEnabled || item.isCompleted) return;
    await _reminders.snooze(item);
    final pendingCount = await _reminders.pendingCount();
    if (!mounted) return;
    setState(() => _pendingReminderCount = pendingCount);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder snoozed for 10 minutes.')),
    );
  }

  Future<void> _showAlarmReminder(RoutineItem item) async {
    if (!mounted || _activeAlarmItemId == item.id) return;
    _dismissAlarmReminder();

    late final Route<void> route;
    route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RoutineAlarmScreen(
        item: item,
        onSnooze: () async {
          _dismissAlarmReminder(item.id);
          await _snoozeItem(item);
        },
        onStop: () async {
          _dismissAlarmReminder(item.id);
          await _reminders.stopAlarm(item.id);
          final occurrenceDate = DateTime.tryParse(
            ReminderNotificationService.occurrenceDateForAction(item),
          );
          await _setItemCompletion(
            item,
            true,
            occurrenceDate: occurrenceDate ?? DateTime.now(),
          );
        },
      ),
    );
    _activeAlarmRoute = route;
    _activeAlarmItemId = item.id;
    await Navigator.of(context, rootNavigator: true).push(route);
    if (identical(_activeAlarmRoute, route)) {
      _activeAlarmRoute = null;
      _activeAlarmItemId = null;
    }
  }

  void _dismissAlarmReminder([String? itemId]) {
    final route = _activeAlarmRoute;
    if (route == null || (itemId != null && itemId != _activeAlarmItemId)) {
      return;
    }
    _activeAlarmRoute = null;
    _activeAlarmItemId = null;
    route.navigator?.removeRoute(route);
  }

  Future<void> _showItemActions(RoutineItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isCompletedOnDate(item, _selectedDate))
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Mark Done'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _setItemCompletion(
                      item,
                      true,
                      occurrenceDate: _selectedDate,
                    );
                  },
                ),
              if (item.notificationsEnabled &&
                  !_isCompletedOnDate(item, _selectedDate))
                ListTile(
                  leading: const Icon(Icons.snooze),
                  title: const Text('Snooze 10 minutes'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _snoozeItem(item);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showItemBuilder(existingItem: item);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteItem(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteItem(RoutineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete routine item?'),
        content: Text(
          item.recurrenceRule == 'none'
              ? '“${item.title}” and its stored data will be removed.'
              : '“${item.title}” and all of its completion history will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _reminders.cancel(item.id);
    await _repository.deleteItem(item.id);
    final pendingCount = await _reminders.pendingCount();
    if (!mounted) return;
    setState(() {
      _items.removeWhere((entry) => entry.id == item.id);
      _occurrences.removeWhere((_, occurrence) => occurrence.itemId == item.id);
      _pendingReminderCount = pendingCount;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted “${item.title}”.')));
  }

  void _showFastLogSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String dateMode = 'Today';
        String category = 'personal';
        final noteController = TextEditingController();

        return _TextEditingControllerOwner(
          controllers: [noteController],
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fast Event & Observation Logger',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Target Date (Dual Timestamping)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnduraChoiceRow<String>(
                      values: const ['Today', 'Yesterday', 'Tomorrow'],
                      selected: dateMode,
                      label: (val) => val,
                      onSelected: (val) => setSheetState(() => dateMode = val),
                    ),
                    const SizedBox(height: 16),
                    AnduraTextArea(
                      controller: noteController,
                      labelText: 'What happened or what did you observe?',
                      hintText:
                          'e.g. Car engine hesitated, plant soil was dry...',
                      minLines: 3,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    AnduraSelect<String>(
                      value: category,
                      labelText: 'Category',
                      items: const [
                        DropdownMenuItem(
                          value: 'personal',
                          child: Text('Personal'),
                        ),
                        DropdownMenuItem(value: 'work', child: Text('Work')),
                        DropdownMenuItem(
                          value: 'family',
                          child: Text('Family'),
                        ),
                        DropdownMenuItem(value: 'home', child: Text('Home')),
                        DropdownMenuItem(
                          value: 'finance',
                          child: Text('Finance'),
                        ),
                      ],
                      onChanged: (val) => setSheetState(() => category = val!),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (noteController.text.trim().isNotEmpty) {
                            final now = DateTime.now();
                            final dayOffset = dateMode == 'Yesterday'
                                ? -1
                                : dateMode == 'Tomorrow'
                                ? 1
                                : 0;
                            final eventDate = DateTime(
                              now.year,
                              now.month,
                              now.day + dayOffset,
                              now.hour,
                              now.minute,
                            );
                            final newItem = RoutineItem(
                              id: DateTime.now().microsecondsSinceEpoch
                                  .toString(),
                              title: noteController.text.isNotEmpty
                                  ? noteController.text.split('\n').first
                                  : 'Quick Observation Log',
                              itemType: 'log',
                              category: category,
                              timeOfDay: eventDate.hour < 12
                                  ? 'morning'
                                  : eventDate.hour < 18
                                  ? 'afternoon'
                                  : 'evening',
                              scheduledTime: _formatTime(
                                TimeOfDay.fromDateTime(eventDate),
                              ),
                              scheduledDate: _dateKey(eventDate),
                              isCompleted: true,
                              eventTimestamp: eventDate.toIso8601String(),
                              recordedAtTimestamp: now.toIso8601String(),
                              notes: noteController.text.trim(),
                            );
                            await _repository.insertItem(newItem);
                            if (mounted) {
                              setState(() {
                                _items.add(newItem);
                                _selectedDate = eventDate;
                              });
                            }
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          'Save Log Entry',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showBriefingModal(RoutineItem item) {
    final availableSources = _briefingService.availableSources;
    List<String> selectedSources = List<String>.from(
      item.topicSources ?? ['TechCrunch', 'Bloomberg', 'HackerNews'],
    );
    bool isFetching = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog.fullscreen(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      tooltip: 'Filter Sources',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          builder: (sheetCtx) {
                            return StatefulBuilder(
                              builder: (sheetStateCtx, setSheetState) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Select Briefing Sources',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: availableSources.map((src) {
                                          final isSelected = selectedSources
                                              .contains(src);
                                          return FilterChip(
                                            label: Text(src),
                                            selected: isSelected,
                                            onSelected: (val) {
                                              setSheetState(() {
                                                if (val) {
                                                  selectedSources.add(src);
                                                } else if (selectedSources
                                                        .length >
                                                    1) {
                                                  selectedSources.remove(src);
                                                }
                                              });
                                              setDialogState(() {});
                                            },
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(sheetCtx),
                                          child: const Text(
                                            'Apply Source Selection',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Active Sources:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedSources.map((src) {
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              src,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Curated Stories (${(item.briefStories ?? []).length})',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isFetching)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text(
                                'Refresh Feed',
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                setDialogState(() => isFetching = true);
                                final newStories = await _briefingService
                                    .fetchBriefingStories(
                                      selectedSources: selectedSources,
                                    );
                                final updatedItem = RoutineItem(
                                  id: item.id,
                                  title: item.title,
                                  itemType: item.itemType,
                                  category: item.category,
                                  timeOfDay: item.timeOfDay,
                                  scheduledTime: item.scheduledTime,
                                  scheduledDate: item.scheduledDate,
                                  recurrenceRule: item.recurrenceRule,
                                  notificationsEnabled:
                                      item.notificationsEnabled,
                                  eventTimestamp: item.eventTimestamp,
                                  recordedAtTimestamp: item.recordedAtTimestamp,
                                  isCompleted: item.isCompleted,
                                  notes: item.notes,
                                  prepOffsetMinutes: item.prepOffsetMinutes,
                                  topicSources: selectedSources,
                                  briefStories: newStories
                                      .map((s) => s.toMap())
                                      .toList(),
                                );
                                await _repository.insertItem(updatedItem);
                                if (mounted) {
                                  setState(() {
                                    final idx = _items.indexWhere(
                                      (i) => i.id == item.id,
                                    );
                                    if (idx != -1) _items[idx] = updatedItem;
                                  });
                                }
                                setDialogState(() {
                                  item = updatedItem;
                                  isFetching = false;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...(item.briefStories ?? []).map((story) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      story['source'] ?? '',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (story['category'] != null)
                                    Text(
                                      story['category']!,
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                story['headline'] ?? '',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                story['summary'] ?? '',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                      ),
                      onPressed: () async {
                        await _setItemCompletion(
                          item,
                          true,
                          occurrenceDate: _selectedDate,
                        );
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      },
                      child: const Text(
                        '✓ Mark Briefing Complete',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineSection(
    String title,
    String timeOfDay,
    IconData sectionIcon,
  ) {
    final sectionItems = _selectedDateItems
        .where(
          (i) =>
              i.timeOfDay.toLowerCase().trim() ==
              timeOfDay.toLowerCase().trim(),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(sectionIcon, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        if (sectionItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No items scheduled',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          )
        else
          ...sectionItems.map((item) {
            final isCompleted = _isCompletedOnDate(item, _selectedDate);
            final occurrence = item.recurrenceRule == 'none'
                ? null
                : _occurrences[RoutineOccurrence.keyFor(
                    item.id,
                    _dateKey(_selectedDate),
                  )];
            final eventTimestamp =
                occurrence?.eventTimestamp ?? item.eventTimestamp;
            final recordedAtTimestamp =
                occurrence?.recordedAtTimestamp ?? item.recordedAtTimestamp;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: .5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(item.category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (item.itemType == 'briefing')
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade800,
                            foregroundColor: const Color(0xFF38BDF8),
                            minimumSize: const Size(0, 36),
                          ),
                          onPressed: () => _showBriefingModal(item),
                          child: const Text('Read Brief'),
                        )
                      else
                        IconButton(
                          icon: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isCompleted
                                ? const Color(0xFF34D399)
                                : Colors.grey,
                          ),
                          onPressed: () => _setItemCompletion(
                            item,
                            !isCompleted,
                            occurrenceDate: _selectedDate,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'Item actions',
                        onPressed: () => _showItemActions(item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.scheduledTime,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '• ${item.itemType.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (item.recurrenceRule != 'none' ||
                      item.notificationsEnabled) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (item.recurrenceRule != 'none')
                          AnduraBadge(
                            label: _recurrenceLabel(item),
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                          ),
                        if (item.notificationsEnabled)
                          AnduraBadge(
                            label: 'Reminder enabled',
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiaryContainer,
                          ),
                      ],
                    ),
                  ],
                  if (item.prepOffsetMinutes != null) ...[
                    const SizedBox(height: 6),
                    AnduraBadge(
                      label:
                          'Prep offset: ${item.prepOffsetMinutes}m lead time',
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ],
                  if (item.notes != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: const Border(
                          left: BorderSide(color: Color(0xFF38BDF8), width: 3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_note,
                            size: 14,
                            color: Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Log: ${item.notes}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (eventTimestamp != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: .7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Event: ${_formatTimestamp(eventTimestamp)}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: .7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        if (recordedAtTimestamp != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.save,
                                size: 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: .7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Recorded: ${_formatTimestamp(recordedAtTimestamp)}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: .7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPatternReportView() {
    final report = _anomalyEngine.analyze(_items);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade900.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.primaryAnomalyDescription,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard(
                'Tracked Items',
                '${report.totalEvents}',
                'Active routine logs',
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                'Anomalies',
                '${report.anomaliesDetected}',
                'Timing shifts',
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                'Avg Delay',
                '${report.averageDelayMinutes}m',
                'Schedule variance',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Detected Patterns & Anomalies',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...report.detectedPatterns.map((pat) {
            return _buildAnomalyCard(
              'Timeline Variance Detected',
              pat,
              'Engine Schedule Rule Match',
              Colors.amber,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              val,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(
    String title,
    String desc,
    String evidence,
    Color accentColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Evidence: $evidence',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings & System Status',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appearance Theme',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Switch(
                      value: widget.themeMode == ThemeMode.dark,
                      onChanged: (_) => widget.onToggleTheme(),
                    ),
                  ],
                ),
                Text(
                  'Current Mode: ${widget.themeMode == ThemeMode.dark ? 'Linear Dark' : 'Linear Light'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Native Alarms',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_pendingReminderCount pending alarm${_pendingReminderCount == 1 ? '' : 's'} • full-screen Stop and Snooze',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                if (_alarmPermissionsGranted == true)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Alarm permissions are enabled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_active, size: 16),
                    label: const Text('Enable Alarm Permissions'),
                    onPressed: () async {
                      final granted = await _reminders.requestPermissions();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            granted
                                ? 'Alarm permissions are enabled.'
                                : 'Alarm permissions were not fully granted.',
                          ),
                        ),
                      );
                      await _refreshAlarmPermissions();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local SQLite Database',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Storage File: routine_v4.db (${_items.length} active records)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local-First Architecture',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Version 1.1.0 • Zero Cloud Dependency • 100% On-Device Analytics',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Routine',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.bolt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ],
            ),
            Text(
              'Remember it. Record it. Notice the pattern.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.themeMode == ThemeMode.dark
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            tooltip: 'Create routine item',
            icon: Icon(
              Icons.add_task,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showItemBuilder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedIndex == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        onPressed: () => _changeDate(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            _formatDate(_selectedDate),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 3650),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                            );
                            if (selected != null && mounted) {
                              setState(() => _selectedDate = selected);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next day',
                        onPressed: () => _changeDate(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineSection(
                    'MORNING (05:00 - 12:00)',
                    'morning',
                    Icons.wb_twilight,
                  ),
                  const SizedBox(height: 12),
                  _buildTimelineSection(
                    'AFTERNOON (12:00 - 18:00)',
                    'afternoon',
                    Icons.wb_sunny,
                  ),
                  const SizedBox(height: 12),
                  _buildTimelineSection(
                    'EVENING (18:00 - 24:00)',
                    'evening',
                    Icons.nights_stay,
                  ),
                ],
              ),
            )
          : _selectedIndex == 1
          ? _buildPatternReportView()
          : _buildSettingsView(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              onPressed: _showFastLogSheet,
              icon: const Icon(Icons.flash_on),
              label: const Text('Quick Log'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Pattern Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class RoutineAlarmScreen extends StatefulWidget {
  const RoutineAlarmScreen({
    super.key,
    required this.item,
    required this.onSnooze,
    required this.onStop,
  });

  final RoutineItem item;
  final Future<void> Function() onSnooze;
  final Future<void> Function() onStop;

  @override
  State<RoutineAlarmScreen> createState() => _RoutineAlarmScreenState();
}

class _RoutineAlarmScreenState extends State<RoutineAlarmScreen> {
  late DateTime _now = DateTime.now();
  Timer? _clockTimer;
  bool _handlingAction = false;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _clockTime {
    final period = _now.hour >= 12 ? 'PM' : 'AM';
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    return '$hour:${_now.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_handlingAction) return;
    setState(() => _handlingAction = true);
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            children: [
              Text(
                'ROUTINE ALARM',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
                      blurRadius: 36,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.alarm_rounded,
                  size: 58,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 38),
              Text(
                _clockTime,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w300,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Scheduled for ${widget.item.scheduledTime}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                'Always vibrates • sound follows your phone setting',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handlingAction
                          ? null
                          : () => _run(widget.onSnooze),
                      icon: const Icon(Icons.snooze_rounded),
                      label: const Text('Snooze 10m'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _handlingAction
                          ? null
                          : () => _run(widget.onStop),
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Stop'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns controllers used by a transient route and disposes them only after the
/// route's widget subtree is unmounted. A route future completes when it is
/// popped, before its exit animation has finished.
class _TextEditingControllerOwner extends StatefulWidget {
  const _TextEditingControllerOwner({
    required this.controllers,
    required this.child,
  });

  final List<TextEditingController> controllers;
  final Widget child;

  @override
  State<_TextEditingControllerOwner> createState() =>
      _TextEditingControllerOwnerState();
}

class _TextEditingControllerOwnerState
    extends State<_TextEditingControllerOwner> {
  @override
  void dispose() {
    for (final controller in widget.controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
