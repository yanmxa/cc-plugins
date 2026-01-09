---
argument-hint: "<keyword> [account] [--raw|--lang=zh|en|de] [--unread]"
description: View email content by keyword search with translation and read status options
allowed-tools:
  - Bash
---

Search for emails by keyword (subject or sender), display the most relevant email content with optional translation, and manage read status.

## Parameters

Parse the arguments to extract:
- **keyword** (required): Search term to match against subject or sender
- **account** (optional): Filter by account (RedHat, 163, Gmail, Outlook)
  - Default: search all accounts
- **output mode** (optional):
  - Default: Auto-detect based on conversation context (respond in user's language)
  - `--raw`: Output original email content without translation
  - `--lang=zh`: Translate/summarize in Chinese
  - `--lang=en`: Translate/summarize in English
  - `--lang=de`: Translate/summarize in German
  - Other languages supported: `--lang=ja` (Japanese), `--lang=fr` (French), etc.
- **read status** (optional):
  - Default: Mark as read after viewing
  - `--unread`: Keep as unread (or mark as unread if already read)

## Implementation Steps

1. **Parse Arguments**: Extract from $ARGUMENTS:
   - keyword (required)
   - account filter (optional, default: all)
   - output mode (--raw, --lang=XX, or auto)
   - read status flag (--unread)

2. **Fetch Email Content**: Use AppleScript with optimized search.

**IMPORTANT Performance Notes:**
- Use `whose` clause for keyword filtering when possible
- Only fetch content for the SINGLE matched email
- Set timeout to handle slow responses

```applescript
tell application "Mail"
    -- Use filtered query for better performance
    -- Search in subject (sender search requires loop)
    set matchedMsgs to (every message of inbox whose subject contains "keyword")

    if (count of matchedMsgs) > 0 then
        set msg to item 1 of matchedMsgs
        set emailAccount to name of (account of mailbox of msg)
        set emailFrom to sender of msg
        set emailSubject to subject of msg
        set emailDate to date received of msg
        set emailContent to content of msg  -- Only fetch content for matched email

        -- Handle read status
        set read status of msg to true  -- or false if --unread

        return output
    end if
    return "No email found matching: keyword"
end tell
```

3. **Process Output Based on Mode**:

   **If `--raw`:**
   - Output email content exactly as received (original language)
   - No translation or summarization

   **If `--lang=XX` specified:**
   - Translate email content to the specified language
   - Preserve key information (sender, subject, date)
   - Summarize long emails if appropriate

   **If default (no mode specified):**
   - Detect conversation language from context
   - If user is writing in Chinese, respond in Chinese
   - If user is writing in English, respond in English
   - Translate/summarize email content accordingly

4. **Format Output**:
```
Account: [account name]
From: [sender]
Subject: [subject]
Date: [date]
Status: [Marked as READ / Kept UNREAD]
---

[Email content - processed based on output mode]
```

## Usage Examples

### Basic Usage
- `/email/view Kaggle` - View email, auto-translate based on context
- `/email/view "RNA Folding"` - Search specific phrase

### With Account Filter
- `/email/view kay Gmail` - Search in Gmail only
- `/email/view Jira RedHat` - Search in RedHat account

### Output Modes
- `/email/view Kaggle --raw` - Show original content (no translation)
- `/email/view Kaggle --lang=zh` - Translate to Chinese
- `/email/view Kaggle --lang=en` - Translate to English
- `/email/view Kaggle --lang=de` - Translate to German

### Read Status
- `/email/view Kaggle` - View and mark as read (default)
- `/email/view Kaggle --unread` - View but keep/mark as unread

### Combined
- `/email/view Jira RedHat --raw --unread` - Raw content, keep unread
- `/email/view kay --lang=zh` - Translate to Chinese, mark as read

## Output Mode Reference

| Flag | Behavior |
|------|----------|
| (none) | Auto-detect from conversation, translate if needed |
| `--raw` | Original language, no processing |
| `--lang=zh` | Chinese translation/summary |
| `--lang=en` | English translation/summary |
| `--lang=de` | German translation/summary |
| `--lang=ja` | Japanese translation/summary |
| `--lang=fr` | French translation/summary |

## Read Status Reference

| Flag | Behavior |
|------|----------|
| (none) | Mark as read after viewing |
| `--unread` | Keep as unread / Mark as unread |

## Notes

- Mail.app must be running or will be launched automatically
- Only searches INBOX (not sent, trash, etc.)
- Returns the most recent matching email
- Account names are case-sensitive (RedHat, Gmail, 163, Outlook)
- Use `/email/list` first to find keywords if unsure
- Translation quality depends on email content complexity
