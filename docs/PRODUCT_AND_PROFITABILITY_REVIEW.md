# Routine — Product Improvement & Profitability Review

**Status:** Draft implementation plan  
**Reviewed:** 2026-07-26  
**Scope:** Flutter mobile app in the current repository

> This document complements `docs/ROADMAP.md`. The existing roadmap records delivered technical slices; this plan defines the critical path from the current beta to a validated, monetizable product.

## 1. Executive assessment

Routine has a credible technical beta and a promising product thesis:

> Help people compare what they planned with what actually happened, then show explainable patterns they can act on.

The local-first approach, SQLite persistence, recurring occurrences, dual timestamps, and actionable notifications are useful foundations. At review time:

- `flutter analyze` passes.
- All 19 automated tests pass.
- Core timeline, logging, recurrence, editing, deletion, and native reminders work at beta level.
- The application has no billing, paywall, advertising, or other direct monetization implementation.

The application is therefore **not demonstrably profitable from the repository alone**. Actual profitability cannot be determined without installs, active users, retention, conversion, revenue, acquisition cost, support cost, and development cost.

Commercial potential exists, especially because a local-first app can have low infrastructure costs. However, the current product is too broad and its main differentiator—the pattern engine—is still a prototype. In its present form, users may perceive Routine as another reminders or habit-tracking app, a category with many free alternatives.

### Overall verdict

- **Technical foundation:** promising beta
- **Commercial readiness:** low
- **Monetization readiness:** not implemented
- **Best commercial opportunity:** explainable plan-versus-actual insights for a narrowly defined user group
- **Largest risk:** adding more features before proving retention and willingness to pay

## 2. What should be improved

### 2.1 Make the insight engine the product moat

`lib/data/anomaly_engine.dart` currently evaluates simple per-item delays and note text. It does not yet implement the promised sliding seven-day analysis, recurring occurrence history, repeated observations, or candidate co-occurrences. It also returns canned fallback patterns when no real evidence exists.

Improvements:

- Analyze `item_occurrences`, not only top-level item templates.
- Use explicit seven-day and longer comparison windows.
- Detect repeated late, missed, skipped, and rescheduled events.
- Group repeated observations with deterministic, explainable rules.
- Require minimum sample sizes before showing a relationship.
- Attach every insight to the exact records used as evidence.
- Never display fabricated fallback patterns as user findings.
- Turn findings into actions such as “Move this reminder 20 minutes later?”

### 2.2 Narrow the initial product

The current scope combines reminders, habit tracking, event logging, measurements, maintenance, analytics, and news briefings. That creates implementation and marketing complexity without proving that users want the combination.

The recommended initial wedge is:

> People with changing schedules—such as shift workers or working parents—who need to understand why important routines repeatedly happen late or are missed.

Before implementation continues, validate this audience or select another equally specific audience. The topic briefing should remain outside the critical path unless interviews show that it materially improves retention or paid conversion.

### 2.3 Correct the event and status model

The current model primarily uses `isCompleted`. It cannot accurately represent the product promise.

Required states:

- scheduled
- completed
- late
- skipped
- rescheduled
- logged

Every completion or status change should capture:

- planned timestamp
- actual event timestamp
- recorded-at timestamp
- occurrence date
- optional note
- optional measurement and unit

Non-recurring items must capture completion timestamps just as recurring items do. Fast Log should support an exact event date and time, meaningful units, and optional attachment to an existing routine.

### 2.4 Simplify the user experience

The current screenshots and presentation expose implementation language and too much metadata in the primary timeline.

Improvements:

- Show title, planned time, status, and one primary action on a collapsed card.
- Move event/recorded timestamps and long notes into an expandable detail view.
- Provide one consistent quick-add or quick-log action.
- Add a Today shortcut and compact week/date navigation.
- Add search and filters for category, status, and type.
- Replace “Pattern Report” with friendlier language such as “Weekly Insights.”
- Replace terms such as “Dual Timestamping,” “SQLite Database,” and “Anomaly Engine” with user outcomes.
- Use progressive disclosure in the item builder so each item type only asks relevant questions.

### 2.5 Improve onboarding, trust, and release quality

