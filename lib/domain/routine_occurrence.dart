class RoutineOccurrence {
  final String itemId;
  final String occurrenceDate;
  final bool isCompleted;
  final String? eventTimestamp;
  final String recordedAtTimestamp;

  const RoutineOccurrence({
    required this.itemId,
    required this.occurrenceDate,
    required this.isCompleted,
    this.eventTimestamp,
    required this.recordedAtTimestamp,
  });

  String get key => keyFor(itemId, occurrenceDate);

  static String keyFor(String itemId, String occurrenceDate) =>
      '$itemId::$occurrenceDate';
}
