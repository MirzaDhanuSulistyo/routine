import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../main.dart';
import 'database_helper.dart';

class RoutineRepository {
  final DatabaseHelper dbHelper;

  RoutineRepository({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<RoutineItem>> getAllItems() async {
    final db = await dbHelper.database;
    final maps = await db.query('items', orderBy: 'scheduled_time ASC');

    if (maps.isEmpty) {
      final seeds = getSeedItems();
      for (final item in seeds) {
        await insertItem(item);
      }
      return seeds;
    }

    final items = <RoutineItem>[];
    for (final map in maps) {
      try {
        items.add(_mapToRoutineItem(map));
      } catch (_) {}
    }

    if (items.isEmpty) {
      await db.delete('items');
      final seeds = getSeedItems();
      for (final item in seeds) {
        await insertItem(item);
      }
      return seeds;
    }

    return items;
  }

  Future<void> seedDataIfEmpty() async {
    final db = await dbHelper.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM items'));
    if (count == null || count == 0) {
      final seeds = getSeedItems();
      for (final item in seeds) {
        await insertItem(item);
      }
    }
  }

  Future<void> insertItem(RoutineItem item) async {
    final db = await dbHelper.database;
    await db.insert(
      'items',
      _routineItemToMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  RoutineItem _mapToRoutineItem(Map<String, dynamic> map) {
    List<String>? topicSources;
    if (map['topic_sources_json'] != null) {
      try {
        topicSources = List<String>.from(jsonDecode(map['topic_sources_json'].toString()));
      } catch (_) {}
    }

    List<Map<String, String>>? briefStories;
    if (map['brief_stories_json'] != null) {
      try {
        final rawList = jsonDecode(map['brief_stories_json'].toString()) as List;
        briefStories = rawList.map((e) => Map<String, String>.from(e as Map)).toList();
      } catch (_) {}
    }

    return RoutineItem(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? 'Untitled Item',
      itemType: map['item_type']?.toString() ?? 'task',
      category: map['category']?.toString() ?? 'personal',
      timeOfDay: map['time_of_day']?.toString() ?? 'morning',
      scheduledTime: map['scheduled_time']?.toString() ?? '09:00 AM',
      eventTimestamp: map['event_timestamp']?.toString(),
      recordedAtTimestamp: map['recorded_at_timestamp']?.toString(),
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      notes: map['notes']?.toString(),
      numericValue: map['numeric_value'] != null ? (map['numeric_value'] as num).toDouble() : null,
      unit: map['unit']?.toString(),
      prepOffsetMinutes: map['prep_offset_minutes'] != null ? (map['prep_offset_minutes'] as num).toInt() : null,
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
      'event_timestamp': item.eventTimestamp,
      'recorded_at_timestamp': item.recordedAtTimestamp,
      'is_completed': item.isCompleted ? 1 : 0,
      'notes': item.notes,
      'numeric_value': item.numericValue,
      'unit': item.unit,
      'prep_offset_minutes': item.prepOffsetMinutes,
      'topic_sources_json': item.topicSources != null ? jsonEncode(item.topicSources) : null,
      'brief_stories_json': item.briefStories != null ? jsonEncode(item.briefStories) : null,
    };
  }

  List<RoutineItem> getSeedItems() {
    return [
      RoutineItem(
        id: '1',
        title: 'Warm up car (Engine & AC prep)',
        itemType: 'preparation',
        category: 'home',
        timeOfDay: 'morning',
        scheduledTime: '06:40 AM',
        eventTimestamp: '2026-07-20 06:42 AM',
        recordedAtTimestamp: '2026-07-20 06:42 AM',
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
        eventTimestamp: '2026-07-20 07:05 AM',
        recordedAtTimestamp: '2026-07-20 07:05 AM',
        topicSources: ['TechCrunch', 'Bloomberg', 'HackerNews'],
        briefStories: [
          {
            'headline': 'AI Hardware Startups Shift Focus to Edge Inference Chips',
            'summary': 'Next-gen devices prioritize on-device models with sub-watt power budgets.',
            'source': 'TechCrunch',
          },
          {
            'headline': 'Global Yield Curves Flatten as Central Banks Hold Rates',
            'summary': 'Treasury yields remain stable while tech sector indices record gains.',
            'source': 'Bloomberg',
          },
          {
            'headline': 'Show HN: Local-First Encrypted Notes for Mobile',
            'summary': 'Community response highlights growing user preference for zero-cloud data models.',
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
        eventTimestamp: '2026-07-20 08:12 AM',
        recordedAtTimestamp: '2026-07-20 08:12 AM',
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
      ),
      RoutineItem(
        id: '5',
        title: 'Kid\'s Math Practice & Homework',
        itemType: 'task',
        category: 'family',
        timeOfDay: 'evening',
        scheduledTime: '07:00 PM',
      ),
      RoutineItem(
        id: '6',
        title: 'Nightly Sleep & Observation Log',
        itemType: 'log',
        category: 'personal',
        timeOfDay: 'evening',
        scheduledTime: '09:30 PM',
        eventTimestamp: '2026-07-20 09:15 AM',
        recordedAtTimestamp: '2026-07-20 09:15 AM',
        notes: 'Slept 5.5 hours. Plant soil looked dry.',
        numericValue: 5.5,
        unit: 'hours sleep',
      ),
    ];
  }
}
