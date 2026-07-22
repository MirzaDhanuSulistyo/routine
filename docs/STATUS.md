# Product delivery status

**Updated:** current working tree

**Operating mode:** active development

## Current stage

- Stage: Beta — core workflow hardening
- Status: in progress
- Current focus: reliable reminders and recurring schedules
- Next focus: per-occurrence history and seven-day analytics

## Implemented

- Flutter timeline with light and dark Andura themes
- SQLite schema and repository persistence
- Flexible routine item creation
- Past, present, and future date navigation
- Fast text/numeric logs with separate ISO event and recorded timestamps
- Item completion persistence
- Daily and weekly recurring timeline projection
- Timezone-aware Android/iOS notification scheduling
- Preparation lead-time alerts
- Notification actions for Done, Snooze 10m, and Add Note
- Runtime notification permission controls and pending-reminder status
- Finite source-filtered demo briefing cards
- Basic local schedule variance analysis
- Functional seed-data restore
- Isolated database instances for tests and alternate stores

## Validation baseline

- `flutter analyze` — passing
- `flutter test` — passing
- `flutter build apk --debug` — passing
- `flutter build ios --simulator --no-codesign` — passing
- iOS simulator screenshots are available under `artifacts/screens/`

## Remaining release blockers

- Add per-occurrence completion history for recurring items
- Add edit/delete item flows and notification rescheduling
- Replace demo briefings with live, cached sources and offline states
- Implement true sliding seven-day repeated-note and candidate-correlation rules
- Persist theme preferences and expose permission-loss diagnostics
- Add local export/backup and restore
- Expand accessibility, failure-state, migration, and integration coverage
- Split the remaining presentation code in `lib/main.dart` into screen/controller modules

## Product status note

The Flutter app is a functional beta, not a production-complete release. The React app under `src/` is an earlier mock-data UI proof and is not currently feature-equivalent.
