# Routine — Screen inventory

**Status:** Draft | Awaiting approval  
**Last updated:** 2026-07-20

## Navigation model

Routine uses a bottom tab bar navigation on mobile (and sidebar on web/tablet) anchored by the **Unified Timeline (Home)**. 

- **Primary Tabs**:
  1. **Timeline** (`routine://timeline`) — Chronological daily view (Plan & Record).
  2. **Fast Log** (`routine://log/fast`) — Quick action sheet / modal to record observations and backdated/future events.
  3. **Pattern Report** (`routine://insights`) — Weekly anomaly & correlation insights (Understand).
  4. **Settings** (`routine://settings`) — Topic preferences, alarm options, data export.
- **Modal / Secondary Routes**:
  - **Item Builder** (`routine://item/create`, `routine://item/edit/:id`) — Modal workflow for creating/editing items.
  - **Topic Briefing Detail** (`routine://briefing/:id`) — Detailed reader for topic digest stories.
- **System Surfaces**:
  - **Interactive Local Notification**: Lock screen/banner with `Done`, `Snooze`, `Add Note`.

## Screen inventory

| # | Screen | Purpose | Primary entry | Platforms | Priority | Specification |
|---|---|---|---|---|---|---|
| 1 | Timeline (Home) | Unified chronological daily plan, logs, and topic briefs (Morning/Afternoon/Evening) | Bottom Tab / Launch | All | P0 | [`01_TIMELINE.md`](01_TIMELINE.md) |
| 2 | Item Builder & Editor | Create or edit flexible items (Reminder, Task, Maintenance, Deadline, Preparation, Briefing, Observation) | Floating Action Button / Modal | All | P0 | [`02_ITEM_BUILDER.md`](02_ITEM_BUILDER.md) |
| 3 | Fast Observation Logger | 1-tap logging for present, backdated, or future notes and status | Navigation Bar + / Quick Action | All | P0 | [`03_FAST_LOG.md`](03_FAST_LOG.md) |
| 4 | Topic Briefing Reader | Read finite top 3–5 news & social updates for followed topics | Timeline Card / Notification Tap | All | P0 | [`04_TOPIC_BRIEFING.md`](04_TOPIC_BRIEFING.md) |
| 5 | Pattern & Anomaly Report | Weekly report highlighting timing shifts, repeated notes, and candidate correlations | Bottom Tab | All | P0 | [`05_PATTERN_REPORT.md`](05_PATTERN_REPORT.md) |
| 6 | Settings & Topic Manager | Manage followed topics (Reddit/Bluesky/RSS), alarm sounds, and database exports | Bottom Tab / Header Icon | All | P1 | [`06_SETTINGS.md`](06_SETTINGS.md) |

## System surfaces

| Surface | Purpose | Tap/deep-link destination | Platforms |
|---|---|---|---|
| Interactive Local Notification | Alarm alert with quick actions (`Done`, `Snooze`, `Note`) | `routine://timeline?item_id=<id>` | iOS / Android / Web |
| Morning Brief Push Banner | Direct trigger for Morning Topic Digest | `routine://briefing/<id>` | iOS / Android |

## Global states

- **First run/onboarding**: Welcome guide introducing the 3-Layer Model (Plan, Record, Understand), requesting notification permissions, and setting up initial topics (Tech, Finance, Health, World).
- **Loading and refresh**: Skeleton loaders for timeline items and topic digests.
- **Empty data**: Empty state encouraging creation of the first item or routine.
- **Offline/stale/partial data**: Timeline and logs function 100% offline; stale indicator shown on topic briefs if internet is unavailable.
- **Permission denied**: Banner explaining how to enable Exact Alarm & Notification permissions in OS settings.

## Requirement coverage

| PRD requirement | Screen/system surface |
|---|---|
| FR-1: Flexible Item Builder | SCR-02 (Item Builder) |
| FR-2: Unified Chronological Timeline | SCR-01 (Timeline) |
| FR-3: Local Alarms & Action Notifications | System Surface (Interactive Notification) & SCR-01 |
| FR-4: Fast Event & Dual-Timestamp Logging | SCR-03 (Fast Logger) & SCR-01 |
| FR-5: Scheduled Topic Briefings | SCR-04 (Topic Briefing Reader) & SCR-01 |
| FR-6: Weekly Pattern & Anomaly Engine | SCR-05 (Pattern Report) |

## Approval

- [ ] Navigation and screen scope approved
- Approved by/date: Pending user review
