# Routine — Delivery Roadmap

**Status:** Awaiting approval  
**Last updated:** 2026-07-20

## Delivery principles

- Deliver independently testable vertical slices.
- Preserve local-first privacy and 3-Layer Model principles.
- Do not treat mock data as a completed integration.

## Phase 1 — Local SQLite Persistence & Timeline Engine

**Status:** not-started

### Outcome
A user can view daily scheduled items, log fast observations with dual timestamps (`event_time`, `recorded_at`), mark items complete, and persist changes across app restarts.

### Included
- PRD requirements: `REQ-F1` (3-Layer Model), `REQ-F2` (Dual Timestamping), `REQ-F4` (Fast Logging)
- Screens: Timeline View, Fast Event Logger Sheet

### Implementation
- Setup `sqflite` database schema (`items`, `logs`).
- Implement `RoutineRepository` SQLite data source.
- Connect `_showFastLogSheet` to persist logs to local database.

### Validation
```sh
flutter analyze && flutter test
```
Target demonstration: iPhone 17 simulator log entry created, persisted in SQLite, and rendered after app restart.

---

## Phase 2 — Lead-Time Reminders & Finite Topic Briefings

**Status:** not-started

### Outcome
A user receives lead-time offset alerts prior to scheduled departure times (e.g. 10m engine prep) and views finite 3-story morning/evening briefings.

### Included
- PRD requirements: `REQ-F3` (Lead-Time Buffer Engine), `REQ-F6` (Finite Scheduled Briefings)
- Screens: Timeline View, Briefing Modal Dialog

### Implementation
- Integrate `flutter_local_notifications` for lead-time reminders.
- Build briefing parser for scheduled tech/market updates.

---

## Phase 3 — 7-Day Sliding Window Rule Engine & Pattern Report

**Status:** not-started

### Outcome
Routine automatically analyzes 7 days of logs to detect timing shifts (>30m late clock-out), repeated notes (>=3 occurrences), and co-occurring events.

### Included
- PRD requirements: `REQ-F5` (7-Day Pattern & Anomaly Detection)
- Screens: Pattern Report View

### Implementation
- Implement sliding 7-day rule engine algorithm.
- Render detected anomaly cards with evidence snippets in Pattern Report screen.

---

## Phase 4 — Topic Subscriptions & Settings Customization

**Status:** not-started

### Outcome
User can customize briefing topics, configure notification schedules, toggle Light/Dark mode preferences, and export local data.

### Included
- PRD requirements: `REQ-F6`, `REQ-N1` (Local Storage & Data Portability)
- Screens: Settings Screen

---

## Approval

- [ ] Architecture and phase order approved
- Approved by/date: Awaiting user approval (Stage 6 Gate)
