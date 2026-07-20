# SCR-03: Fast Observation & Event Logger

**Route/deep link:** `routine://log/fast`  
**Platforms:** iOS, Android, Web  
**PRD requirements:** FR-4  

## Purpose

Ultra-low-friction bottom sheet to quickly record what happened (status, free-text observations, measurements like sleep hours) for Today, Yesterday (backdated), or Tomorrow (future). Ensures exact separation of `event_timestamp` vs `recorded_at_timestamp`.

## Entry points

- Navigation Bar "+" button
- "Was anything unusual today?" prompt on Timeline
- Notification quick action

## Content hierarchy

1. **Date & Time Selector**: Toggle between Today (default), Yesterday (past), Tomorrow (future), or custom date/time (`event_timestamp`).
2. **Quick Entry Prompt**: Short headline ("What happened or what did you observe?").
3. **Category Tag Picker**: Work, Family, Home, Finance, Personal.
4. **Observation / Note Input**: Text area for quick observation (e.g., "Car took 3 attempts to start", "Plant leaves look yellow").
5. **Numeric Measurement Field** (Optional): Number input for sleep hours, expenses, or counts.

## Primary actions

- **Save Log**: Inserts record into database with current system clock as `recorded_at_timestamp` and chosen event time as `event_timestamp`.

## Andura UI mapping

| Product element | Andura component/token | Notes |
|---|---|---|
| Bottom Sheet | `AnduraBottomSheet` | Mobile-optimized slide up. |
| Date Selector | `AnduraChipGroup` | Today / Yesterday / Custom. |
| Note Field | `AnduraTextArea` | Expanding multi-line text field. |
| Save Action | `AnduraButton` (Primary) | Full-width submit button. |

## Data requirements

Stores new record in `Item` or `ObservationLog` table in local DB.