The app currently inserts sample activity automatically into an empty database. A user who deletes everything can receive sample data again, and fabricated activity may appear to be their own history.

Improvements:

- Start with a real empty state and optional templates or an explicitly labeled sample mode.
- Request notification permissions only after explaining the benefit.
- Add export/import, secure backup options, and clear deletion controls.
- Confirm destructive reset operations.
- Persist appearance and other preferences.
- Publish a privacy policy and accurately describe whether the local database is encrypted.
- Add production signing, CI, accessibility testing, failure states, and real-device integration tests.

### 2.6 Resolve known implementation risks

- `lib/main.dart` is approximately 2,091 lines and should be split into screens, controllers, and reusable components.
- Snoozing uses the same notification ID as the recurring reminder and can replace the future recurring schedule.
- Android release builds currently use debug signing.
- The production Android manifest does not currently include internet access for a future live briefing integration.
- The briefing service returns fixed demo stories rather than live cached content.
- No billing or entitlement system exists.
- No product metrics exist, making retention and profitability impossible to evaluate.

## 3. Phase-by-phase implementation plan

### Critical path

```text
Phase 0: Validate scope
    ↓
Phase 1: Correct the data model
    ↓
Phase 2: Rebuild the core user loop
    ↓
Phase 3: Harden reminders
    ↓
Phase 4: Build real weekly insights
    ↓
Phase 5: Add trust and beta readiness
    ↓
Phase 6: Run a measured beta
    ↓
Phase 7: Add monetization and release
    ↓
Phase 8: Consider expansion only after validation
```

Do not advance solely because tasks are coded. Each phase has an exit gate that should be satisfied first.

---

## Phase 0 — Validate the audience and scope

**Objective:** Confirm who has the problem, how severe it is, and which outcome they will pay for.

**Indicative duration:** 1–2 weeks

### Work

- [ ] Interview at least 15–20 people from one proposed audience.
- [ ] Document their current workaround, frequency of the problem, consequences, and previous purchases.
- [ ] Test the positioning “plan versus actual, with explainable weekly insights.”
- [ ] Show the existing prototype and observe users completing the core workflow.
- [ ] Ask for a real beta commitment rather than only positive opinions.
- [ ] Test a concrete price range, such as $29.99–$39.99 per year.
- [ ] Decide whether topic briefings solve a validated problem or should be deferred.
- [ ] Define the activation event and the primary retention event.

### Deliverables

- One primary user profile
- One primary job-to-be-done
- A one-sentence value proposition
- A list of explicitly deferred features
- Beta recruitment list
- Initial success metrics

### Exit gate

Proceed only when at least 10 target users commit to using a four-week beta and several can clearly explain why plan-versus-actual insights would change their behavior. If that does not happen, revise the audience or proposition before adding features.

---

## Phase 1 — Correct the event, occurrence, and status foundation

**Objective:** Ensure all future UX and analytics are built on accurate history.

**Indicative duration:** 1–2 weeks

### Work

- [ ] Replace stringly typed item types, categories, statuses, and recurrence rules with validated domain values or enums.
- [ ] Replace the completion-only model with explicit occurrence status.
- [ ] Store an occurrence for both recurring and non-recurring scheduled items.
- [ ] Store planned, actual-event, and recorded-at timestamps consistently.
- [ ] Support completed, late, skipped, rescheduled, and logged outcomes.
- [ ] Define how un-completing or correcting an occurrence affects history.
- [ ] Add exact event date/time and user-selected units to Fast Log.
- [ ] Allow a log to reference an existing item or occurrence.
- [ ] Add repository range queries for seven-day and longer windows.
- [ ] Centralize recurrence projection so UI and repository code do not duplicate the rules.
- [ ] Add a versioned SQLite migration that preserves all current user records.
- [ ] Stop automatically restoring seed data after a user intentionally reaches zero items.
- [ ] Add database constraints and indexes for occurrence date, item ID, and status.

### Primary code areas

- `lib/domain/routine_item.dart`
- `lib/domain/routine_occurrence.dart`
- `lib/data/database_helper.dart`
- `lib/data/routine_repository.dart`
- `lib/main.dart` completion and Fast Log flows

### Tests

