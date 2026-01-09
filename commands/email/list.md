---
argument-hint: "[account] [time] [--unread]  account: RedHat|163|Gmail|Outlook|all  time: today|yesterday|last3days|last5days"
description: List and organize emails from Mac Mail.app with filtering options
allowed-tools:
  - Bash
---

Fetch and organize emails from Mac Mail.app using AppleScript.

## Parameters

Parse the arguments to extract:
- **account**: Account filter (default: all)
  - `all` - All accounts
  - `RedHat` - Work email (myan@redhat.com)
  - `163` - 163 email (yanmxa@163.com)
  - `Gmail` - Gmail (yanmxa@gmail.com)
  - `Outlook` - Outlook (yanmxa@outlook.com)
- **time**: Time range (default: today)
  - `today` - Today's emails
  - `yesterday` - Yesterday's emails
  - `last3days` - Last 3 days
  - `last5days` - Last 5 days
  - `YYYY-MM-DD` - Specific date (e.g., 2026-01-09)
- **--unread**: Only show unread emails
  - If `--unread` specified without time, fetch ALL unread emails (no time limit)

## Implementation Steps

1. **Parse Arguments**: Extract account, time range, and unread flag from $ARGUMENTS

2. **Build Optimized AppleScript**: Use Mail.app's filtering instead of manual iteration for better performance.

**IMPORTANT Performance Notes:**
- Use `whose` clause for filtering (faster than manual loop)
- Only fetch essential properties: subject, sender, date received
- Do NOT fetch message content (slow and unnecessary for listing)
- Limit results if needed to prevent timeout

```applescript
tell application "Mail"
    -- Calculate date range
    set yesterday to (current date) - 1 * days
    set time of yesterday to 0  -- Start of day
    set today to yesterday + 1 * days

    -- Use filtered query (FAST) instead of loop iteration (SLOW)
    set theMessages to (every message of inbox whose date received ≥ yesterday and date received < today)

    -- For unread only:
    -- set theMessages to (every message of inbox whose read status is false and date received ≥ yesterday)

    set output to ""
    repeat with msg in theMessages
        -- Only get essential fields (NO content)
        set output to output & "[Account] " & (sender of msg) & " - " & (subject of msg) & linefeed
    end repeat
    return output
end tell
```

3. **Execute and Format Output**: Run the AppleScript and organize results:
   - Group by account with `[AccountName]` prefix
   - Show only: sender, subject (essential info)
   - Summarize counts per account

4. **Present Summary**: Display organized email list with:
   - Total count per account
   - Key emails highlighted (work-related, important senders)
   - Use `/email/view <keyword>` to see full content

## Usage Examples

- `/email/list` - List today's emails from all accounts
- `/email/list RedHat` - List today's emails from RedHat account only
- `/email/list yesterday` - List yesterday's emails
- `/email/list RedHat yesterday` - Yesterday's RedHat emails
- `/email/list 2026-01-08` - Emails from specific date
- `/email/list --unread` - All unread emails (no time limit)
- `/email/list RedHat --unread` - All unread emails from RedHat
- `/email/list last5days` - Last 5 days of emails
- `/email/list 163 last3days` - Last 3 days from 163 account

## Date Calculation Reference

| Parameter | Days Back | Description |
|-----------|-----------|-------------|
| today | 0 | Current day only |
| yesterday | 1 | Previous day only |
| last3days | 3 | Past 3 days |
| last5days | 5 | Past 5 days |

## Notes

- Mail.app must be running or will be launched automatically
- Account names are case-sensitive (RedHat, Gmail, 163, Outlook)
- GitHub notifications from 163 account can be verbose; consider filtering
- Unread mode without time range may return many results
