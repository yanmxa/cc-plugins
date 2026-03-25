---
name: jira
description: Jira operations — sprint board, my issues, create/update/close/link issues. Triggers on sprint, issues, create, update, close, link, or any ACM-xxx mention.
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob, WebFetch]
---

# Jira

Bundled scripts for common Jira workflows. Each operation is a single script call.

Scripts are at `${CLAUDE_SKILL_DIR}/scripts/`.

## sprint — List my current sprint issues

```bash
scripts/sprint.sh [board_id]
```

Outputs a markdown table directly, grouped by status (New -> In Progress -> Closed) with columns: Type, Pri, Key (markdown links), Title, SP, Activity, Components, Versions, Labels. Print the output as-is. Collapse bulk CVE vulnerabilities into a summary row.

## issues — List all my assigned issues

```bash
scripts/issues.sh [extra_jql_filter]
```

Lists all issues assigned to current user, excluding Closed and Backlog by default. Supports optional extra JQL filter (e.g. `"project = ACM"`, `"component = 'Global Hub'"`).

Outputs a markdown table directly, grouped by status (New -> In Progress -> Resolved) with columns: Type, Pri, Key (markdown links), Title, SP, Activity, Components, Versions. Keys prefixed with pin emoji indicate issues in the current active sprint. Print the output as-is. Collapse bulk CVE vulnerabilities into a summary row.

## create — Create a new issue

```bash
scripts/create.sh "<summary>" [type=Task] [priority=Major] [sp=3] [parent=ACM-xxx] [component=Global Hub] [sprint=current]
```

Defaults: project=ACM, component=Global Hub, assignee=current user, type=Task.

## update — Update issue fields

```bash
scripts/update.sh <KEY> <field=value> [field=value ...]
```

| Field | Example |
|-------|---------|
| status | `status=Closed` |
| sp | `sp=3` |
| priority | `priority=Major` |
| activity | `activity=Product / Portfolio Work` |
| component | `component=Global Hub` |
| parent | `parent=ACM-30822` |
| sprint | `sprint=current` |
| assignee | `assignee=-1` (-1 = current user) |
| link | `link=https://github.com/.../pull/42` |

All fields run in parallel. Custom field IDs resolved dynamically.

Activity Type values: `Associate Wellness & Development`, `Future Sustainability`, `Incidents & Support`, `Quality / Stability / Reliability`, `Security & Compliance`, `Product / Portfolio Work`

## link — Link issue to URL or set parent

```bash
scripts/link.sh <KEY> <URL_OR_ISSUE_KEY> [custom_title]
```

Auto-detects URL type for title: GitHub PR -> `PR #N - repo`, GitLab MR -> `MR !N - repo`, Google Drive -> `Google Drive`, Blog -> `Blog: slug`. If target is an issue key, sets it as parent instead.

## jira-ops CLI — Direct Jira API operations

The `jira-ops` CLI is bundled at `scripts/jira-ops`. Use it for any operation not covered by the high-level scripts above.

```bash
# Issue operations
scripts/jira-ops issue get <key> [fields]
scripts/jira-ops issue search <jql> [fields] [max]
scripts/jira-ops issue create <json-payload>
scripts/jira-ops issue update <key> <json-payload>
scripts/jira-ops issue delete <key>
scripts/jira-ops issue get-field <key> <field-name>
scripts/jira-ops issue set-field <key> <field-name> <val>
scripts/jira-ops issue transition <key> <status>
scripts/jira-ops issue transitions <key>
scripts/jira-ops issue link <type> <from> <to>
scripts/jira-ops issue comment <key> <text>
scripts/jira-ops issue comment-delete <key> <comment-id>
scripts/jira-ops issue remote-link <key> <url> <title>

# Sprint / Board
scripts/jira-ops board list <project> [max]
scripts/jira-ops sprint list <board-id>
scripts/jira-ops sprint issues <sprint-id> [fields] [max]
scripts/jira-ops sprint move <sprint-id> <keys...>

# Custom field mapping
scripts/jira-ops field discover
scripts/jira-ops field search <pattern>
scripts/jira-ops field get <name>

# Global flag: --json outputs raw JSON
scripts/jira-ops --json issue get ACM-123
```

## jira-ops.sh Library — For custom scripts

Source `scripts/jira-ops.sh` to use library functions directly. See `references/api-reference.md` for the full function reference (CRUD, search, transitions, ADF builders, sprint operations, URL title detection).

```bash
source "${CLAUDE_SKILL_DIR}/scripts/jira-ops.sh"
jira_search 'project = ACM AND status = Open'
ISSUE_KEY=$(jira_create_issue "$payload") || exit 1
jira_transition "$ISSUE_KEY" "In Progress"
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `JIRA_USER` | Yes | Atlassian account email |
| `JIRA_API_TOKEN` | Yes | API token (not password) |
| `JIRA_BASE_URL` | Yes | e.g. `https://your-domain.atlassian.net` |
| `JIRA_AUTH_TYPE` | No | `basic-header` (default), `basic`, `bearer` |

## Key Reminders

- Auth: Basic Auth with API tokens. Default `basic-header` works through corporate proxies
- Description/comments require ADF JSON — use `adf_*` builder functions in library mode
- Epic parent: use `parent` field, not legacy custom fields
- Sprint: cannot be set via REST API PUT — use `jira-ops sprint move` or `jira_move_to_sprint`
- Search: uses `/rest/api/3/search/jql` (GET), not the deprecated POST endpoint
- Custom fields: run `jira-ops field discover` once, then use `jira-ops field get "Story Points"` to look up IDs