- [ ] Migration from the current schema without data loss
- [ ] One-time and recurring occurrence creation
- [ ] Every supported status transition
- [ ] Backdated and future-dated event timestamps
- [ ] Timezone and day-boundary behavior
- [ ] Empty database remains empty
- [ ] Range query correctness and ordering

### Exit gate

Every status action must produce deterministic, queryable occurrence history, and all migration/repository tests must pass without losing existing records.

---

## Phase 2 — Rebuild the core Plan → Record loop

**Objective:** Make daily use fast, understandable, and free of developer-facing concepts.

**Indicative duration:** 2–3 weeks

### Work

- [ ] Split `lib/main.dart` into presentation screens, application controllers, and reusable widgets.
- [ ] Add first-run onboarding with a clear promise and optional routine templates.
- [ ] Replace automatic demo records with an explicitly labeled sample mode.
- [ ] Redesign timeline cards to show only essential information by default.
- [ ] Add item detail and occurrence history views.
- [ ] Add one-tap Done, Late, Skip, and Add Note actions.
- [ ] Add Today, compact week navigation, date picker, search, and filters.
- [ ] Redesign Fast Log with exact date/time, type, unit, category, and optional linked routine.
- [ ] Use progressive fields in the item builder for reminder, maintenance, deadline, measurement, and other behaviors.
- [ ] Persist theme and user preferences.
- [ ] Add useful empty, loading, error, and permission-denied states.
- [ ] Remove internal terminology from consumer-facing screens.
- [ ] Validate dynamic text, screen readers, contrast, touch targets, and keyboard behavior.

### Suggested module structure

```text
lib/
├── application/
│   ├── timeline_controller.dart
│   ├── item_editor_controller.dart
│   └── insights_controller.dart
├── presentation/
│   ├── onboarding/
│   ├── timeline/
│   ├── item_builder/
│   ├── fast_log/
│   ├── insights/
│   └── settings/
├── domain/
├── data/
└── services/
```

### Exit gate

In usability testing, at least 80% of target users should be able to create a routine, enable a reminder, record an outcome, and find its history without assistance. The UI must remain usable with large text and on supported phone sizes.

---

## Phase 3 — Harden reminder reliability

**Objective:** Make reminders dependable enough to support daily retention.

**Indicative duration:** 1–2 weeks

### Work

- [ ] Give snoozed notifications a separate ID so they do not replace recurring schedules.
- [ ] Reconcile pending OS notifications with database state at launch.
- [ ] Ensure editing, deleting, disabling, completing, and resetting items correctly reschedules or cancels notifications.
- [ ] Record notification actions against the correct occurrence for every recurrence type.
- [ ] Open Add Note with the triggering item and occurrence already selected.
- [ ] Handle app launch from notification actions and deep-link to the correct screen.
- [ ] Show actual notification and exact-alarm permission status.
- [ ] Provide an inexact fallback and explain reduced precision to the user.
- [ ] Test daylight-saving transitions, timezone changes, midnight offsets, reboot, and app upgrades.
- [ ] Review Google Play exact-alarm policy before release.

### Exit gate

Complete a real-device test matrix on at least one supported iOS device and two supported Android versions. One-time, daily, weekly, preparation, snooze, done, and note actions must remain correct after restart and timezone changes.

---

## Phase 4 — Implement explainable weekly insights

**Objective:** Deliver the differentiated outcome users may pay for.

**Indicative duration:** 2–3 weeks

### Work

- [ ] Replace item-template analysis with occurrence range analysis.
- [ ] Implement an explicit seven-day reporting period with a selectable end date.
- [ ] Add comparison against a prior period when enough history exists.
- [ ] Detect repeated timing shifts using documented thresholds and minimum samples.
- [ ] Detect skipped/missed trends.
- [ ] Detect repeated observations with deterministic text normalization.
- [ ] Detect candidate co-occurrences only when minimum opportunity and evidence counts are met.
- [ ] Use cautious language and never imply causation.
- [ ] Return a structured insight object containing rule ID, period, sample size, evidence occurrence IDs, summary, and possible action.
- [ ] Show “Not enough history yet” instead of canned findings.
- [ ] Let users inspect the evidence behind every card.
- [ ] Add actions such as adjusting a reminder, changing preparation time, or dismissing a finding.
- [ ] Keep processing on-device and move expensive work off the UI thread if required.

