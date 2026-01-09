---
argument-hint: "[time] [account]  time: today|yesterday|last3days  account: all|RedHat|163|Gmail"
description: Generate email digest with summaries, priorities, and action items
allowed-tools:
  - Bash
---

Generate a comprehensive email digest that summarizes important emails, identifies action items, and suggests replies for emails that need responses.

## Parameters

Parse the arguments to extract:
- **time** (optional, default: today):
  - `today` - Today's emails
  - `yesterday` - Yesterday's emails
  - `last3days` - Last 3 days
  - `last5days` - Last 5 days
  - `YYYY-MM-DD` - Specific date
- **account** (optional, default: all):
  - `all` - All accounts
  - `RedHat` - Work email only
  - `163` - 163 email only
  - `Gmail` / `Outlook` - Specific account

## Implementation Steps

### 1. Fetch All Emails

Use AppleScript to get all emails for the specified time range:

```applescript
tell application "Mail"
    set todayStart to current date
    set time of todayStart to 0
    set theMessages to (every message of inbox whose date received ≥ todayStart)

    repeat with msg in theMessages
        -- Get: account, sender, subject, date, read status
    end repeat
end tell
```

### 2. Categorize Emails by Importance

**High Priority (Action Required):**
- Direct emails from colleagues (not bot/automated)
- Emails with questions or requests
- Meeting invitations
- Jira issues assigned to you or mentioning you
- Security advisories
- Emails from external contacts (potential collaboration)

**Medium Priority (FYI):**
- Team newsletters
- PR reviews requested
- CI/CD notifications for your PRs
- General announcements

**Low Priority (Ignorable):**
- Marketing emails
- Automated bot notifications (not your PRs)
- Mailing list digests
- Promotional content

### 3. Generate Digest Report

For each category, provide appropriate level of detail:

**High Priority Emails:**
- Read full content using AppleScript
- Generate detailed summary for each
- Identify if response is needed
- Suggest response outline if applicable

**Medium Priority Emails:**
- Brief one-line summary
- Group similar emails (e.g., "5 PR notifications for #2230")

**Low Priority Emails:**
- Just count and category (e.g., "3 marketing emails")

### 4. Create Action Items

For emails requiring response or action:

```markdown
## Action Items

| Priority | From | Subject | Suggested Action |
|----------|------|---------|------------------|
| High | kay Yu | FL research | Reply: introduce project, share link, ask about use cases |
| Medium | Yasen Li | Lab ticket | Review and respond by EOD |
```

### 5. Generate Reply Suggestions

For high-priority emails needing response:
- Analyze the email content
- Draft a suggested reply outline
- Include key points to address

## Output Format

**Language:** Auto-detect user's language from their query and respond in that language.

Structure the report with the following sections in order:

### 1. Summary Section
```markdown
# Email Digest - [Date]

## Summary
- **Total:** X emails | **Unread:** X emails
- **High Priority:** X | **Medium:** X | **Low:** X
- **Action Required:** X emails
```

### 2. Email Details by Priority

**High Priority (Action Required):**
```markdown
### 1. [Sender] - [Subject]
**Account:** RedHat | **Time:** 14:30 | **Status:** Unread
**Summary:** [2-3 sentence summary]
```

**Medium Priority (FYI):** Use compact table format with detailed notes
```markdown
| From | Subject | Note |
|------|---------|------|
| DangPeng Liu (x2) | PR #2223 - Migration error handling | Code review: suggests showing max 3 errors in condition, full list in events |
| Ya Heng Liu | PR #23 - acm-qe-assistant | Approved PR, waiting for CI checks to complete |
| Katie Riedesel | HCM AI Newsletter | Weekly AI updates: new model releases, team highlights |
```
Note: Include specific details like review comments, PR status, or key points from content.

**Low Priority (Ignorable):** Group by category with detailed breakdown
```markdown
| Category | Count | Details |
|----------|-------|---------|
| Konflux bot | 8 | multicluster-controlplane: antlr4 v4.0.0, client-go 48f4ccf, ghodss/yaml d8423dc, library-go db8dbd6, k8s.io/utils 914a6e7 |
| Newsletters | 4 | CNCF (KubeCon EU keynote CFP), Friday Five (weekly digest), Linux Foundation (HPSFCon 2026), Kimi (K2 Thinking guide) |
| Marketing | 1 | Capterra: professional solutions promo |
```
Note: List specific repos/digests/senders to help user identify important items.

### 3. Todo List (Action Center)

Put ALL actionable items into ONE unified table at the end, including:
- High/Medium priority emails requiring response or review
- PR status that needs attention (as "Review" type)
- Batch processing commands for low-priority emails (merge similar commands into ONE item)
- Tips and suggestions (as "Tip" type)

**Important:**
- Merge similar low-priority commands into a single item to keep the list concise
- Make suggestions actionable with direct links or commands

```markdown
## Todo List

| # | Priority | Type | Content | Suggestion |
|---|----------|------|---------|------------|
| 1 | High | Reply | Xiaowu Wu - Lab-team | `/email:reply "Lab-team" "确认新流程，感谢分享"` |
| 2 | Medium | Review | PR #2223 code review | [View PR](https://github.com/stolostron/multicluster-global-hub/pull/2223) |
| 3 | Medium | Review | PR #123 merged | [View PR](https://github.com/org/repo/pull/123) |
| 4 | Low | Command | Batch mark low-priority emails read | `/email:mark read "konflux"` `/email:mark read "newsletter"` |
| 5 | Tip | Bookmark | Lab ticket new workflow | [Open Link](https://hub.redhat.com/...) |
```

**Suggestion formats by type:**
- Reply: Provide `/email:reply "<keyword>" "<outline>"` command with suggested response
- Review: Provide direct GitHub PR/issue link `[View PR](url)`
- Command: Provide `/email:mark` commands, merge similar ones
- Tip/Bookmark: Provide clickable link `[Open Link](url)` or `/email:view "<keyword>"`

**Type categories:**
- Reply: Emails requiring response
- Review: PRs or emails needing review
- Command: Batch processing commands (mark read/flag)
- Tip: Tips and suggestions

**Priority levels:**
- High: Urgent, needs immediate action
- Medium: Important but not urgent
- Low: Can be done in batch or later
- Tip: FYI, optional actions

## Usage Examples

```bash
# Today's email digest (default)
/email/digest

# Yesterday's digest
/email/digest yesterday

# Last 3 days, RedHat only
/email/digest last3days RedHat

# Specific date
/email/digest 2026-01-08
```

## Priority Classification Rules

### High Priority Indicators
- Sender is a known colleague (redhat.com domain, direct email)
- Subject contains: "urgent", "action required", "please"
- Email is a direct question or request
- Meeting invitation
- External contact (potential business opportunity)
- Security advisory

### Low Priority Indicators
- Sender is a bot (*[bot], noreply@, no-reply@)
- Subject contains: "newsletter", "digest", "unsubscribe"
- Marketing keywords: "don't miss", "last chance", "upgrade"
- Automated CI notifications (not your PR)

### Medium Priority (Default)
- Everything else

## Notes

- Fetches email content only for high-priority emails (performance optimization)
- Groups similar notifications to reduce noise
- Suggests actionable replies for emails needing response
- Use `/email/view <keyword>` to see full content of any email
- Use `/email/reply <keyword> "<outline>"` to send suggested replies
