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

The current scope combines reminders, habit tracking, event logging, maintenance, analytics, and news briefings. That creates implementation and marketing complexity without proving that users want the combination.

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

Non-recurring items must capture completion timestamps just as recurring items do. Fast Log should support an exact event date and time and optional attachment to an existing routine. Numeric entry is intentionally removed: the app should derive useful data automatically from planned times, completion times, delays, skips, snoozes, and notes.

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
- [ ] Add exact event date/time to Fast Log.
- [ ] Allow a log to reference an existing item or occurrence.
- [ ] Derive insights from automatic routine signals; do not require manual numeric entry.
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
- [ ] Redesign Fast Log with exact date/time, type, category, and optional linked routine.
- [ ] Remove manual numeric fields from Fast Log and routine items.
- [ ] Use progressive fields in the item builder for reminder, maintenance, deadline, and other behaviors.
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

Do not collect routine titles, note text, or exact personal timestamps. Measure only consented product events such as:

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
- Advanced pattern and candidate-correlation rules based on automatically captured routine history
- 30-day and 90-day trends for delays, skips, snoozes, and completion behavior
- Smart schedule-adjustment suggestions
- Premium templates and widgets
- Optional encrypted backup/sync when available

Pro does not require manual numeric entry. The free product should capture useful event data through normal one-tap actions; Pro unlocks deeper analysis of that history. Automatic health or device integrations can be considered later, but are not required for the core product.

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

## 4. Test strategy — what to test and how

Testing should follow the same critical path as implementation. Business-rule defects should be caught by fast unit tests, screen behavior by widget tests, complete user journeys by app-level E2E tests, and operating-system behavior by native/real-device tests.

### 4.1 Test layers

| Layer | Purpose | Recommended tools | When to run |
|---|---|---|---|
| Static checks | Type, lint, and compile-time problems | `flutter analyze` | Every pull request |
| Unit tests | Pure domain rules, time calculations, insight rules, entitlements | `flutter_test` with fake clock and dependencies | Every pull request |
| Component tests | SQLite repositories, migrations, serialization, service adapters | `flutter_test`, `sqflite_common_ffi`, temporary files | Every pull request |
| Widget tests | Screen states, validation, actions, semantics, themes | `flutter_test` | Every pull request |
| App E2E tests | Full workflows through the real Flutter UI and test database | Flutter `integration_test` | Main branch and release candidates |
| Native-system E2E | Notifications, permission dialogs, lock screen, reboot, timezone changes | Patrol, XCUITest/Espresso, or a controlled manual device script | Nightly where possible and every release candidate |
| Store E2E | Purchase, restore, expiry, grace period, refund behavior | StoreKit sandbox/TestFlight and Google Play license testers/internal track | Every monetization release |
| Exploratory checks | Usability, screen reader quality, unusual device behavior | Physical devices, VoiceOver, TalkBack, DevTools | Every milestone and release candidate |

Flutter's `integration_test` package can automate the app UI, persistence, and navigation. It cannot reliably prove lock-screen notification delivery, reboot behavior, or every native permission flow. Those require native automation or a documented real-device test pass; a mocked plugin test is not a substitute.

### 4.2 Testability changes required before expanding the suite

The current widgets create concrete repositories and singleton services directly. Refactor toward dependency injection before adding large E2E suites:

- [ ] Inject `RoutineRepository`, reminder gateway, settings store, metrics sink, entitlement service, and file/export gateway.
- [ ] Inject a clock and timezone provider instead of calling `DateTime.now()` throughout business logic.
- [ ] Inject an ID generator so fixtures and assertions are deterministic.
- [ ] Separate reminder planning from the `flutter_local_notifications` plugin wrapper.
- [ ] Give screens stable semantic labels and keys based on behavior, not visual position.
- [ ] Provide a test application bootstrap with an isolated database and fake platform services.
- [ ] Reset and close all test databases after every test.
- [ ] Never use a developer's or user's production database in automated tests.
- [ ] Never call live news, billing, or analytics endpoints from normal CI tests.
- [ ] Keep test fixture loading unavailable from production UI.

