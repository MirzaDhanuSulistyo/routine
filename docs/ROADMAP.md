# Routine — Delivery Roadmap

**Status:** Active

**Delivery principle:** complete independently testable vertical slices; do not count demo data as a production integration.

## Phase 1 — Local persistence and daily timeline

**Status:** substantially complete

Delivered:
- SQLite item persistence and migration support
- Daily timeline and chronological time sorting
- Past/future date navigation
- Flexible item creation
- Fast logs with separate event and recorded timestamps
- Completion updates and functional seed restore

Remaining:
- Edit/delete interactions
- Recurring schedule model
- Timeline search and filters

## Phase 2 — Native reminders and finite briefings

**Status:** partial

Delivered:
- Preparation lead-time model
- Finite briefing UI
- Source selection and cached SQLite representation

Remaining:
- `flutter_local_notifications` integration
- Done, Snooze, and Add Note notification actions
- Permission-loss handling
- Live RSS/API adapters, cache age, and offline/error states

## Phase 3 — Seven-day pattern engine

**Status:** prototype

Delivered:
- Local schedule-delay calculation
- Evidence cards and summary metrics

Remaining:
- Sliding seven-day query window
- Repeated observation rules
- Recurring timing-shift thresholds
- Candidate co-occurrence rules
- Deterministic fixtures covering multiple days and cautious insight language

## Phase 4 — Settings and release readiness

**Status:** partial

Delivered:
- Light/dark theme control
- Database status and seed restore

Remaining:
- Persisted user settings
- Notification schedule controls
- JSON export/import
- Accessibility and performance validation
- Android/iOS release configuration and end-to-end testing

## Phase 5 — Optional web dashboard

**Status:** deferred

The React app in `src/` remains a mock-data UI proof. Web persistence and feature parity should begin only after the Flutter core workflow is validated with real usage.
