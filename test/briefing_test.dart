import 'package:flutter_test/flutter_test.dart';
import 'package:routine/data/briefing_service.dart';

void main() {
  test('BriefingService fetches default stories', () async {
    final service = BriefingService();
    final stories = await service.fetchBriefingStories();

    expect(stories, isNotEmpty);
    expect(stories.any((s) => s.source == 'TechCrunch'), isTrue);
    expect(stories.any((s) => s.source == 'Bloomberg'), isTrue);
  });

  test('BriefingService filters stories by selected sources', () async {
    final service = BriefingService();
    final stories = await service.fetchBriefingStories(
      selectedSources: ['TechCrunch'],
    );

    expect(stories.every((s) => s.source == 'TechCrunch'), isTrue);
  });
}
