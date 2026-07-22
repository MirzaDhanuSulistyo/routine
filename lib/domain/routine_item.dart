class RoutineItem {
  final String id;
  final String title;
  final String itemType;
  final String category;
  final String timeOfDay;
  final String scheduledTime;
  final String? scheduledDate;
  final String? eventTimestamp;
  final String? recordedAtTimestamp;
  bool isCompleted;
  final String? notes;
  final double? numericValue;
  final String? unit;
  final int? prepOffsetMinutes;
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
    this.eventTimestamp,
    this.recordedAtTimestamp,
    this.isCompleted = false,
    this.notes,
    this.numericValue,
    this.unit,
    this.prepOffsetMinutes,
    this.topicSources,
    this.briefStories,
  });

  RoutineItem copyWith({
    String? title,
    String? itemType,
    String? category,
    String? timeOfDay,
    String? scheduledTime,
    String? scheduledDate,
    String? eventTimestamp,
    String? recordedAtTimestamp,
    bool? isCompleted,
    String? notes,
    double? numericValue,
    String? unit,
    int? prepOffsetMinutes,
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
      eventTimestamp: eventTimestamp ?? this.eventTimestamp,
      recordedAtTimestamp: recordedAtTimestamp ?? this.recordedAtTimestamp,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      numericValue: numericValue ?? this.numericValue,
      unit: unit ?? this.unit,
      prepOffsetMinutes: prepOffsetMinutes ?? this.prepOffsetMinutes,
      topicSources: topicSources ?? this.topicSources,
      briefStories: briefStories ?? this.briefStories,
    );
  }
}
