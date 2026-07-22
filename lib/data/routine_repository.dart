import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../domain/routine_item.dart';
import '../domain/routine_occurrence.dart';
import 'database_helper.dart';

class RoutineRepository {
  final DatabaseHelper dbHelper;

  RoutineRepository({DatabaseHelper? dbHelper})
    : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<RoutineItem>> getAllItems() async {
    final db = await dbHelper.database;
    final maps = await db.query('items');

    if (maps.isEmpty) {
      await resetToSeedItems();
      return getAllItems();
    }

    final items = <RoutineItem>[];
    for (final map in maps) {
      try {
        items.add(_mapToRoutineItem(map));
      } catch (_) {
        // Ignore an invalid record without destroying valid user data.
      }
    }
    items.sort(_compareItems);
    return items;
  }

  Future<List<RoutineItem>> getItemsForDate(DateTime date) async {
    final items = await getAllItems();
    final dateKey = _dateKey(date);
    final db = await dbHelper.database;
    final occurrenceMaps = await db.query(
      'item_occurrences',
      where: 'occurrence_date = ?',
      whereArgs: [dateKey],
    );
    final completedIds = occurrenceMaps
        .map(_mapToOccurrence)
        .where((entry) => entry.isCompleted)
        .map((entry) => entry.itemId)
        .toSet();

    final projected =
        items.where((item) => _occursOnDate(item, date)).map((item) {
          if (item.recurrenceRule == 'none') return item;
          return item.copyWith(isCompleted: completedIds.contains(item.id));
        }).toList()..sort(
          (a, b) => _timeMinutes(
            a.scheduledTime,
          ).compareTo(_timeMinutes(b.scheduledTime)),
        );
    return projected;
  }

