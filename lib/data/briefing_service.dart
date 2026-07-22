import 'dart:async';

class BriefStory {
  final String headline;
  final String summary;
  final String source;
  final String category;
  final String? url;

  BriefStory({
    required this.headline,
    required this.summary,
    required this.source,
    required this.category,
    this.url,
  });

  Map<String, String> toMap() {
    return {
      'headline': headline,
      'summary': summary,
      'source': source,
      'category': category,
      'url': ?url,
    };
  }

  factory BriefStory.fromMap(Map<String, dynamic> map) {
    return BriefStory(
      headline: map['headline']?.toString() ?? 'Untitled Story',
      summary: map['summary']?.toString() ?? '',
      source: map['source']?.toString() ?? 'News Feed',
      category: map['category']?.toString() ?? 'General',
      url: map['url']?.toString(),
    );
  }
}

class BriefingService {
  final List<String> availableSources = [
    'TechCrunch',
    'Bloomberg',
    'HackerNews',
    'Wall Street Journal',
    'The Verge',
    'Ars Technica',
  ];

  Future<List<BriefStory>> fetchBriefingStories({
    List<String>? selectedSources,
  }) async {
    // Simulate lightweight network delay for feed fetching
    await Future.delayed(const Duration(milliseconds: 250));

    final sources =
        selectedSources ?? ['TechCrunch', 'Bloomberg', 'HackerNews'];

    final allStories = [
      BriefStory(
        headline: 'AI Hardware Startups Shift Focus to Edge Inference Chips',
        summary:
            'Next-gen devices prioritize on-device models with sub-watt power budgets to eliminate cloud latency.',
        source: 'TechCrunch',
        category: 'Technology',
        url: 'https://techcrunch.com',
      ),
      BriefStory(
        headline:
            'Global Yield Curves Flatten as Central Banks Hold Interest Rates',
        summary:
            'Treasury yields remain stable while tech sector indices record modest morning gains.',
        source: 'Bloomberg',
        category: 'Markets',
        url: 'https://bloomberg.com',
      ),
      BriefStory(
        headline:
            'Show HN: Local-First Encrypted Notes with SQLite Persistence',
        summary:
            'Community response highlights growing developer preference for zero-cloud client architecture.',
        source: 'HackerNews',
        category: 'Engineering',
        url: 'https://news.ycombinator.com',
      ),
      BriefStory(
        headline:
            'Consumer Sentiment Rebounds Ahead of Quarterly Earnings Reports',
        summary:
            'Retail figures indicate steady consumer spending across tech and hardware sectors.',
        source: 'Wall Street Journal',
        category: 'Economy',
        url: 'https://wsj.com',
      ),
      BriefStory(
        headline:
            'Open-Source AI Models Attain Parity in Mobile Efficiency Metrics',
        summary:
            'Benchmarks show 3B parameter models executing 45 tokens/sec on modern arm mobile SoCs.',
        source: 'Ars Technica',
        category: 'AI Research',
        url: 'https://arstechnica.com',
      ),
    ];

    return allStories.where((story) => sources.contains(story.source)).toList();
  }
}
