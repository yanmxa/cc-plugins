# Jira Ops API Reference

Detailed function signatures, parameters, and examples for `jira-ops.sh`.

## Table of Contents

1. [Transport Layer](#transport-layer)
2. [Custom Field Mapping](#custom-field-mapping)
3. [Issue CRUD](#issue-crud)
4. [Search](#search)
5. [Workflow Transitions](#workflow-transitions)
6. [Issue Links](#issue-links)
7. [Remote Links](#remote-links)
8. [Comments](#comments)
9. [Agile / Sprint](#agile--sprint)
10. [ADF Builders](#adf-builders)
11. [v3 API Notes](#v3-api-notes)

---

## Transport Layer

### `jira_request METHOD ENDPOINT [PAYLOAD]`

Low-level HTTP request with auth and 429 retry. Sets `RESPONSE_BODY` and `RESPONSE_CODE` globals.

- Auth controlled by `JIRA_AUTH_TYPE`: `basic-header` (default), `basic`, `bearer`
- Retries on 429 with exponential backoff (5s -> 80s, max 5 attempts)
- Uses temp file for response body (cross-shell compatible)

```bash
jira_request GET "/rest/api/3/issue/ACM-123"
jira_request POST "/rest/api/3/issue" "$json_payload"
```

### `jira_check_response EXPECTED_CODE [CONTEXT]`

Validate `RESPONSE_CODE`. Returns 1 on mismatch with error details to stderr.

```bash
jira_request POST "/rest/api/3/issue" "$payload"
jira_check_response "201" "Create issue" || exit 1
```

## Custom Field Mapping

### `jira_discover_fields [OUTPUT_FILE]`

Query `/rest/api/3/field`, build `{name: id}` mapping, save to JSON file.
Default output: `<script-dir>/field-mapping.json`

```bash
jira_discover_fields                    # save to default location
jira_discover_fields "/tmp/fields.json" # save to custom location
```

### `jira_field_id FIELD_NAME`

Look up field ID by name. Auto-discovers if mapping doesn't exist.

```bash
sp_field=$(jira_field_id "Story Points")  # -> customfield_10028
jira_update_issue "ACM-123" "{\"fields\":{\"${sp_field}\":3}}"
```

### `jira_field_search PATTERN`

Search field names by pattern (case-insensitive). For interactive discovery.

```bash
jira_field_search "story"   # -> Story Points: customfield_10028
jira_field_search "sprint"  # -> Sprint: customfield_10020
```

## Issue CRUD

### `jira_create_issue PAYLOAD` -> issue key on stdout

```bash
payload=$(jq -n '{fields:{project:{key:"ACM"},summary:"Test",issuetype:{name:"Task"}}}')
ISSUE_KEY=$(jira_create_issue "$payload") || exit 1
```

### `jira_get_issue ISSUE_KEY [FIELDS]`

Sets `RESPONSE_BODY` with issue JSON. Optional comma-separated fields filter.

```bash
jira_get_issue "ACM-123" "summary,status,parent"
echo "$RESPONSE_BODY" | jq '.fields.summary'
```

### `jira_update_issue ISSUE_KEY PAYLOAD`

```bash
jira_update_issue "ACM-111" '{"fields":{"parent":{"key":"ACM-100"}}}'

# Update custom field by name
sp=$(jira_field_id "Story Points")
jira_update_issue "ACM-111" "{\"fields\":{\"${sp}\":5}}"
```

### `jira_delete_issue ISSUE_KEY`

## Search

### `jira_search JQL [FIELDS] [MAX_RESULTS]`

GET `/rest/api/3/search/jql`. Sets `RESPONSE_BODY`.

```bash
jira_search 'project = ACM AND status = Open'
jira_search 'assignee = currentUser()' 'key,summary,status' 50
echo "$RESPONSE_BODY" | jq '.issues[].key'
```

## Workflow Transitions

### `jira_get_transitions ISSUE_KEY`

### `jira_transition ISSUE_KEY TARGET_STATUS`

Looks up transition ID by name automatically.

```bash
jira_transition "ACM-123" "In Progress"
jira_transition "ACM-123" "Done"
```

## Issue Links

### `jira_link_issues LINK_TYPE INWARD_KEY OUTWARD_KEY`

Types: "Related", "Blocks", "Cloners", "Duplicate", "Test"

```bash
jira_link_issues "Blocks" "ACM-100" "ACM-200"
```

## Remote Links

### `jira_add_remote_link ISSUE_KEY URL TITLE [ICON_URL]`

Attach PR/MR URLs to issues.

```bash
jira_add_remote_link "ACM-123" "https://github.com/org/repo/pull/42" "PR #42: fix auth"
```

## Comments

### `jira_add_comment ISSUE_KEY COMMENT_ADF`

Comment body must be ADF format. Use `adf_doc` + `adf_paragraph` builders.

```bash
comment=$(adf_doc "[$(adf_paragraph \"Build passed\")]")
jira_add_comment "ACM-123" "$comment"
```

### `jira_delete_comment ISSUE_KEY COMMENT_ID`

## Agile / Sprint

These use `/rest/agile/1.0` API (not REST API v3).

### `jira_get_boards PROJECT_KEY [MAX]`
### `jira_get_active_sprints BOARD_ID`
### `jira_get_sprint_issues SPRINT_ID [FIELDS] [MAX]`

### `jira_move_to_sprint SPRINT_ID ISSUE_KEYS...`

Sprint cannot be set via REST API PUT -- this Agile endpoint is the only way.

```bash
jira_move_to_sprint 34330 "ACM-123" "ACM-456"
```

## ADF Builders

v3 requires ADF (Atlassian Document Format) for rich text fields.

| Function | Returns |
|----------|---------|
| `adf_doc CONTENT_ARRAY` | Complete ADF document |
| `adf_paragraph TEXT` | Paragraph node |
| `adf_heading LEVEL TEXT` | Heading node (1-6) |
| `adf_text TEXT` | Plain text node |
| `adf_bold_text TEXT` | Bold text node |
| `adf_link_text TEXT URL` | Linked text node |
| `adf_kv_item KEY VALUE` | "**Key:** value" list item |
| `adf_link_item TEXT URL` | Linked list item |
| `adf_bullet_list ITEMS_ARRAY` | Bullet list |
| `adf_table_header_row HEADERS` | Table header row |
| `adf_table_row CELLS` | Table data row |
| `adf_table ROWS_ARRAY` | Table wrapper |

Composition pattern:
```bash
desc=$(adf_doc "[$(adf_heading 2 "Release"), $(adf_paragraph "Details here")]")
```

## v3 API Notes

- **Description/comments**: Must use ADF JSON, not plain text
- **Search**: Use `/rest/api/3/search/jql` (GET). The older `/rest/api/3/search` POST is deprecated
- **Epic parent**: Use `parent` field, not `customfield_12311140`
- **User reference**: Use `accountId`, not `name` or `key`
- **Auth**: Basic Auth with API tokens. Do NOT use Bearer for Jira Cloud API token auth
- **Rate limiting**: HTTP 429 -- library auto-retries with exponential backoff