### Initial deterministic rules

1. **Timing shift:** at least three comparable occurrences in seven days and a delay above the defined threshold.
2. **Repeated observation:** a normalized term or phrase appears in at least two or three separate events.
3. **Missed routine trend:** a recurring item is skipped or left incomplete on multiple eligible occurrences.
4. **Candidate co-occurrence:** two event classes coincide repeatedly with a minimum sample size and explicit evidence count.

Thresholds must be product decisions documented in code and tests, not hidden magic values.

### Tests

- [ ] Multi-day fixtures for each rule
- [ ] Insufficient-data fixtures
- [ ] False-positive and cross-midnight cases
- [ ] Recurring and non-recurring event coverage
- [ ] Every generated claim maps to evidence
- [ ] Performance test with at least 1,000 occurrences

### Exit gate

No insight may appear without real supporting records. Beta reviewers must be able to understand why each insight was generated and identify at least one useful action from it.

---

## Phase 5 — Add trust, portability, and beta readiness

**Objective:** Make it safe to entrust the app with long-lived personal history.

**Indicative duration:** 1–2 weeks

### Work

- [ ] Add versioned JSON export and validated import.
- [ ] Keep data export available even if future premium access expires.
- [ ] Add explicit delete-history and delete-all-data flows with confirmation.
- [ ] Remove development-only seed restore controls from production UI.
- [ ] Decide and document the threat model for local storage.
- [ ] Add database encryption if it is part of the marketing claim; otherwise clearly state the actual protection.
- [ ] Add an optional app lock if target users request it.
- [ ] Publish privacy policy, terms, support contact, and data handling documentation.
- [ ] Add migration failure recovery and backup-before-migration behavior.
- [ ] Add privacy-preserving diagnostics and crash handling.
- [ ] Add CI for analysis, tests, Android build, and iOS simulator build.
- [ ] Configure production Android signing and final bundle identifiers.
- [ ] Complete accessibility and performance checks.

### Exit gate

A user must be able to export, restore, and permanently delete their data. Release builds must use production configuration, automated checks must pass, and privacy claims must match actual implementation.

---

## Phase 6 — Run a measured beta

**Objective:** Prove repeated use and willingness to pay before adding monetization complexity.

**Indicative duration:** 4–6 weeks, including enough time to observe D30 retention

### Privacy-preserving events to measure

Do not collect routine titles, note text, measurements, or exact personal timestamps. Measure only consented product events such as:

- onboarding completed
- first item created
- notification enabled
- notification action used
- fast log saved
- weekly insight generated
- insight opened
- suggested action accepted
- pricing screen opened

A fully local metrics export plus structured beta interviews is acceptable before introducing remote analytics.

### Directional beta targets

These are internal decision thresholds, not universal market benchmarks:

- [ ] At least 60% of recruited users reach activation.
- [ ] Activation means creating at least three routines and recording at least one real outcome.
- [ ] D7 retention is at least 35%.
- [ ] D30 retention is at least 20%.
- [ ] At least 30% of weekly active users open a weekly insight.
- [ ] A meaningful subset accepts or acts on a suggested adjustment.
- [ ] At least 10 target users make a real preorder, founding purchase, or paid-pilot commitment in the tested price range.
- [ ] Qualitative interviews confirm that insights—not generic reminders—are the main reason to return.

### Exit gate

Proceed to monetization only if retention and paid intent are credible. If users create routines but do not return, loop back to Phase 2. If they return but do not value insights, loop back to Phase 0 or Phase 4. Do not attempt to solve weak retention by adding unrelated features.

---

## Phase 7 — Implement monetization and production release

**Objective:** Convert validated value into sustainable revenue.

**Indicative duration:** 2–3 weeks

### Recommended model to test

Avoid advertising because it conflicts with local-first privacy positioning.

**Free:**

- Up to five active routines
- Core reminders and logging
- Basic weekly summary
- Data export and deletion

**Pro — test approximately $4.99/month or $39.99/year:**

