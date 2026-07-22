# Routine

Routine is a local-first personal life operations assistant for planning expected events, recording what actually happened, and identifying explainable patterns over time.

> Remember it. Record it. Notice the pattern.

## Current capabilities

- Daily timeline grouped into morning, afternoon, and evening
- Past and future date navigation
- Flexible item creation across reminders, tasks, maintenance, deadlines, preparation, briefings, logs, and measurements
- Daily and weekly recurring timeline items with independent completion history per date
- Item editing and confirmed deletion with reminder rescheduling and history cleanup
- Native scheduled notifications with Done, Snooze 10m, and Add Note actions
- Preparation lead-time alerts with timezone-aware scheduling
- Fast observation and numeric logging with separate event and recorded timestamps
- Local SQLite persistence
- Finite, source-filtered briefing cards using demo content
- Basic on-device schedule variance reporting
- Linear light and dark themes

## Run the Flutter app

Routine currently depends on the sibling Andura UI repository:

```text
parent/
├── andura-ui/
└── routine/
```

Then run:

```sh
flutter pub get
flutter run
```

## Validate

```sh
flutter analyze
flutter test
```

## Project structure

- `lib/domain/` — application entities
- `lib/data/` — SQLite repository, briefing service, and analytics engine
- `lib/main.dart` — current Flutter presentation layer
- `test/` — repository, service, analytics, and widget tests
- `src/` — earlier React UI proof; it is not the production implementation
- `docs/` — product, architecture, screen, and delivery documentation

## Production gaps

The app remains a beta. Live briefing feeds, robust seven-day correlation analysis, data export, persisted preferences, and broader integration testing are still planned.
