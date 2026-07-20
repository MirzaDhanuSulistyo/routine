import 'package:flutter/material.dart';
import 'package:andura_ui/andura_ui.dart';

void main() {
  runApp(const RoutineApp());
}

class RoutineApp extends StatefulWidget {
  const RoutineApp({super.key});

  @override
  State<RoutineApp> createState() => _RoutineAppState();
}

class _RoutineAppState extends State<RoutineApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
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
      ),
    );
  }
}

class RoutineItem {
  final String id;
  final String title;
  final String itemType; // reminder, task, maintenance, deadline, preparation, briefing, log
  final String category; // work, family, home, finance, personal
  final String timeOfDay; // morning, afternoon, evening
  final String scheduledTime;
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
}

class MainNavigationScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const MainNavigationScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final String _currentDate = 'Monday, Jul 20, 2026';

  late List<RoutineItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      RoutineItem(
        id: '1',
        title: 'Warm up car (Engine & AC prep)',
        itemType: 'preparation',
        category: 'home',
        timeOfDay: 'morning',
        scheduledTime: '06:40 AM',
        prepOffsetMinutes: 10,
        isCompleted: true,
        eventTimestamp: '2026-07-20 06:42 AM',
        recordedAtTimestamp: '2026-07-20 06:42 AM',
        notes: 'Took two attempts to start smoothly',
      ),
      RoutineItem(
        id: '2',
        title: 'Morning Briefing — Tech, Markets & Social Trends',
        itemType: 'briefing',
        category: 'personal',
        timeOfDay: 'morning',
        scheduledTime: '07:00 AM',
        isCompleted: true,
        eventTimestamp: '2026-07-20 07:05 AM',
        recordedAtTimestamp: '2026-07-20 07:05 AM',
        topicSources: ['Reddit / r/technology', 'Bluesky / AI Update', 'GNews / Tech'],
        briefStories: [
          {
            'source': 'Bluesky / AI Update',
            'headline': 'Open-Source Multi-Modal Models Reach New Benchmarks',
            'summary': 'New lightweight models achieve near state-of-the-art vision and code execution while running on consumer GPUs.',
          },
          {
            'source': 'Reddit / r/technology',
            'headline': 'Global Renewable Energy Grid Storage Surges 40%',
            'summary': 'Grid battery deployments in Q2 surpassed all previous yearly milestones driven by lower LFP cell costs.',
          },
          {
            'source': 'GNews / Markets',
            'headline': 'Tech Earnings Week Kicks Off with Semiconductor Signals',
            'summary': 'Key suppliers report strong server chip demand while consumer hardware orders normalize.',
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
        isCompleted: true,
        eventTimestamp: '2026-07-20 08:12 AM',
        recordedAtTimestamp: '2026-07-20 08:12 AM',
        notes: 'Arrived 12 minutes late due to road construction on 4th Ave',
      ),
      RoutineItem(
        id: '4',
        title: 'Clock Out of Work',
        itemType: 'reminder',
        category: 'work',
        timeOfDay: 'afternoon',
        scheduledTime: '05:00 PM',
        isCompleted: false,
      ),
      RoutineItem(
        id: '5',
        title: 'Water Indoor & Balcony Plants',
        itemType: 'maintenance',
        category: 'home',
        timeOfDay: 'afternoon',
        scheduledTime: '06:00 PM',
        isCompleted: false,
      ),
      RoutineItem(
        id: '6',
        title: 'Help Son Practice Math (Multiplication Tables)',
        itemType: 'task',
        category: 'family',
        timeOfDay: 'evening',
        scheduledTime: '06:30 PM',
        isCompleted: false,
      ),
      RoutineItem(
        id: '7',
        title: 'Daily Life Observation & Sleep Log',
        itemType: 'log',
        category: 'personal',
        timeOfDay: 'evening',
        scheduledTime: '09:00 PM',
        isCompleted: true,
        eventTimestamp: '2026-07-20 09:15 AM',
        recordedAtTimestamp: '2026-07-20 09:15 AM',
        notes: 'Slept 5.5 hours. Plant soil looked dry.',
        numericValue: 5.5,
        unit: 'hours sleep',
      ),
    ];
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
        final numController = TextEditingController();

        return StatefulBuilder(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fast Event & Observation Logger',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Target Date (Dual Timestamping)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
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
                    hintText: 'e.g. Car engine hesitated, plant soil was dry...',
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AnduraTextField(
                          controller: numController,
                          keyboardType: TextInputType.number,
                          labelText: 'Numeric Value',
                          hintText: 'e.g. 5.5',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnduraSelect<String>(
                          value: category,
                          labelText: 'Category',
                          items: const [
                            DropdownMenuItem(value: 'personal', child: Text('Personal')),
                            DropdownMenuItem(value: 'work', child: Text('Work')),
                            DropdownMenuItem(value: 'family', child: Text('Family')),
                            DropdownMenuItem(value: 'home', child: Text('Home')),
                            DropdownMenuItem(value: 'finance', child: Text('Finance')),
                          ],
                          onChanged: (val) => setSheetState(() => category = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                      if (noteController.text.isNotEmpty || numController.text.isNotEmpty) {
                        setState(() {
                          _items.insert(
                            0,
                            RoutineItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: noteController.text.isNotEmpty
                                  ? noteController.text.split('\n').first
                                  : 'Quick Observation Log',
                              itemType: 'log',
                              category: category,
                              timeOfDay: 'evening',
                              scheduledTime: 'Fast Logged',
                              isCompleted: true,
                              eventTimestamp: '$dateMode 09:00 AM',
                              recordedAtTimestamp: 'Today 09:35 AM',
                              notes: noteController.text.isNotEmpty ? noteController.text : null,
                              numericValue: double.tryParse(numController.text),
                              unit: numController.text.isNotEmpty ? 'units' : null,
                            ),
                          );
                        });
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Save Log Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBriefingModal(RoutineItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          title: Text(item.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 6,
                  children: (item.topicSources ?? []).map((src) {
                    return Chip(
                      label: Text(src, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text('Finite Scheduled Briefing (3 Stories)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 12),
                ...(item.briefStories ?? []).map((story) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story['source'] ?? '',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          story['headline'] ?? '',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          story['summary'] ?? '',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
              onPressed: () {
                setState(() => item.isCompleted = true);
                Navigator.pop(context);
              },
              child: const Text('✓ Mark Briefing Complete', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineSection(String title, String timeOfDay, IconData sectionIcon) {
    final sectionItems = _items.where((i) => i.timeOfDay == timeOfDay).toList();

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
            child: Text('No items scheduled', style: TextStyle(color: Colors.white38, fontSize: 13)),
          )
        else
          ...sectionItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5)),
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
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
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
                            item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: item.isCompleted ? const Color(0xFF34D399) : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              item.isCompleted = !item.isCompleted;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item.scheduledTime, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 12),
                      Text('• ${item.itemType.toUpperCase()}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  if (item.prepOffsetMinutes != null) ...[
                    const SizedBox(height: 6),
                    AnduraBadge(
                      label: 'Prep offset: ${item.prepOffsetMinutes}m lead time',
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ],
                  if (item.notes != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                        border: const Border(left: BorderSide(color: Color(0xFF38BDF8), width: 3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note, size: 14, color: Color(0xFF38BDF8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Log: ${item.notes}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (item.eventTimestamp != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 10, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .7)),
                            const SizedBox(width: 4),
                            Text(
                              'Event: ${item.eventTimestamp}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .7), fontSize: 10),
                            ),
                          ],
                        ),
                        if (item.recordedAtTimestamp != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save, size: 10, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .7)),
                              const SizedBox(width: 4),
                              Text(
                                'Recorded: ${item.recordedAtTimestamp}',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .7), fontSize: 10),
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
                Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Understand Layer: Periodic sliding 7-day rule engine detecting timing shifts, repeated notes, and candidate correlations.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard('7-Day Rate', '84%', '+4% vs last week'),
              const SizedBox(width: 10),
              _buildStatCard('Tracked', '42', 'Work, Family, Home'),
              const SizedBox(width: 10),
              _buildStatCard('Anomalies', '3', 'Requires review'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Detected Patterns & Anomalies',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAnomalyCard(
            'Timing Shift: Work Clock-Out Delay',
            'You clocked out >30 minutes late on 4 out of the last 6 workdays.',
            'Tuesday: +35m | Wednesday: +40m | Thursday: +25m',
            Colors.amber,
          ),
          _buildAnomalyCard(
            'Candidate Correlation: Overtime & Family',
            'Observed relationship: On days when work clock-out occurred past 05:30 PM, math practice was marked skipped or delayed.',
            'Co-occurrence in 3 of 4 recent instances.',
            const Color(0xFF38BDF8),
          ),
          _buildAnomalyCard(
            'Repeated Note: Vehicle Starting Delay',
            'Note "car engine hesitated / multi-start" was logged 3 times in the last 7 days.',
            'Jul 16: "Hesitated" | Jul 18: "3 attempts" | Jul 20: "2 attempts"',
            Colors.amber,
          ),
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
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(val, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(String title, String desc, String evidence, Color accentColor) {
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
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Evidence: $evidence',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11),
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
                Icon(Icons.bolt, color: Theme.of(context).colorScheme.primary, size: 18),
              ],
            ),
            Text(
              'Remember it. Record it. Notice the pattern.',
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.add_task, color: Theme.of(context).colorScheme.primary),
            onPressed: _showFastLogSheet,
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 6),
                            Text(
                              _currentDate,
                              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 115,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF38BDF8),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onPressed: _showFastLogSheet,
                          icon: const Icon(Icons.edit_note, size: 16),
                          label: const Text('+ Fast Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineSection('MORNING (05:00 - 12:00)', 'morning', Icons.wb_twilight),
                  const SizedBox(height: 12),
                  _buildTimelineSection('AFTERNOON (12:00 - 18:00)', 'afternoon', Icons.wb_sunny),
                  const SizedBox(height: 12),
                  _buildTimelineSection('EVENING (18:00 - 24:00)', 'evening', Icons.nights_stay),
                ],
              ),
            )
          : _selectedIndex == 1
              ? _buildPatternReportView()
              : Center(
                  child: Text('Settings & Topic Subscriptions', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: Colors.black,
        onPressed: _showFastLogSheet,
        icon: const Icon(Icons.flash_on),
        label: const Text('Quick Log'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Timeline'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Pattern Report'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