Add Flutter's SDK E2E package when Phase 2 begins:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

Suggested test layout:

```text
test/
├── unit/
│   ├── domain/
│   ├── application/
│   └── services/
├── component/
│   ├── database/
│   ├── repository/
│   └── import_export/
├── widget/
│   ├── onboarding/
│   ├── timeline/
│   ├── fast_log/
│   ├── insights/
│   └── settings/
└── fixtures/

integration_test/
├── first_run_journey_test.dart
├── routine_occurrence_journey_test.dart
├── insight_journey_test.dart
├── backup_restore_journey_test.dart
└── entitlement_journey_test.dart
```

The existing tests can be moved gradually; file organization should not block feature work.

### 4.3 Unit and component test matrix

#### Domain and time rules

**What to test**

- Parsing and formatting 12:00 AM, 12:00 PM, invalid times, and section boundaries.
- Daily, weekly, and future custom recurrence projection.
- Start dates, leap days, month/year boundaries, and preparation offsets crossing midnight.
- Status transitions among scheduled, completed, late, skipped, rescheduled, and logged.
- Planned, actual-event, and recorded-at timestamp semantics.
- Backdated entries, future plans, and edits to prior occurrences.
- Daylight-saving and timezone behavior for supported scheduling rules.

**How**

- Use pure Dart functions and table-driven fixtures.
- Inject a fixed clock and explicit timezone.
- Assert exact output dates/statuses rather than formatted display strings.
- Add a regression fixture for every date/time bug found in production.

#### Repository and migration behavior

**What to test**

- CRUD and round-trip serialization for every field and status.
- Independent completion history for recurring and one-time items.
- Seven-day/30-day range query boundaries and chronological ordering.
- Cascade behavior when deleting an item.
- Transaction rollback after a forced write/import failure.
- Empty database behavior without automatic sample restoration.
- Migration from every shipped schema version to the newest schema.
- Malformed legacy JSON, null legacy fields, duplicate IDs, and partial records.

**How**

- Use `sqflite_common_ffi` with a uniquely named temporary database per test.
- Create old schema fixtures directly with SQL, insert known rows, open with the new migrator, and compare every preserved value.
- Close and delete the database in `tearDown`.
- Test failed transactions by injecting or deliberately triggering an invalid row inside the transaction.

#### Reminder planning and service adapter

**What to test**

- One-time, daily, weekly, preparation, and cross-midnight schedules.
- Stable base reminder IDs and distinct snooze IDs.
- Snooze does not remove the next recurring reminder.
- Edit, disable, completion, deletion, and reset produce the correct schedule/cancel operations.
- Notification actions map to the intended occurrence.
- Exact-permission denial selects the documented inexact fallback.
- Permission revocation and reconciliation remove stale assumptions.

**How**

- Move schedule calculation into a pure `ReminderPlanner` and unit-test its commands with a fixed clock.
- Put the plugin behind a gateway and use a fake gateway that records schedule/cancel calls.
- Reserve actual delivery, notification shade, and lock-screen assertions for native-system E2E tests.

#### Insight engine

**What to test**

- Timing shifts at, below, and above each threshold.
- Minimum sample requirements and prior-period comparison.
- Repeated-note normalization, punctuation, case, and common false matches.
- Missed/skipped routine trends.
- Candidate co-occurrence positive, negative, and insufficient-opportunity cases.
- Cross-midnight and timezone evidence.
- No data and insufficient data return no fabricated insight.
- Every result includes the correct evidence IDs, period, sample count, and cautious language.
- Suggested actions change only the intended schedule field.
- Performance with at least 1,000 occurrences.

**How**

