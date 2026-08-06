/// Weekday numbers use Dart's `DateTime.weekday` convention: Monday = 1
/// through Sunday = 7. Used by the `daily` recurrence rule to select which
/// days of the week repeat. A null or empty list means every day (legacy
/// `daily` behavior).
class RoutineItem {
  final String id;
  final String title;
  final String itemType;
  final String category;
  final String timeOfDay;
  final String scheduledTime;
  final String? scheduledDate;
  final String recurrenceRule;
  final bool notificationsEnabled;
  final String? eventTimestamp;
  final String? recordedAtTimestamp;
  bool isCompleted;
  final String? notes;
  final int? prepOffsetMinutes;
  final List<int>? repeatDays;
  final List<String>? topicSources;
  final List<Map<String, String>>? briefStories;

  RoutineItem({
    required this.id,
    required this.title,
    required this.itemType,
    required this.category,
    required this.timeOfDay,
    required this.scheduledTime,
    this.scheduledDate,
    this.recurrenceRule = 'none',
    this.notificationsEnabled = false,
    this.eventTimestamp,
    this.recordedAtTimestamp,
    this.isCompleted = false,
    this.notes,
    this.prepOffsetMinutes,
    this.repeatDays,
    this.topicSources,
    this.briefStories,
  });

  /// Whether this item is scheduled to occur on the given calendar date.
  bool occursOnDate(DateTime date) {
    final start = DateTime.tryParse(scheduledDate ?? '');
    if (start == null) return false;
    final target = DateTime(date.year, date.month, date.day);
    final first = DateTime(start.year, start.month, start.day);
    if (target.isBefore(first)) return false;
    final difference = target.difference(first).inDays;
    return switch (recurrenceRule) {
      'daily' => _repeatsOnWeekday(target.weekday),
      'weekly' => difference % 7 == 0,
      'monthly' => target.day == first.day,
      _ => difference == 0,
    };
  }

  /// Whether the daily recurrence fires on the given weekday.
  bool _repeatsOnWeekday(int weekday) {
    final days = repeatDays;
    if (days == null || days.isEmpty) return true;
    return days.contains(weekday);
  }

  RoutineItem copyWith({
    String? title,
    String? itemType,
    String? category,
    String? timeOfDay,
    String? scheduledTime,
    String? scheduledDate,
    String? recurrenceRule,
    bool? notificationsEnabled,
    String? eventTimestamp,
    String? recordedAtTimestamp,
    bool? isCompleted,
    String? notes,
    int? prepOffsetMinutes,
    List<int>? repeatDays,
    List<String>? topicSources,
    List<Map<String, String>>? briefStories,
  }) {
    return RoutineItem(
      id: id,
      title: title ?? this.title,
      itemType: itemType ?? this.itemType,
      category: category ?? this.category,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      eventTimestamp: eventTimestamp ?? this.eventTimestamp,
      recordedAtTimestamp: recordedAtTimestamp ?? this.recordedAtTimestamp,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      prepOffsetMinutes: prepOffsetMinutes ?? this.prepOffsetMinutes,
      repeatDays: repeatDays ?? this.repeatDays,
      topicSources: topicSources ?? this.topicSources,
      briefStories: briefStories ?? this.briefStories,
    );
  }
}
