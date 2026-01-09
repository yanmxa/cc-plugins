---
argument-hint: "<keyword|time> [account] [--read|--unread|--flag|--unflag]"
description: Mark emails as read/unread or flag/unflag by keyword or time range
allowed-tools:
  - Bash
---

Mark emails in Mac Mail.app with various status options. Supports batch operations on multiple emails or targeting specific emails by keyword.

## Parameters

Parse the arguments to extract:
- **target** (required): Which emails to mark
  - `<keyword>` - Match emails by subject or sender (e.g., "Kaggle", "Jira")
  - `today` / `yesterday` - Emails from specific day
  - `last3days` / `last5days` - Emails from date range
  - `YYYY-MM-DD` - Emails from specific date
- **account** (optional): Filter by account
  - `all` (default), `RedHat`, `163`, `Gmail`, `Outlook`
- **action** (optional): What status to set
  - `--read` (default) - Mark as read
  - `--unread` - Mark as unread
  - `--flag` - Add flag (starred)
  - `--unflag` - Remove flag
  - `--all-read` - Mark ALL matching emails as read (batch)
  - `--all-unread` - Mark ALL matching emails as unread (batch)

## Implementation Steps

1. **Parse Arguments**: Extract target, account filter, and action from $ARGUMENTS

2. **Build AppleScript**: Construct query based on target type.

**For keyword search (single email):**
```applescript
tell application "Mail"
    set matchedMsgs to (every message of inbox whose subject contains "keyword")

    if (count of matchedMsgs) > 0 then
        set msg to item 1 of matchedMsgs

        -- Apply action
        set read status of msg to true  -- or false for --unread
        -- set flagged status of msg to true  -- for --flag

        return "Marked 1 email as read: " & (subject of msg)
    end if
    return "No email found matching: keyword"
end tell
```

**For date range (batch operation):**
```applescript
tell application "Mail"
    set yesterday to (current date) - 1 * days
    set time of yesterday to 0
    set todayStart to current date
    set time of todayStart to 0

    set theMessages to (every message of inbox whose date received ≥ yesterday and date received < todayStart)
    set markedCount to 0

    repeat with msg in theMessages
        set read status of msg to true  -- or false for --unread
        set markedCount to markedCount + 1
    end repeat

    return "Marked " & markedCount & " emails as read"
end tell
```

3. **Execute and Report**: Run AppleScript and show results:
   - Number of emails affected
   - Brief summary of what was marked

## Usage Examples

### Mark Single Email
- `/email/mark Kaggle` - Mark most recent Kaggle email as read
- `/email/mark Kaggle --unread` - Mark as unread
- `/email/mark Jira --flag` - Flag Jira email

### Mark by Date (Batch)
- `/email/mark today --all-read` - Mark all today's emails as read
- `/email/mark yesterday --all-read` - Mark all yesterday's emails as read
- `/email/mark yesterday 163 --all-read` - Mark all yesterday's 163 emails as read

### Mark with Account Filter
- `/email/mark Jira RedHat` - Mark Jira email in RedHat as read
- `/email/mark yesterday RedHat --all-read` - Mark all yesterday's RedHat emails

### Flag Operations
- `/email/mark "important" --flag` - Flag email containing "important"
- `/email/mark Kaggle --unflag` - Remove flag from Kaggle email

## Action Reference

| Flag | Behavior |
|------|----------|
| (none) / `--read` | Mark as read (default) |
| `--unread` | Mark as unread |
| `--flag` | Add flag/star |
| `--unflag` | Remove flag/star |
| `--all-read` | Batch mark all matching as read |
| `--all-unread` | Batch mark all matching as unread |

## Notes

- Single keyword targets the most recent matching email
- Use `--all-read` or `--all-unread` for batch operations on date ranges
- Account names are case-sensitive (RedHat, Gmail, 163, Outlook)
- Use `/email/list` first to preview which emails will be affected
- Flag operations work on single emails (use keyword to target)
