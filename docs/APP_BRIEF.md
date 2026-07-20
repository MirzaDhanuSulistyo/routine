# Routine — App brief

**Status:** Draft | Awaiting approval  
**Last updated:** 2026-07-20

## Product idea

Routine is a **personal life operations & event intelligence assistant** that helps users remember time-sensitive responsibilities, stay informed on followed topics, record daily events, and discover unusual patterns across work, family, home, finances, and personal life. 

Rather than a basic habit tracker or alarm app, Routine unifies **Plan**, **Record**, and **Understand** into a single chronological timeline driven by flexible "Items".

## Primary user

Individuals managing multi-faceted lives (work commitments like clock-in/out, family responsibilities like kids' study, home maintenance, finances, and self-care) who want a unified assistant to track what should happen, record what actually happened, and gain insights into patterns and anomalies over time.

## Problem

Existing tools fragment life management into single-purpose silos:
- Alarm/reminder apps alert on schedules but cannot record actual outcomes or note observations.
- Habit trackers enforce binary streak goals without accounting for context, delays, or irregular events.
- Journaling apps capture notes without integrating timed commitments or actionable deadlines.
- News aggregators provide endless feeds detached from daily life operations.

Users struggle to connect cause and effect across days (e.g., late clock-outs leading to missed family routines, or weather changes affecting home maintenance).

## Core feature

**Unified Chronological Timeline & 3-Layer Life Operations Model**:

1. **Plan (Expected Events)**: Flexible Items combining Reminders, Tasks, Maintenance, Deadlines, Contextual Preparations, and Scheduled Topic Briefings.
2. **Record (Actual Events & Log Entries)**: Fast logging of actual completions, deviations, free-text observations, numeric measurements, and backdated/future-dated logs (separating `event_timestamp` from `recorded_at_timestamp`).
3. **Understand (Pattern & Anomaly Intelligence)**: Rule-based pattern detection highlighting repeated exceptions, timing shifts, missed routines, and potential correlations (e.g., "Late clock-outs on Tuesdays coincided with missed study sessions").

## Core Product Primitive: Flexible "Item"

All entries exist on a single timeline and adopt specific behaviors:
- **Reminder**: Clock-in (08:00), Clock-out (17:00)
- **Task**: Help son practice math (18:30)
- **Maintenance**: Water plants every 3 days
- **Deadline**: Pay electricity bill by July 25
- **Preparation**: Warm the car 10 minutes before leaving
- **Topic Briefing**: 3 concise updates on AI and local politics at 07:00 Morning Brief
- **Log Prompt / Observation**: Record unusual events, symptoms, or notes (e.g., "Car made an unusual noise")
- **Measurement**: Log values (e.g., Slept 5.5 hours)

## Value proposition

**"Remember it. Record it. Notice the pattern."**

Instead of just checking off tasks, Routine bridges planned commitments with actual real-world logs and provides weekly pattern reports. It moves users from passive task management to proactive life operational intelligence.

## Target platforms

- **Primary**: Mobile App (Flutter / iOS & Android) with local notifications, background alarm support, and fast event logging.
- **Secondary**: Cross-platform Web dashboard (React / Andura UI) for routine setup, detailed timeline review, and pattern analytics.

## First-release outcome (5 Core MVP Capabilities)

A user can:
1. **Set Flexible Reminders & Schedule**: Create fixed-time, recurring, deadline-based, or contextual preparation items.
2. **View Unified Chronological Timeline**: Manage work, family, home, finance, and personal items together in a daily timeline (Morning, Afternoon, Evening).
3. **Fast Event & Observation Logging**: Record what actually happened (Done, Late, Skipped, Note, Number, Photo) with support for present, past (backdated), and future-dated entries.
4. **Scheduled Topic Briefing**: Receive a finite daily news/info update on followed topics (e.g., Morning Brief at 07:00) embedded directly into the timeline.
5. **Weekly Pattern & Anomaly Report**: Review rule-based summaries highlighting missed items, timing shifts, repeated observations, and candidate correlations without false causal claims.

## Constraints

- **Design system**: Andura UI (`packages/flutter` and `packages/react`), using shared tokens and semantic components.
- **Distribution**: iOS App Store / Google Play Store for mobile app; web hosting for dashboard.
- **Privacy/security**: Local-first logging storage for sensitive personal events and habit notes; minimal external server footprint.
- **Technical**: Mobile background execution policies (iOS Background Tasks, Android AlarmManager / Exact Alarms) for precise alarms and brief notifications.

## Non-goals

- Complex project management / gantt charts (V1 focuses on personal life operations).
- Unlimited open-ended news reader or RSS manager (V1 provides finite, topic-focused digests).
- Full social network or public feed sharing (V1 is personal and private).
- Black-box AI recommendations that make unfounded causal leaps (V1 relies on transparent rule-based anomaly & correlation detection).

## Assumptions

- Users will engage with fast 1-tap logging prompts ("Was anything unusual today?") if friction is minimal.
- Separating `event_timestamp` from `recorded_at_timestamp` provides accurate historical data for pattern analysis.

## Open decisions

1. **Primary Target Framework for Proof/MVP**: Flutter (mobile-first for native alarms & notifications) or React (web-first prototype)?
2. **Pattern Intelligence Storage**: Local client-side rule evaluation vs. encrypted cloud engine?

## Approval

- [ ] Product direction approved
- Approved by/date: Pending user review
