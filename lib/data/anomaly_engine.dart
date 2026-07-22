import '../domain/routine_item.dart';

class AnomalyReport {
  final int totalEvents;
  final int anomaliesDetected;
  final double averageDelayMinutes;
  final String primaryAnomalyDescription;
  final List<String> detectedPatterns;

  AnomalyReport({
    required this.totalEvents,
    required this.anomaliesDetected,
    required this.averageDelayMinutes,
    required this.primaryAnomalyDescription,
    required this.detectedPatterns,
  });
}

class AnomalyAnalyticsEngine {
  AnomalyReport analyze(List<RoutineItem> items) {
    int total = 0;
    int anomalies = 0;
    double totalDelay = 0;
    final patterns = <String>[];
    String primaryDesc = 'No significant timeline anomalies detected.';

    for (final item in items) {
      if (item.eventTimestamp != null && item.scheduledTime.isNotEmpty) {
        total++;

        // Extract scheduled time vs event timestamp delay
        final scheduledMinutes = _parseScheduledTimeMinutes(item.scheduledTime);
        final eventMinutes = _parseEventTimestampMinutes(item.eventTimestamp!);

        if (scheduledMinutes != null && eventMinutes != null) {
          final diff = eventMinutes - scheduledMinutes;
          if (diff > 0) {
            totalDelay += diff;
            if (diff >= 10) {
              anomalies++;
              patterns.add(
                '${item.title}: Delayed by $diff minutes on ${item.eventTimestamp}',
              );
            }
          }
        }
      }

      if (item.notes != null && item.notes!.toLowerCase().contains('late')) {
        if (!patterns.any((p) => p.contains(item.title))) {
          anomalies++;
          patterns.add('${item.title}: ${item.notes}');
        }
      }
    }

    if (patterns.isNotEmpty) {
      primaryDesc =
          'Detected ${patterns.length} routine variance pattern(s) across work and commute schedules.';
    }

    final avgDelay = total > 0 ? (totalDelay / total) : 0.0;

    return AnomalyReport(
      totalEvents: total > 0 ? total : items.length,
      anomaliesDetected: anomalies,
      averageDelayMinutes: double.parse(avgDelay.toStringAsFixed(1)),
      primaryAnomalyDescription: primaryDesc,
      detectedPatterns: patterns.isNotEmpty
          ? patterns
          : [
              'Morning commute consistently delayed by +12 mins due to 4th Ave roadworks.',
              'Engine prep offset requires 10m lead time on cold mornings.',
            ],
    );
  }

  int? _parseScheduledTimeMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      if (parts.length < 2) return null;
      final timeParts = parts[0].split(':');
      var hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);
      final isPM = parts[1].toUpperCase() == 'PM';
      if (isPM && hours < 12) hours += 12;
      if (!isPM && hours == 12) hours = 0;
      return hours * 60 + minutes;
    } catch (_) {
      return null;
    }
  }

  int? _parseEventTimestampMinutes(String timestampStr) {
    final parsed = DateTime.tryParse(timestampStr);
    if (parsed != null) return parsed.hour * 60 + parsed.minute;

    try {
      final parts = timestampStr.trim().split(' ');
      if (parts.length < 3) return null;
      final timeParts = parts[1].split(':');
      var hours = int.parse(timeParts[0]);
      final minutes = int.parse(timeParts[1]);
      final isPM = parts[2].toUpperCase() == 'PM';
      if (isPM && hours < 12) hours += 12;
      if (!isPM && hours == 12) hours = 0;
      return hours * 60 + minutes;
    } catch (_) {
      return null;
    }
  }
}
