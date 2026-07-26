# Routine — Product Requirements Document (PRD)

**Status:** Draft | Awaiting approval  
**Last updated:** 2026-07-20  
**Version:** 1.0  

---

## 1. Executive Overview & Goals

**Routine** is a personal life operations and event intelligence assistant designed to help users remember time-sensitive responsibilities, stay informed on followed topics, record daily events, and discover unusual patterns across work, family, home, finances, and personal life.

### Key Motto & Value Proposition
> **"Remember it. Record it. Notice the pattern."**

### Core Goals
- **Remind**: Deliver time-sensitive alarms, preparation steps, maintenance schedules, and topic briefings across daily life domains.
- **Record**: Provide friction-free logging for actual completions, delays, and free-text observations, including past (backdated) and future entries.
- **Understand**: Generate weekly pattern and anomaly reports that highlight timing shifts, repeated observations, and potential correlations without false causal claims.
- **Privacy-First & Offline Ready**: Run core operations locally on-device without requiring external servers for habit data.

---

## 2. User Personas

1. **Alex — Multi-Role Operator**
   - **Needs**: Balances strict work hours (clock-in/out), family duties (son's math practice), home maintenance (car warming, plant watering), and financial deadlines (paying bills).
   - **Pain Point**: Forgets context between apps; misses subtle patterns like work overtime impacting family routines or sleep.
2. **Maya — Focused Information Consumer**
   - **Needs**: Follows niche topics (AI Tech, Local Politics, Market Trends) and wants a structured morning briefing without getting sucked into infinite social media feeds.
   - **Pain Point**: Social media platforms cause doomscrolling; RSS readers lack connection to daily routines.

---

## 3. Platform Capability Contract

| Platform | Core UI | Persistence | Alarms / Reminders | Topic Fetching |
|---|---|---|---|---|
| **Flutter (iOS & Android)** | Mobile App | Local SQLite / Isar | `UNUserNotificationCenter` / `AlarmManager` | Background HTTP / On-Notification Fetch |
| **React (Web)** | Dashboard | IndexedDB / LocalStorage | Web Notification API / Service Worker | Fetch API |

---

## 4. Scope Classification (P0 / P1 / P2)

### P0 (MVP — Critical path)
- **FR-1: Flexible Item Builder**: Create items categorized as Reminder, Task, Maintenance, Deadline, Preparation, Topic Briefing, or Log/Observation.
- **FR-2: Unified Chronological Timeline**: View planned and actual items grouped by time of day (Morning, Afternoon, Evening) for present, past, and future dates.
- **FR-3: Local Alarms & Action Notifications**: Trigger precise local alarms and notifications with actionable buttons (*Done, Snooze, Add Note*).
- **FR-4: Fast Event & Dual-Timestamp Logging**: Record actual outcomes with distinct `event_timestamp` (when it happened) and `recorded_at_timestamp` (when entered).
- **FR-5: Scheduled Topic Briefings**: Deliver finite news & social updates (Reddit, Bluesky, RSS) at user-configured times (e.g. Morning Brief at 07:00 AM).
- **FR-6: Weekly Pattern & Anomaly Engine**: Evaluate local database queries over 7-day windows to surface timing shifts, repeated notes, and candidate correlations.

### P1 (Should Have)
- Category tagging (Work, Family, Home, Finance, Personal).
- Search & filter timeline by category or item status.
- Local JSON database export/backup.

### P2 (Nice to Have / Future)
- Photo attachment for log entries.
- Optional encrypted cloud sync.

---

## 5. Functional Requirements & Acceptance Criteria

### FR-1: Flexible Item Primitive
- **Description**: The system must allow users to create a unified `Item` object with customizable behavior.
- **Acceptance Criteria**:
  - [ ] User can specify Title, Category (Work, Family, Home, Finance, Personal), Schedule Type (Fixed time, Recurring, Relative offset, Deadline).
  - [ ] User can attach a relative preparation trigger (e.g. "Warm car 10 mins before 06:40 AM departure").
  - [ ] System saves items locally with unique IDs.

### FR-2: Unified Chronological Timeline
- **Description**: Present all planned items, completed logs, topic briefs, and observations in a single timeline.
- **Acceptance Criteria**:
  - [ ] Timeline displays items in chronological order split by Morning (<12:00), Afternoon (12:00–18:00), and Evening (>18:00).
  - [ ] User can navigate to past dates (backdated view) and future dates (upcoming plan view).
  - [ ] Items reflect clear visual indicators for status: *Scheduled, Completed, Late, Skipped, Observation Logged*.

### FR-3: Local Alarms & Actionable Reminders
- **Description**: Trigger local OS notifications/alarms for scheduled items.
- **Acceptance Criteria**:
  - [ ] At scheduled time, system triggers local notification with custom alarm audio (if configured).
  - [ ] Notification presents interactive actions: `Mark Done`, `Snooze 10m`, `Add Note`.
  - [ ] Action execution immediately updates local item status without requiring full app navigation.

### FR-4: Fast Event & Dual-Timestamp Logging
- **Description**: Capture actual outcomes with accurate event timing vs entry timing.
- **Acceptance Criteria**:
  - [ ] User can log an entry for Today, Yesterday (past), or Tomorrow (future).
  - [ ] Database stores both `event_timestamp` (user-chosen event time) and `recorded_at_timestamp` (system clock time).
  - [ ] Users can enter free-text observations ("Car made a grinding noise") without requiring manual numeric entry.

### FR-5: Scheduled Topic Briefings
- **Description**: Deliver finite topic updates at user-specified times.
- **Acceptance Criteria**:
  - [ ] User can select followed topics (e.g. "Tech & AI", "Finance", custom search query) and sources (News RSS, Reddit, Bluesky).
  - [ ] At configured brief time (e.g. 07:00 AM), system compiles up to 3–5 top stories/discussions.
  - [ ] Briefing is displayed as a finite card in the timeline—no infinite scrolling.

### FR-6: Weekly Pattern & Anomaly Engine
- **Description**: Analyze sliding 7-day event logs to detect deviations and correlations.
- **Acceptance Criteria**:
  - [ ] System detects when a recurring item is completed >15 minutes late on 3+ occasions.
  - [ ] System highlights repeated keyword observations (e.g. "car noise" entered 2x in 7 days).
  - [ ] System detects co-occurring events (e.g. "Overtime clock-out coincided with missed math practice on 3 of last 4 Tuesdays").
  - [ ] Insights explicitly state: *"This pattern was observed..."* avoiding definitive causal assertions.
  - [ ] Insights use automatically captured timing, completion, delay, skip, snooze, and observation history rather than requiring daily numeric entry.

---

## 6. Information Architecture & Data Model

```
[ Unified Timeline ]
       ├── [ Date Selector: Past / Today / Future ]
       ├── [ Morning Section ] -> (Warm Car Prep, Topic Briefing, Clock In Alarm)
       ├── [ Afternoon Section ] -> (Clock Out Reminder, Plant Check)
       └── [ Evening Section ] -> (Son's Math Practice, Daily Observation Log)

[ Pattern Report Screen ]
       ├── [ Completion Rate Trends ]
       ├── [ Timing Shift Anomalies ]
       └── [ Candidate Correlations ]
```

### Core Schema (`Item` Entity)
- `id`: string (UUID)
- `title`: string
- `item_type`: enum (`reminder`, `task`, `maintenance`, `deadline`, `preparation`, `briefing`, `log`)
- `category`: enum (`work`, `family`, `home`, `finance`, `personal`)
- `scheduled_timestamp`: timestamp (nullable)
- `event_timestamp`: timestamp (time event occurred)
- `recorded_at_timestamp`: timestamp (time entry created in DB)
- `status`: enum (`scheduled`, `completed`, `late`, `skipped`, `logged`)
- `notes`: text (nullable)
- `topic_sources`: list of strings (for briefing items)

---

## 7. Non-Functional Requirements

- **Performance**: Local timeline load time < 100ms for 1,000 items.
- **Reliability**: 100% offline functionality for timeline viewing, item creation, and logging.
- **Design System**: Use Andura UI (`packages/flutter` / `packages/react`) components and tokens for layout, buttons, inputs, modals, and typography.
- **Battery & Memory**: Background alarm scheduling must consume negligible standby power (< 1% daily battery drop).

---

## 8. Risks & Mitigation

| Risk | Impact | Mitigation |
|---|---|---|
| OS revokes exact alarm permissions | High | Detect permission loss on launch and prompt user with guide to re-enable in OS Settings. |
| News API rate limits or network failures | Medium | Cache last fetched topic digest locally; display cached content with offline banner if network is down. |
| Misleading pattern correlations | Medium | Format anomaly findings with cautious language ("Observed relationship") rather than causal claims. |

---

## 9. Definition of Done (DoD)

1. All P0 functional requirements implemented and passing automated tests.
2. Formatted with standard linters and Andura UI design system tokens.
3. Verified on target simulators/browsers.
4. `docs/STATUS.md` updated.

---

## 10. Approval

- [ ] Product Requirements Document approved
- Approved by/date: Pending user review