- Use named, deterministic multi-day fixtures where expected evidence IDs are explicit.
- Test each rule separately before testing combined reports.
- Add negative fixtures designed to look correlated but fail the minimum evidence rule.
- Keep rule output structured; test presentation copy separately from evidence selection.

#### Import, export, settings, and privacy

**What to test**

- Export → delete → import round trip preserves all supported data.
- Importing corrupt, truncated, future-version, duplicate, and incompatible files.
- Import is atomic and leaves existing data unchanged on failure.
- Theme and settings survive app restart; invalid values fall back safely.
- Delete-history and delete-all affect exactly the intended records.
- Metrics events contain only approved fields and never include titles, notes, or exact personal timestamps.

**How**

- Use temporary files and compare normalized domain objects rather than raw JSON ordering.
- Inject an in-memory settings store and an event-recording metrics sink.
- Maintain an allow-list for metrics payload keys and unit-test every event constructor.

#### Entitlements and billing

**What to test**

- Free, trial, Pro, expired, grace-period, billing-retry, refunded, and offline-cached states.
- Purchase and restore success, cancellation, timeout, and store error.
- Existing user data remains readable/exportable after entitlement expiry.
- Premium mutations are blocked consistently while data is never deleted.

**How**

- Keep entitlement policy in a pure service and test it with a fake store client.
- Use fake purchase results in CI; use real store sandbox tests only in the release matrix.
- Never make ordinary unit tests depend on StoreKit, Play Billing, or RevenueCat availability.

#### Optional briefing adapters

If Phase 8 retains briefings, unit-test feed parsing, sanitization, deduplication, attribution, cache age, stale fallback, timeout, rate limit, and malformed responses using saved fixtures or a local mock server. Do not use live publishers in CI.

### 4.4 Widget test matrix

Pump each screen with fake repositories/services so every state can be reached deterministically.

| Area | Widget behavior to test |
|---|---|
| Onboarding | Fresh install, template selection, skip path, contextual permission explanation, completion persistence |
| Timeline | Loading, empty, populated, error, selected date, filters, compact card, details, Done/Late/Skip actions |
| Item builder | Required validation, progressive fields by type, recurrence, date/time, notification denial, edit preservation |
| Fast Log | Exact date/time, note-only observation, linked routine, invalid/empty input, save failure |
| Weekly Insights | Insufficient history, populated report, evidence expansion, dismissed insight, suggested action confirmation |
| Settings/data | Permission states, export result, import error, destructive confirmation, theme persistence |
| Monetization | Free/Pro states, paywall timing, purchase progress/error, restore, expired entitlement without hidden data |

For every critical screen:

- [ ] Test light and dark themes.
- [ ] Test large text without clipped actions or overflow.
- [ ] Test semantic labels and selected/disabled states.
- [ ] Check Flutter accessibility guidelines for labeled targets, contrast, and touch-target size where applicable.
- [ ] Use a small number of stable golden tests for high-value layouts; do not replace behavioral assertions with screenshots.

### 4.5 Automated app E2E scenarios

Run these through the real Flutter UI with a real isolated SQLite database. Fake only boundaries that cannot be made deterministic in CI, such as the OS notification center and app-store backend.

#### E2E-01 — First-run Plan → Record journey

1. Launch with fresh app data.
2. Complete onboarding without sample records.
3. Create a daily routine and enable its reminder through a fake permission gateway.
4. Verify it appears on the correct date and time.
5. Mark the occurrence late and add a note.
6. Restart the app.
7. Verify the status, actual time, note, and recurrence remain correct.

#### E2E-02 — Independent recurring occurrences

1. Create a daily routine.
2. Complete one date, skip the next, and leave the third scheduled.
3. Navigate backward and forward through the dates.
4. Edit the template without erasing prior occurrence history.
5. Restart and verify all three dates remain independent.

#### E2E-03 — Backdated event log

