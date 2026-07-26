# SCR-02: Item Builder & Editor

**Route/deep link:** `routine://item/create` | `routine://item/edit/:id`  
**Platforms:** iOS, Android, Web  
**PRD requirements:** FR-1, FR-3  

## Purpose

Modal screen for defining or editing a flexible timeline `Item`. Allows selecting item type (Reminder, Task, Maintenance, Deadline, Preparation, Topic Briefing, or Log/Observation), schedule rules, category, and attached triggers (e.g. preparation lead time).

## Entry points

- Floating Action Button on Timeline (`SCR-01`)
- "Edit Item" action on timeline card
- Quick action menu

## Content hierarchy

1. **Header**: Modal title ("New Item" / "Edit Item") with Cancel and Save buttons.
2. **Item Type Selector**: Segmented selector for item behavior (Reminder, Task, Maintenance, Deadline, Prep, Briefing, Observation).
3. **Basic Details**: Title input field, Category dropdown (Work, Family, Home, Finance, Personal).
4. **Schedule & Timing Controls**:
   - Time of Day / Specific Time picker.
   - Repeat Rule (Daily, Weekdays, Custom Interval e.g., Every 3 days).
   - Preparation Offset (e.g. "Trigger 10 minutes before").
5. **Topic Briefing Setup** (Visible if type is Briefing): Topic selection (Tech & AI, Finance, World, Custom query) and sources (Reddit, Bluesky, RSS).
6. **Notes & Attachments**: Free-text description field.

## Primary actions

- **Save Item**: Validates input, calculates schedule, updates local DB, schedules local OS notification, and returns to Timeline.
- **Delete Item**: Destructive button (when editing) with confirmation dialog.

## Andura UI mapping

| Product element | Andura component/token | Notes |
|---|---|---|
| Form Modal | `AnduraModal` / `AnduraSheet` | Slide-up sheet on mobile, modal dialog on web. |
| Type Selector | `AnduraSegmentedControl` / `AnduraChoiceChip` | Multi-option type picker. |
| Text Inputs | `AnduraTextField` | Styled text input with clear button. |
| Category Dropdown | `AnduraSelect` / `AnduraDropdown` | Category picking with color indicators. |
| Time Picker | `AnduraTimePicker` / `AnduraDatePicker` | Native/custom time selection. |
| Save Button | `AnduraButton` (Primary) | Main submit action. |

## Data requirements

| Data | Source | Freshness | Missing-data behavior |
|---|---|---|---|
| Item Entity | Local Database | Fresh | Initialize defaults (Type: Reminder, Category: Personal). |

## States

- **Validation Error**: Red inline message under required fields (e.g., empty title).
- **Saving**: Disable Save button and show spinner on action.

## Accessibility

- All form fields labeled for screen readers. Error messages associated via `aria-describedby` / semantic accessibility attributes.
