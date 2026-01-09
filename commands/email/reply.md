---
argument-hint: "<keyword> \"<outline>\" [--lang=en|zh]"
description: Draft and send email reply based on outline with review before sending
allowed-tools:
  - Bash
  - AskUserQuestion
---

Draft a reply email based on user-provided outline, allow review and editing, then send via AppleScript.

## Parameters

Parse the arguments to extract:
- **keyword** (required): Search term to find the target email (subject or sender)
- **outline** (required): Key points for the reply content (in quotes)
- **--lang** (optional): Reply language
  - `--lang=en` - English (default)
  - `--lang=zh` - Chinese

## Implementation Steps

1. **Find Target Email**: Use AppleScript to locate the email to reply to.

```applescript
tell application "Mail"
    set matchedMsgs to (every message of inbox whose subject contains "keyword")
    if (count of matchedMsgs) > 0 then
        set msg to item 1 of matchedMsgs
        -- Return email details for context
        return "From: " & (sender of msg) & linefeed & "Subject: " & (subject of msg) & linefeed & "Content: " & (content of msg)
    end if
end tell
```

2. **Draft Reply Content**: Based on the original email and user's outline:
   - Read and understand the original email context
   - Generate a professional reply following the outline
   - Match the tone and formality of the original email
   - Keep it concise and clear

3. **Present Draft for Review**: Show the drafted reply to user:
```
---
**Draft Reply**

Subject: Re: [original subject]

[Generated reply content based on outline]

---
```

Ask user: "Is this reply OK? You can request changes or approve to send."

4. **Handle User Feedback**:
   - If user requests changes: Modify the draft and present again
   - If user approves: Proceed to send

5. **Send Reply via AppleScript**:

```applescript
tell application "Mail"
    set matchedMsgs to (every message of inbox whose subject contains "keyword")

    if (count of matchedMsgs) > 0 then
        set originalMsg to item 1 of matchedMsgs

        -- Create reply
        set replyMsg to reply originalMsg with opening window

        tell replyMsg
            set content to "[APPROVED_CONTENT]"
        end tell

        -- Send the reply
        send replyMsg

        return "Reply sent successfully"
    end if
end tell
```

6. **Confirm Success**: Report that the reply was sent.

## Usage Examples

### Basic Usage
```bash
# Reply to email with outline
/email/reply "FL x multi-cluster" "Thank for reaching out, introduce project status, share link, look forward to discussion"

# Reply with specific points
/email/reply "kay" "1. Thank for reaching out 2. Share project link 3. Ask about their use cases"
```

### With Language Option
```bash
# Reply in English (default)
/email/reply "Kaggle" "Thank them, express interest, ask about timeline"

# Reply in Chinese
/email/reply "meeting" "Received, will arrange accordingly" --lang=zh
```

### Complex Outline
```bash
/email/reply "Lab-team ticket" "1. Acknowledge the question 2. Explain the process: a) open Jira b) select component c) assign to team 3. Offer to help if needed"
```

## Draft Guidelines

When generating reply content:

1. **Greeting**: Match the original email's style (Hi/Hello/Dear)
2. **Opening**: Acknowledge the original message if appropriate
3. **Body**: Address each point in the outline
4. **Closing**: Professional sign-off matching the tone
5. **Signature**: Use "Best regards," followed by user's name

## Review Process

The draft will be presented for review. User can:
- **Approve**: Say "OK", "send", "yes" → Proceed to send
- **Request changes**: Describe what to modify → Regenerate draft
- **Cancel**: Say "cancel", "abort" → Abort without sending

## Notes

- Original email context is used to generate appropriate reply
- Draft is ALWAYS shown for review before sending
- Supports both English and Chinese replies
- Uses Mail.app's reply function to maintain thread
- Reply is sent from the same account that received the original email
