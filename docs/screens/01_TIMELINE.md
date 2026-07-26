# SCR-01: Timeline (Home)

**Route/deep link:** `routine://timeline`  
**Platforms:** iOS, Android, Web  
**PRD requirements:** FR-2, FR-3, FR-4, FR-5  

## Purpose

The central operational hub of Routine. Shows a unified chronological view of planned items, completed actions, log entries, observations, and scheduled topic briefings grouped by time of day (Morning, Afternoon, Evening). Enables switching between Today, Past (backdated), and Future dates.

## Entry points

- App launch
- Bottom tab bar ("Timeline")
- Notification deep-link

## Content hierarchy

1. **Date Header Strip**: Day selector (Past / Today / Future) with date picker calendar drawer.
2. **Daily Operations Timeline**:
   - **Morning Section (<12:00)**: Alarm items (e.g. Clock In), Contextual Preps (Warm Car), Morning Brief Card.
   - **Afternoon Section (12:00–18:00)**: Clock Out reminder, recurring maintenance (Water Plants).
   - **Evening Section (>18:00)**: Family tasks (Son's math practice), Daily Observation Log prompt ("Was anything unusual today?").
3. **Quick Log Floating Action Button**: Fast entry for observations or status.

## Primary actions

- **Toggle Status**: Mark item Done, Skipped, or Late directly from timeline card.
- **Open Brief**: Tap Topic Briefing card to navigate to `routine://briefing/:id`.
- **Add Item**: Tap `+` button to open Item Builder (`routine://item/create`).
- **Log Observation**: Tap "Log Observation" prompt to open Fast Logger (`routine://log/fast`).

## Andura UI mapping

| Product element | Andura component/token | Notes |
|---|---|---|
| Main Container | `AnduraContainer` / `AnduraPageLayout` | Baseline page layout with semantic surface colors. |
| Time Section Header | `AnduraSectionHeader` | Labeling Morning, Afternoon, Evening with visual icons. |
| Timeline Item Card | `AnduraCard` / `AnduraListItem` | Customized card with status check, category badge, and title. |
| Quick Status Toggle | `AnduraCheckbox` / `AnduraIconButton` | Immediate status state mutation. |
| Topic Briefing Card | `AnduraCard` with `AnduraBadge` | Visual styling for topic news summaries. |
| Date Switcher | `AnduraSegmentedControl` / `AnduraDatePicker` | Past / Today / Future filtering. |

## Data requirements

| Data | Source | Freshness | Missing-data behavior |
|---|---|---|---|
| Timeline Items | Local Database (SQLite / Isar) | Real-time local query | Display empty state prompt for date. |
| Topic Brief Digest | Local Cache / Network Fetch | Cached or fresh | Show cached digest with offline badge if offline. |

## States

- **Loading**: Render skeleton list cards while reading local database.
- **Empty**: Display friendly illustration ("No items planned for this date. Tap + to add one.").
- **Error**: Local DB read failure banner with retry button.
- **Permission denied**: Non-intrusive warning card if notifications are disabled in OS.

## Interaction notes

- Swipe right on timeline item card to quick-complete.
- Swipe left to snooze or edit.
- Tapping a completed item allows editing `notes` or updating `event_timestamp`.

## Accessibility

- Full VoiceOver / TalkBack support for timeline item titles, times, and completion statuses.
- High-contrast badges for categories (Work, Family, Home, Finance, Personal).

## Platform differences

- **Android**: Supports native Android back button to return to Today view if viewing a past date.
- **iOS**: Uses iOS pull-to-refresh to force re-fetch of topic briefs.
- **Web**: Sidebar navigation replaces bottom tab bar.