1. Open Fast Log.
2. Choose a prior date and exact event time.
3. Enter an observation, optionally linked to an existing routine.
4. Save and verify it appears at the correct historical position.
5. Verify recorded-at time differs from event time and survives restart.

#### E2E-04 — Edit, reschedule, and delete

1. Create a notified recurring item.
2. Edit its time and recurrence.
3. Verify the fake notification gateway contains one correct base schedule and no stale schedule.
4. Delete the item with confirmation.
5. Verify the item, occurrence history, and pending reminder are removed.

#### E2E-05 — Evidence-backed weekly insight

1. Load a test-only seven-day fixture with known delays and skipped events.
2. Open Weekly Insights.
3. Verify the expected rule appears and unrelated rules do not.
4. Expand evidence and verify the displayed dates match fixture records.
5. Accept a schedule-adjustment suggestion.
6. Return to the timeline and verify only the intended routine changed.
7. Repeat with insufficient history and verify no fabricated insight appears.

#### E2E-06 — Export, clear, and restore

1. Create items, occurrences, notes, and settings.
2. Export to a test-controlled file location.
3. Delete all data and verify the empty state.
4. Import the file.
5. Verify all records, relationships, settings, and history are restored.
6. Attempt a corrupt import and verify existing data remains unchanged.

#### E2E-07 — Recoverable failures

1. Force repository load and save failures through a test adapter.
2. Verify useful error and retry states.
3. Retry after restoring the adapter.
4. Verify no duplicate or lost records.

#### E2E-08 — Entitlement journey

1. Reach the paywall after the configured value moment.
2. Simulate purchase success and verify Pro features unlock.
3. Restart offline and verify cached entitlement behavior.
4. Simulate expiry and verify existing data remains visible/exportable.
5. Simulate restore and verify access returns.

### 4.6 Native and real-device E2E scenarios

These scenarios cross the Flutter/OS boundary and must not be signed off using mocks alone:

| ID | Scenario | Required assertion |
|---|---|---|
| N-01 | App terminated before a one-time reminder | Notification appears at the expected local time |
| N-02 | Done from notification shade/lock screen | Correct occurrence is completed after reopening the app |
| N-03 | Snooze a recurring reminder | Snooze appears after 10 minutes and the next recurrence remains scheduled |
| N-04 | Add Note action | App opens the logger linked to the triggering occurrence |
| N-05 | Permission denied/revoked | App shows accurate status and continues safely with documented fallback |
| N-06 | Android exact alarm denied | Inexact mode is used and clearly communicated |
| N-07 | Device reboot/app upgrade | Eligible reminders are restored without duplicates |
| N-08 | Timezone/DST change | Future reminders follow the documented local-time behavior |
| N-09 | Notification action near midnight | Completion is assigned to the intended occurrence date |

**How to run**

- Schedule test notifications one or two minutes ahead using dedicated test data.
- Test at least one physical iOS device and two supported Android OS versions.
- Use Patrol or native XCUITest/Espresso for permission and notification UI when stable; otherwise follow a versioned manual script.
- Capture device model, OS version, timezone, result, logs, and evidence for every release candidate.
- Include denied and later-revoked permissions, not only the happy path.

### 4.7 Store sandbox E2E scenarios

Before a monetized release, test on both store ecosystems:

- New monthly and annual purchase
- User-cancelled purchase
- Store/network failure
- Restore on a second installation/device
- Subscription renewal
- Cancellation with access until period end
- Billing retry and grace period
- Expiry and re-subscription
- Refund/revocation
- Offline launch with a previously cached entitlement

Use Apple sandbox/TestFlight and Google Play license testers/internal testing. Verify both the store state and visible app entitlement; dashboard-only confirmation is insufficient.

### 4.8 Performance, accessibility, and security checks

**Performance**

- Seed 1,000 and 10,000 occurrences and measure timeline query, report generation, startup, and scrolling.
- Preserve the PRD goal of sub-100ms local timeline query for 1,000 items where practical.
- Use Flutter integration performance traces and DevTools to detect dropped frames and memory growth.

