# Routine — Feasibility assessment

**Status:** Draft | Awaiting approval  
**Last updated:** 2026-07-20

## Executive assessment

The core capabilities of Routine—flexible item scheduling, unified timeline, fast logging, dual timestamp tracking (`event_timestamp` vs `recorded_at_timestamp`), topic briefing, and rule-based anomaly detection—are fully technically feasible. 

Platform constraints primarily affect **high-precision alarm playback** on iOS (Critical Alerts require Apple entitlement approval; standard local notifications work universally) and **background pre-fetching of news summaries** prior to morning alarms (iOS limits exact-time background network operations; mitigated by server push or on-demand fetch).

## Capability matrix

| Capability | Platform | Status | API/mechanism | Permission/entitlement | Limitations | Fallback |
|---|---|---|---|---|---|---|
| Exact Time Alarms & Task Reminders | iOS | Supported / Permission-required | `UNUserNotificationCenter` | Notification permission | Critical Alert entitlement required for bypassing Mute switch. | Standard high-priority local notifications with custom sound & snooze actions. |
| Exact Time Alarms & Task Reminders | Android | Supported / Permission-required | `AlarmManager`, `NotificationManager` | `SCHEDULE_EXACT_ALARM`, `POST_NOTIFICATIONS` | Android 12+ exact alarm permission restrictions. | Prompt user for Exact Alarm permission or fallback to `WorkManager` coarse timing. |
| Contextual Preparation Alarms (e.g., 10m relative offset) | All | Supported | Local offset math + Notification APIs | Same as Alarms | Calculated ahead of time relative to target event. | Standard notification at calculated offset timestamp. |
| Topic Briefing Delivery | iOS | Limited (Background Fetch) | `BGAppRefreshTask` / Remote Push | Background Refresh permission | iOS background execution timing is OS-controlled, not guaranteed exact. | Fetch news digest on demand when user opens notification, or push via APNs. |
| Topic Briefing Delivery | Android | Supported | `WorkManager` / FCM | `INTERNET`, `WAKE_LOCK` | Battery saver mode may defer background network calls. | Fetch on notification open or fallback to last cached digest. |
| Social Media Topic Feeds (X, Reddit, Bluesky) | All | Supported / Platform-specific limits | Reddit JSON API, Bluesky AT Protocol API, X API v2 / Nitter RSS | `INTERNET` | Official X (Twitter) API requires paid tier ($100+/mo); Bluesky & Reddit APIs are free/open. | Use open networks (Reddit, Bluesky, RSS) and web search APIs; optional X API proxy if configured. |
| Dual Timestamp Event & Observation Logging | All | Supported | Local DB (SQLite / Isar / IndexedDB) | None | Must store `event_timestamp` separately from `recorded_at_timestamp`. | Native local database schema enforcement. |
| Rule-Based Pattern & Anomaly Engine | All | Supported | In-memory / SQL sliding window queries | None | Complex statistical calculations on large histories can affect UI thread if unindexed. | Run pattern queries asynchronously on background thread / web worker. |

## Background execution

- **iOS**: Standard local notifications do not require background execution time. However, background news pre-fetching relies on `BGAppRefreshTask` (opportunistic) or APNs silent push notifications.
- **Android**: `AlarmManager` with `setExactAndAllowWhileIdle` wakes the system for scheduled reminders even in Doze mode. `WorkManager` manages periodic background topic sync.
- **Web**: Service Worker Push API handles notifications when tab is inactive; active tab handles live timer countdowns.

## Data quality and accuracy

- **Separation of Timestamps**: Crucial for accuracy. `event_timestamp` records when an event occurred (allows backdating/future-dating), while `recorded_at_timestamp` records when the user entered the log.
- **Anomaly Detection False Positives**: Statistical correlations (e.g. "Late clock-out on Tuesdays correlates with missed math practice") must be presented as **observed patterns / potential relationships**, never as definitive causal claims.

## Privacy and security

- **Personal Life Event Logs**: Notes, health/sleep numbers, and daily observations are stored in local device storage (`SQLite` / `Isar` with SQLCipher encryption optional).
- **Topic Briefings**: Topic preferences (e.g., "AI Technology", "Finance") are sent anonymously to news API endpoints without attaching personal routine or schedule data.

## Distribution and policy

- **App Store & Google Play**: Standard productivity app policies apply. No restricted entitlements are strictly required (standard Local Notifications & Exact Alarm permissions are supported with clear user justification).
- **Background Execution Disclosures**: Play Store requires rationale for `USE_EXACT_ALARM` permission (justified by user-scheduled clock-in/out alarms and reminders).

## Prototype gates

1. **Exact Alarm & Local Notification Execution**: Prototype local notification triggers with custom action buttons (Done, Snooze, Note) across iOS, Android, and Web.
2. **Dual Timestamp Storage & Querying**: Verify that backdated entries properly update sliding 7-day pattern windows without corrupting historical sequence orders.

## Recommended scope

### Include

- Flexible Item builder (Reminders, Tasks, Maintenance, Deadlines, Preparation, Briefing, Log/Observation, Measurement).
- Unified Chronological Timeline (Morning, Afternoon, Evening).
- Local Notifications & Actionable Alarms.
- Fast Event Logging with Present, Past (backdated), and Future support.
- Configurable Topic Briefings delivered at scheduled times (e.g. Morning Brief at 07:00 AM).
- Rule-based Weekly Pattern & Anomaly Report (slips, repeated notes, timing shifts, correlations).

### Limit or defer

- **Full-Screen Audio Alarm Overlay on iOS**: Standard high-priority notifications with custom sound used instead of requesting Apple Critical Alerts entitlement.
- **Automatic Background News Sync on Low Battery**: Defer live news network calls to notification tap when battery saver is active.

### Exclude

- Heavy social feed sharing and public routine publishing.
- Black-box AI generative story creation for anomalies (V1 uses transparent rule engine).

## Sources

- Apple Developer Documentation: [UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications), [Background Tasks](https://developer.apple.com/documentation/backgroundtasks) (Accessed 2026-07-20)
- Android Developers Documentation: [AlarmManager](https://developer.android.com/reference/android/app/AlarmManager), [Exact Alarms](https://developer.android.com/about/versions/14/changes/exact-alarms) (Accessed 2026-07-20)

## Approval

- [ ] Realistic scope approved
- Approved by/date: Pending user review
