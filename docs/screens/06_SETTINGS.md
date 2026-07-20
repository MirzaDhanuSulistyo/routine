# SCR-06: Settings & Topic Manager

**Route/deep link:** `routine://settings`  
**Platforms:** iOS, Android, Web  
**PRD requirements:** P1 Scope  

## Purpose

Allows users to manage followed topics for Morning/Evening Briefings (adding topics, toggling Reddit/Bluesky/RSS sources), set default alarm sounds, configure notification permissions, and export local database backups (JSON/CSV).

## Entry points

- Bottom Tab Bar ("Settings")
- Header icon on Timeline

## Content hierarchy

1. **Topic Briefing Preferences**:
   - Followed Topics List (e.g. "Tech & AI", "Finance", "World News").
   - Add Custom Topic / Keyword.
   - Source Toggles: Reddit, Bluesky, RSS Feeds.
2. **Notification & Alarm Settings**:
   - Alarm sound selector & volume preview.
   - OS Notification permission status badge.
3. **Data & Privacy**:
   - Export Data (JSON / CSV).
   - Clear History / Reset Database.
4. **App Info**: Version number and licenses.

## Andura UI mapping

| Product element | Andura component/token | Notes |
|---|---|---|
| Setting List | `AnduraList` / `AnduraListItem` | Grouped settings layout. |
| Source Switches | `AnduraSwitch` | Toggle sources on/off. |
| Action Buttons | `AnduraButton` | Export and permission actions. |
