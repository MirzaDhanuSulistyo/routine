# SCR-04: Topic Briefing Reader

**Route/deep link:** `routine://briefing/:id`  
**Platforms:** iOS, Android, Web  
**PRD requirements:** FR-5  

## Purpose

Displays a clean, finite digest of top 3–5 news stories and social media discussions (from followed topics e.g. Tech & AI, Finance, World, Reddit, Bluesky, RSS) delivered at user-scheduled times (e.g. 07:00 Morning Brief). Focuses on fast consumption without infinite scrolling.

## Entry points

- Morning Brief Card on Timeline (`SCR-01`)
- Scheduled Topic Notification tap

## Content hierarchy

1. **Header**: Briefing Title (e.g. "Morning Briefing — Tech & AI") and Timestamp.
2. **Topic Summary Cards**: 3 to 5 curated story items. Each item includes:
   - Topic Badge (e.g. `Reddit / r/technology`, `Bluesky / AI News`, `GNews`)
   - Story Headline & 2-sentence summary snippet
   - External URL link button ("Read Source")
3. **Completion Action**: "Mark Briefing Complete" button.

## Primary actions

- **Mark Complete**: Marks briefing step finished in daily routine.
- **Open Source**: Opens external link in in-app browser sheet.

## Andura UI mapping

| Product element | Andura component/token | Notes |
|---|---|---|
| Card List | `AnduraCard` / `AnduraList` | Styled cards with source badges. |
| Source Badge | `AnduraBadge` | Color-coded by source type. |
| Complete Button | `AnduraButton` | Action to complete routine item. |

## States

- **Offline**: Displays cached news digest with a subtle offline banner.