- Unlimited active routines
- Advanced pattern and candidate-correlation rules
- 30-day and 90-day trends
- Smart schedule-adjustment suggestions
- Premium templates and widgets
- Optional encrypted backup/sync when available

Users must retain read/export access to their existing data after a subscription expires.

### Work

- [ ] Choose StoreKit/Google Play billing integration directly or through a service such as RevenueCat.
- [ ] Define entitlements independently from UI code.
- [ ] Cache entitlement state safely for offline use.
- [ ] Implement purchase, restore, cancellation, billing retry, and grace-period states.
- [ ] Show the paywall after a user experiences value, not during first launch.
- [ ] Test monthly, annual, trial, and optional founding-lifetime offers.
- [ ] Add App Store and Play Store privacy disclosures, subscription terms, screenshots, and support links.
- [ ] Build signed release artifacts in CI.
- [ ] Run sandbox purchase tests and staged store rollout.
- [ ] Add customer-support and refund procedures.

### Exit gate

Purchases and restores must pass on both stores, entitlement failure must never hide or delete user data, and staged-release health metrics must meet the defined quality threshold.

---

## Phase 8 — Expand only after product-market evidence

**Objective:** Add growth features without diluting the validated core.

Potential work, ordered by likely fit:

1. Home-screen widgets and shortcuts
2. Optional encrypted sync and device backup
3. Better automation and calendar integrations
4. Shared household routines, if validated
5. Web dashboard, only after mobile retention and paid conversion are healthy
6. Live topic briefings, only if users specifically request and pay for them

If topic briefings are retained, they require:

- real RSS/API adapters
- source attribution and link opening
- cache age and stale indicators
- offline and error states
- source terms/licensing review
- production Android internet permission
- clear separation between externally requested topics and private routine data
- unit economics that include feed/API costs

Do not build web parity, cloud infrastructure, black-box AI recommendations, or a broad social/news feed before the mobile core demonstrates retention.

## 4. Profitability model

### Current state

No direct monetization is implemented, and the repository contains no financial or usage data. Consequently, current accounting profitability is unknown; if the app is distributed free with no external revenue, direct app revenue is zero.

### Illustrative annual subscription economics

Assume:

- Annual price: **$39.99**
- Store fee: **15%**
- Net before other costs: approximately **$33.99 per subscriber-year**

| Annual target before tax and other costs | Approximate retained annual subscribers |
|---|---:|
| $12,000 | 353 |
| $60,000 | 1,765 |
| $120,000 | 3,531 |

These figures exclude acquisition, refunds, support, development labor, taxes, API costs, hosting, and any sync infrastructure.

### Profit formula

```text
Annual profit =
  paid subscribers
  × (price × (1 − store fee) − variable cost per subscriber)
  − acquisition cost
  − support and infrastructure
  − development and operating costs
```

The local-first architecture can keep variable costs low. Live briefings or cloud sync would reduce that advantage and must have separate unit-economics justification.

## 5. Metrics required to know whether the app is profitable

Track at minimum:

- installs and qualified acquisition source
- onboarding completion
- activation rate
- D1, D7, and D30 retention
- weekly active users
- routines created per active user
- outcomes/logs recorded per week
- notification permission and action rates
- insights generated, opened, and acted upon
- trial-to-paid and free-to-paid conversion
- monthly and annual churn
- refund rate
- customer acquisition cost
- average revenue per paying user
- variable API/infrastructure cost per user
- support and development costs

## 6. Commercial definition of done

Routine is commercially ready when:

1. A specific audience repeatedly uses the Plan → Record → Understand loop.
2. All insights are generated from real evidence and are understandable.
3. D30 retention and paid intent pass the beta gate.
4. Reminder behavior is reliable on real iOS and Android devices.
5. User data can be exported, restored, and deleted safely.
6. Privacy and encryption claims match implementation.
7. Store purchases, restores, and entitlement expiry are safe.
8. Contribution revenue exceeds store, acquisition, infrastructure, support, and development costs.

## 7. Immediate next action

Start with **Phase 0**, not billing or live briefings. In parallel, prepare the Phase 1 occurrence/status migration design so implementation can begin as soon as the target audience and core workflow are confirmed.
