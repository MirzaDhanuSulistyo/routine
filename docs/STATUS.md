# Product delivery status

**Updated:** current working tree

**Operating mode:** active development

## Current stage

- Stage: Beta — core workflow hardening
- Status: in progress
- Current focus: explainable multi-day analytics
- Next focus: seven-day pattern and anomaly rules

## Implemented

- Flutter timeline with light and dark Andura themes
- SQLite schema and repository persistence
- Flexible routine item creation
- Past, present, and future date navigation
- Fast text observation logs with separate ISO event and recorded timestamps
- Item completion persistence
- Per-occurrence completion history keyed by recurring item and date
- Completion event/recorded timestamps for recurring occurrences
- Daily and weekly recurring timeline projection
- Item editing and confirmed deletion with cascading history cleanup
- Reminder cancellation and rescheduling after item mutations
- Timezone-aware Android/iOS reminder scheduling
- Native Android exact alarms that survive app termination and device reboot
- Android foreground ringing/vibration service using the phone's ringer mode
- Full-screen Android lock-screen alarm UI with Stop and Snooze controls
- iOS time-sensitive notifications with system sound (within platform limits)
- Preparation lead-time alerts
- Notification/alarm actions for Done, Stop, Snooze 10m, and Add Note
- Runtime notification, exact-alarm, and full-screen permission controls
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

- Replace demo briefings with live, cached sources and offline states
- Implement true sliding seven-day repeated-note and candidate-correlation rules
- Persist theme preferences and expose permission-loss diagnostics
- Add local export/backup and restore
- Expand accessibility, failure-state, migration, and integration coverage
- Split the remaining presentation code in `lib/main.dart` into screen/controller modules

## Product status note

The Flutter app is a functional beta, not a production-complete release. The React app under `src/` is an earlier mock-data UI proof and is not currently feature-equivalent.