  Future<void> seedDataIfEmpty() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM items'),
    );
    if (count == null || count == 0) await resetToSeedItems();
  }

  Future<void> resetToSeedItems({DateTime? date}) async {
    final db = await dbHelper.database;
    final seeds = getSeedItems(date: date);
    await db.transaction((txn) async {
      await txn.delete('item_occurrences');
      await txn.delete('items');
      final batch = txn.batch();
      for (final item in seeds) {
        batch.insert('items', _routineItemToMap(item));
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> insertItem(RoutineItem item) async {
    final db = await dbHelper.database;
    final values = _routineItemToMap(item);
    await db.transaction((txn) async {
      final updated = await txn.update(
        'items',
        values,
        where: 'id = ?',
        whereArgs: [item.id],
      );
      if (updated == 0) await txn.insert('items', values);
    });
  }

  Future<RoutineItem?> getItemById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : _mapToRoutineItem(maps.first);
  }

  Future<List<RoutineOccurrence>> getAllOccurrences() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'item_occurrences',
      orderBy: 'occurrence_date ASC',
    );
    return maps.map(_mapToOccurrence).toList();
  }

  Future<RoutineOccurrence?> getOccurrence(
    String itemId,
    String occurrenceDate,
  ) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'item_occurrences',
      where: 'item_id = ? AND occurrence_date = ?',
      whereArgs: [itemId, occurrenceDate],
      limit: 1,
    );
    return maps.isEmpty ? null : _mapToOccurrence(maps.first);
  }

  Future<void> setOccurrenceCompletion({
    required String itemId,
    required String occurrenceDate,
    required bool isCompleted,
    DateTime? eventTime,
  }) async {
    final db = await dbHelper.database;
    if (!isCompleted) {
      await db.delete(
        'item_occurrences',
        where: 'item_id = ? AND occurrence_date = ?',
        whereArgs: [itemId, occurrenceDate],
      );
      return;
    }

    final now = DateTime.now();
    await db.insert('item_occurrences', {
      'item_id': itemId,
      'occurrence_date': occurrenceDate,
      'is_completed': 1,
      'event_timestamp': (eventTime ?? now).toIso8601String(),
      'recorded_at_timestamp': now.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateItemCompletion(String id, bool isCompleted) async {
    final db = await dbHelper.database;
    await db.update(
      'items',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(String id) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'item_occurrences',
        where: 'item_id = ?',
        whereArgs: [id],
      );
      await txn.delete('items', where: 'id = ?', whereArgs: [id]);
    });
  }

  RoutineOccurrence _mapToOccurrence(Map<String, dynamic> map) {
    return RoutineOccurrence(
      itemId: map['item_id'].toString(),
      occurrenceDate: map['occurrence_date'].toString(),
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      eventTimestamp: map['event_timestamp']?.toString(),
      recordedAtTimestamp: map['recorded_at_timestamp'].toString(),
    );
  }

  RoutineItem _mapToRoutineItem(Map<String, dynamic> map) {
    List<String>? topicSources;
    if (map['topic_sources_json'] != null) {
      topicSources = List<String>.from(
        jsonDecode(map['topic_sources_json'].toString()),
      );
    }

    List<Map<String, String>>? briefStories;
    if (map['brief_stories_json'] != null) {
      final rawList = jsonDecode(map['brief_stories_json'].toString()) as List;
      briefStories = rawList
          .map((entry) => Map<String, String>.from(entry as Map))
          .toList();
    }

    return RoutineItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Untitled Item',
      itemType: map['item_type']?.toString() ?? 'task',
      category: map['category']?.toString() ?? 'personal',
      timeOfDay: map['time_of_day']?.toString() ?? 'morning',
      scheduledTime: map['scheduled_time']?.toString() ?? '09:00 AM',
      scheduledDate: map['scheduled_date']?.toString(),
      recurrenceRule: map['recurrence_rule']?.toString() ?? 'none',
      notificationsEnabled:
          map['notifications_enabled'] == 1 ||
          map['notifications_enabled'] == true,
      eventTimestamp: map['event_timestamp']?.toString(),
      recordedAtTimestamp: map['recorded_at_timestamp']?.toString(),
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      notes: map['notes']?.toString(),
      numericValue: map['numeric_value'] != null
          ? (map['numeric_value'] as num).toDouble()
          : null,
      unit: map['unit']?.toString(),
      prepOffsetMinutes: map['prep_offset_minutes'] != null
          ? (map['prep_offset_minutes'] as num).toInt()
          : null,
      topicSources: topicSources,
      briefStories: briefStories,
    );
  }

  Map<String, dynamic> _routineItemToMap(RoutineItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'item_type': item.itemType,
      'category': item.category,
      'time_of_day': item.timeOfDay,
      'scheduled_time': item.scheduledTime,
      'scheduled_date': item.scheduledDate,
      'recurrence_rule': item.recurrenceRule,
      'notifications_enabled': item.notificationsEnabled ? 1 : 0,
      'event_timestamp': item.eventTimestamp,
      'recorded_at_timestamp': item.recordedAtTimestamp,
      'is_completed': item.isCompleted ? 1 : 0,
      'notes': item.notes,
      'numeric_value': item.numericValue,
      'unit': item.unit,
      'prep_offset_minutes': item.prepOffsetMinutes,
      'topic_sources_json': item.topicSources == null
          ? null
          : jsonEncode(item.topicSources),
      'brief_stories_json': item.briefStories == null
          ? null
          : jsonEncode(item.briefStories),
    };
  }

  List<RoutineItem> getSeedItems({DateTime? date}) {
    final day = DateTime(
      date?.year ?? DateTime.now().year,
      date?.month ?? DateTime.now().month,
      date?.day ?? DateTime.now().day,
    );
    final dateKey = _dateKey(day);
    String eventAt(int hour, int minute) =>
        DateTime(day.year, day.month, day.day, hour, minute).toIso8601String();

    return [
      RoutineItem(
        id: '1',
        title: 'Warm up car (Engine & AC prep)',
        itemType: 'preparation',
        category: 'home',
        timeOfDay: 'morning',
        scheduledTime: '06:40 AM',
        scheduledDate: dateKey,
        eventTimestamp: eventAt(6, 42),
        recordedAtTimestamp: eventAt(6, 42),
        isCompleted: true,
        prepOffsetMinutes: 10,
        notes: 'Took two attempts to start smoothly',
      ),
      RoutineItem(
        id: '2',
        title: 'Morning Briefing — Tech, Markets & Social Trends',
        itemType: 'briefing',
        category: 'personal',
        timeOfDay: 'morning',
        scheduledTime: '07:00 AM',
        scheduledDate: dateKey,
        eventTimestamp: eventAt(7, 5),
        recordedAtTimestamp: eventAt(7, 5),
        topicSources: const ['TechCrunch', 'Bloomberg', 'HackerNews'],
        briefStories: const [
          {
            'headline':
                'AI Hardware Startups Shift Focus to Edge Inference Chips',
            'summary':
                'Next-gen devices prioritize on-device models with sub-watt power budgets.',
            'source': 'TechCrunch',
          },
          {
            'headline':
                'Global Yield Curves Flatten as Central Banks Hold Rates',
            'summary':
                'Treasury yields remain stable while tech sector indices record gains.',
            'source': 'Bloomberg',
          },
          {
            'headline': 'Show HN: Local-First Encrypted Notes for Mobile',
            'summary':
                'Community response highlights preference for zero-cloud data models.',
            'source': 'HackerNews',
          },
        ],
      ),
      RoutineItem(
        id: '3',
        title: 'Clock In to Work',
        itemType: 'reminder',
        category: 'work',
        timeOfDay: 'morning',
        scheduledTime: '08:00 AM',
        scheduledDate: dateKey,
        eventTimestamp: eventAt(8, 12),
        recordedAtTimestamp: eventAt(8, 12),
        isCompleted: true,
        notes: 'Arrived 12 minutes late due to road construction on 4th Ave',
      ),
      RoutineItem(
        id: '4',
        title: 'Clock Out of Work',
        itemType: 'reminder',
        category: 'work',
        timeOfDay: 'afternoon',
        scheduledTime: '05:00 PM',
        scheduledDate: dateKey,
      ),
      RoutineItem(
        id: '5',
        title: "Kid's Math Practice & Homework",
        itemType: 'task',
        category: 'family',
        timeOfDay: 'evening',
        scheduledTime: '07:00 PM',
        scheduledDate: dateKey,
      ),
      RoutineItem(
        id: '6',
        title: 'Nightly Sleep & Observation Log',
        itemType: 'log',
        category: 'personal',
        timeOfDay: 'evening',
        scheduledTime: '09:30 PM',
        scheduledDate: dateKey,
        eventTimestamp: eventAt(9, 15),
        recordedAtTimestamp: eventAt(9, 15),
        notes: 'Slept 5.5 hours. Plant soil looked dry.',
        numericValue: 5.5,
        unit: 'hours sleep',
      ),
    ];
  }

  bool _occursOnDate(RoutineItem item, DateTime date) {
    final start = DateTime.tryParse(item.scheduledDate ?? '');
    if (start == null) return false;
    final target = DateTime(date.year, date.month, date.day);
    final first = DateTime(start.year, start.month, start.day);
    if (target.isBefore(first)) return false;
    final difference = target.difference(first).inDays;
    return switch (item.recurrenceRule) {
      'daily' => true,
      'weekly' => difference % 7 == 0,
      _ => difference == 0,
    };
  }

  int _compareItems(RoutineItem a, RoutineItem b) {
    final dateComparison = (a.scheduledDate ?? '').compareTo(
      b.scheduledDate ?? '',
    );
    if (dateComparison != 0) return dateComparison;
    return _timeMinutes(
      a.scheduledTime,
    ).compareTo(_timeMinutes(b.scheduledTime));
  }

  int _timeMinutes(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return 24 * 60;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (hour == 12) hour = 0;
    if (period == 'PM') hour += 12;
    return hour * 60 + minute;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
