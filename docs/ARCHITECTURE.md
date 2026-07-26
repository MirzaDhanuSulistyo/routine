# Routine — Application Architecture

**Status:** Awaiting approval  
**Last updated:** 2026-07-20

## Architecture goals

- **Local-First Privacy**: Process all personal life operations, daily observations, and pattern detection 100% on-device.
- **Strict Layering**: Enforce 3-Layer separation (**Plan**, **Record**, **Understand**) across domain entities and state management.
- **Andura UI Compliance**: Use Andura UI components and `linear-app` design tokens with dynamic Light & Dark mode support.
- **Sub-100ms Responsiveness**: Instant UI updates when logging events or viewing 7-day anomaly reports.

## System context

```
[Flutter UI] ---> [Notifier/State Controllers] ---> [Layer Use Cases]
                         |                                |
                         v                                v
                 [Andura UI (Linear)]          [Sliding Rule Engine]
                         |                                |
                         v                                v
            [Platform Notification Channel]    [SQLite Local Persistence]
```

## Module boundaries

| Module | Responsibilities | Depends on |
|---|---|---|
| `lib/presentation/` | UI screens, theme toggle, fast log modals, pattern reports | `andura_ui`, `lib/domain/` |
| `lib/domain/` | `RoutineItem`, `TimelineSlot`, `AnomalyPattern`, 3-layer business rules | None (Pure Dart) |
| `lib/data/` | SQLite database schema, repositories, secure storage | `sqflite`, `lib/domain/` |
| `lib/services/` | Local scheduled notifications, finite RSS briefing fetcher | `flutter_local_notifications`, `http` |

## State and data flow

`Widget UI` → `TimelineNotifier / FastLogController` → `RecordEventUseCase` → `RoutineRepository` → `SQLite Database`.  
On data change, `Evaluate7DayPatternsUseCase` triggers in background to update `PatternReportNotifier`.

## Domain model

- `RoutineItem`: Domain entity representing scheduled tasks, reminders, prep offsets, recurrence, or recorded observations. Numeric measurements are intentionally outside the core model.
- `RoutineOccurrence`: Per-date completion record for a recurring item, including event and recorded timestamps.
- `EventTimestamp`: Business value object tracking `scheduled_time`, `event_actual_time`, and `recorded_at_time`.
- `AnomalyPattern`: Entity capturing detected timing shifts (>30m delay), repeated notes (>=3 occurrences), or candidate co-occurrences.
- `TopicBriefing`: Entity containing 3 finite stories fetched for scheduled morning/evening updates.

## Persistence and migrations

- **Primary Store**: `sqflite` (SQLite database stored in app document directory).
- **Tables**: `items`, `item_occurrences`.
- **Migrations**: Versioned SQLite migrations preserve item templates while adding recurrence and occurrence history.

## Platform integration

- **iOS**: `UNUserNotificationCenter` for scheduled lead-time notifications; background fetch via `workmanager`.
- **Android**: `AlarmManager` for exact lead-time reminders; `NotificationChannel` support.

## Security and privacy

- All personal notes, timestamps, and anomaly reports remain stored locally on device.
- No remote analytics or cloud logging of personal events.

## Observability

- Local debug logging gated by `kDebugMode`.
- Structured error handling for database operations and RSS fetching without network leakage.

## Testing strategy

- **Unit**: Pure Dart domain rule engine, 7-day sliding window algorithms, lead-time calculations.
- **UI/Component**: Widget tests verifying `AnduraTheme.forSystem('linear-app')` rendering in Light & Dark mode.
- **Integration**: SQLite repository CRUD, per-occurrence completion, cascading deletion, and migration tests.

## Dependencies and rationale

| Dependency | Purpose | Why selected | Risk/exit plan |
|---|---|---|---|
| `andura_ui` | Design system tokens & components | Cross-platform contract requirement | Core dependency |
| `sqflite` | SQLite local database | Reliable cross-platform local SQL storage | Standard Flutter package |
| `flutter_local_notifications` | Timed reminders & lead-time alerts | Precise native notification scheduling | Native wrapper |

## Architecture decisions

1. **Local-First Rule Engine**: Run sliding 7-day anomaly detection locally in Dart isolate to ensure instant response and absolute privacy.
2. **Dual-Timestamp Schema**: Store both `event_time` (when it happened) and `recorded_at` (when user logged it) to capture late-logging behaviors accurately.

## Approval

- [ ] Architecture approved
- Approved by/date: Awaiting user approval (Stage 6 Gate)
