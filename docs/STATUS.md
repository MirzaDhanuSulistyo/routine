# Product delivery status

**Updated:** current working tree

**Operating mode:** active development

## Current stage

- Stage: Beta — core workflow hardening
- Status: in progress
- Current focus: reliable plan-and-record workflow
- Next focus: notifications, recurrence, and seven-day analytics

## Implemented

- Flutter timeline with light and dark Andura themes
- SQLite schema and repository persistence
- Flexible routine item creation
- Past, present, and future date navigation
- Fast text/numeric logs with separate ISO event and recorded timestamps
- Item completion persistence
- Finite source-filtered demo briefing cards
- Basic local schedule variance analysis
- Functional seed-data restore
- Isolated database instances for tests and alternate stores

## Validation baseline

- `flutter analyze` — passing
- `flutter test` — passing
- iOS simulator screenshots are available under `artifacts/screens/`

## Remaining release blockers

- Schedule and deliver native local notifications with actions
- Add recurring schedule rules and edit/delete item flows
- Replace demo briefings with live, cached sources and offline states
- Implement true sliding seven-day repeated-note and candidate-correlation rules
- Persist theme and notification preferences
- Add local export/backup and restore
- Expand accessibility, failure-state, migration, and integration coverage
- Split the remaining presentation code in `lib/main.dart` into screen/controller modules

## Product status note

The Flutter app is a functional beta, not a production-complete release. The React app under `src/` is an earlier mock-data UI proof and is not currently feature-equivalent.