**Accessibility**

- Automate semantic labels, touch targets, and large-text layout where possible.
- Manually complete the core journey with VoiceOver and TalkBack before release.
- Verify status is communicated by text/semantics, not color alone.

**Security/privacy**

- Verify exports do not unintentionally enter logs or analytics.
- Verify secrets and store credentials are not committed to the repository.
- Verify delete-all removes application records and test whether backups follow the documented policy.
- Inspect release logs to ensure personal titles and notes are not printed.
- Perform a migration and import threat review before accepting untrusted backup files.

### 4.9 Test requirements by implementation phase

| Phase | Required test gate |
|---|---|
| Phase 0 | Moderated usability script and documented interview evidence; no automated substitute |
| Phase 1 | Domain unit tests plus repository/migration component tests, including all shipped schema versions |
| Phase 2 | Widget tests for all screen states plus E2E-01 through E2E-03 |
| Phase 3 | Reminder planner unit tests, fake-gateway integration tests, and native scenarios N-01 through N-09 |
| Phase 4 | Deterministic insight-rule unit tests plus E2E-05 with evidence verification |
| Phase 5 | Export/import, privacy payload, accessibility, performance, and E2E-06/E2E-07 |
| Phase 6 | Beta telemetry validation, exploratory regression, and real-device release-candidate pass |
| Phase 7 | Entitlement unit/widget tests, E2E-08, and full store sandbox matrix |
| Phase 8 | Contract, unit, E2E, privacy, and cost tests specific to each optional integration |

### 4.10 Commands and CI gates

Local and pull-request baseline:

```sh
flutter analyze
flutter test
flutter test --coverage
```

App E2E after adding `integration_test`:

```sh
flutter test integration_test -d <device-id>
flutter test integration_test/first_run_journey_test.dart -d <device-id>
```

If Patrol is selected for native automation:

```sh
patrol test -d <device-id>
```

Recommended CI schedule:

- **Every pull request:** formatting check, `flutter analyze`, unit, component, and widget tests.
- **Main branch/nightly:** Android emulator E2E; iOS simulator E2E on a macOS runner where available.
- **Release candidate:** signed Android/iOS builds, physical-device native matrix, accessibility pass, migration/backup restore, and store sandbox tests.

Coverage is a diagnostic, not the goal. Require complete behavioral coverage for migrations, status transitions, reminder planning, insight evidence, import atomicity, and entitlements. Do not hide flaky tests behind automatic retries; fix their clocks, state isolation, selectors, or platform assumptions.

### 4.11 Definition of tested for each change

A feature or bug fix is not complete until:

1. Its business rules have unit tests.
2. Its database or platform boundary has component tests with fakes or isolated resources.
3. Its visible states and failure paths have widget tests.
4. A changed critical journey has an E2E test.
5. A native-system change has real-device evidence where Flutter automation cannot prove it.
6. A regression test fails before the fix and passes after it.
7. Tests are deterministic, isolated, and pass in CI.
8. No test sends personal data or calls production services.

## 5. Profitability model

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

## 6. Metrics required to know whether the app is profitable

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

## 7. Commercial definition of done

Routine is commercially ready when:

1. A specific audience repeatedly uses the Plan → Record → Understand loop.
2. All insights are generated from real evidence and are understandable.
3. D30 retention and paid intent pass the beta gate.
4. Reminder behavior is reliable on real iOS and Android devices.
5. User data can be exported, restored, and deleted safely.
6. Privacy and encryption claims match implementation.
7. Store purchases, restores, and entitlement expiry are safe.
8. Contribution revenue exceeds store, acquisition, infrastructure, support, and development costs.

## 8. Immediate next action

Start with **Phase 0**, not billing or live briefings. In parallel, prepare the Phase 1 occurrence/status migration design so implementation can begin as soon as the target audience and core workflow are confirmed.
