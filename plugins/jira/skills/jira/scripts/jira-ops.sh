#!/bin/bash
# jira-ops.sh — Reusable Jira Cloud REST API v3 shell library
#
# Provides higher-level functions for common Jira operations:
#   - Issue CRUD (create, get, update, delete)
#   - JQL search
#   - Workflow transitions
#   - Issue linking
#   - Comments
#   - ADF (Atlassian Document Format) builders
#
# Authentication: Basic Auth with API tokens
#   https://developer.atlassian.com/cloud/jira/platform/basic-auth-for-rest-apis/
#
# API Reference: Jira Cloud REST API v3
#   https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/
#
# Required environment variables:
#   JIRA_USER      - Atlassian account email
#   JIRA_API_TOKEN     - API token (https://id.atlassian.com/manage-profile/security/api-tokens)
#   JIRA_BASE_URL  - e.g., https://your-domain.atlassian.net
#
# Usage:
#   source /path/to/jira-ops.sh
#   jira_create_issue "$payload"   # returns issue key
#   jira_search "project = ACM"    # sets RESPONSE_BODY
#
# All functions set two globals after each HTTP call:
#   RESPONSE_BODY  - Response body (JSON)
#   RESPONSE_CODE  - HTTP status code

# ============================================================
# Colors (safe for non-tty — only used for stderr messages)
# ============================================================
_JO_RED='\033[0;31m'
_JO_GREEN='\033[0;32m'
_JO_YELLOW='\033[1;33m'
_JO_NC='\033[0m'

# ============================================================
# Transport Layer
# ============================================================

# jira_request METHOD ENDPOINT [PAYLOAD]
#
# Low-level HTTP request with Basic Auth and 429 retry.
# Sets RESPONSE_BODY and RESPONSE_CODE globals.
# Retries on HTTP 429 with exponential backoff (5s → 80s, max 5 attempts).
#
# Examples:
#   jira_request GET "/rest/api/3/issue/ACM-123"
#   jira_request POST "/rest/api/3/issue" "$json_payload"
#   jira_request PUT "/rest/api/3/issue/ACM-123" "$update_payload"
jira_request() {
    local method="$1" endpoint="$2" payload="${3:-}"
    local max_retries=5 retry_delay=5

    # Auth: JIRA_AUTH_TYPE controls method (default: basic-header)
    #   basic-header  — explicit Base64 Authorization header (works through proxies)
    #   basic         — curl -u (simpler, may fail through some proxies)
    #   bearer        — Bearer token (for OAuth2 / PAT)
    local auth_type="${JIRA_AUTH_TYPE:-basic-header}"
    local auth_args=()
    case "$auth_type" in
        basic-header)
            local auth_b64
            auth_b64=$(echo -n "${JIRA_USER}:${JIRA_API_TOKEN}" | base64)
            auth_args+=(-H "Authorization: Basic ${auth_b64}")
            ;;
        basic)
            auth_args+=(-u "${JIRA_USER}:${JIRA_API_TOKEN}")
            ;;
        bearer)
            auth_args+=(-H "Authorization: Bearer ${JIRA_API_TOKEN}")
            ;;
    esac

    # Use temp file for response body — avoids fragile stdout splitting
    # that breaks under zsh, large responses, or unusual shell settings
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/jira-ops.XXXXXX")
    trap "rm -f '$tmpfile'" RETURN 2>/dev/null || true

    local args=(-s -o "$tmpfile" -w "%{http_code}" -X "$method"
        "${auth_args[@]}"
        -H "Content-Type: application/json"
        -H "Accept: application/json"
        "${JIRA_BASE_URL}${endpoint}")
    [[ -n "$payload" ]] && args+=(-d "$payload")

    for attempt in $(seq 1 $max_retries); do
        RESPONSE_CODE=$(curl "${args[@]}" 2>/dev/null)
        RESPONSE_BODY=$(cat "$tmpfile")

        if [[ "$RESPONSE_CODE" != "429" ]]; then
            rm -f "$tmpfile"
            return 0
        fi

        if [[ $attempt -lt $max_retries ]]; then
            echo -e "  ${_JO_YELLOW}Rate limited (429), retrying in ${retry_delay}s (attempt ${attempt}/${max_retries})...${_JO_NC}" >&2
            sleep "$retry_delay"
            retry_delay=$((retry_delay * 2))
        fi
    done

    rm -f "$tmpfile"
    echo -e "  ${_JO_RED}Rate limit exhausted after ${max_retries} retries${_JO_NC}" >&2
    return 1
}

# jira_check_response EXPECTED_CODE [CONTEXT]
#
# Validate RESPONSE_CODE against expected value.
# On mismatch, prints error with context and pretty-printed response body to stderr.
# Returns 0 on match, 1 on mismatch.
#
# Example:
#   jira_request POST "/rest/api/3/issue" "$payload"
#   jira_check_response "201" "Create issue" || exit 1
jira_check_response() {
    local expected="$1" context="${2:-Jira API call}"
    if [[ "$RESPONSE_CODE" != "$expected" ]]; then
        echo -e "${_JO_RED}${context} failed (HTTP ${RESPONSE_CODE}):${_JO_NC}" >&2
        echo "$RESPONSE_BODY" | jq . 2>/dev/null >&2 || echo "$RESPONSE_BODY" >&2
        return 1
    fi
}

# ============================================================
# Custom Field Mapping
#
# Jira custom fields have opaque IDs (e.g., customfield_10028).
# These functions discover and cache the name→ID mapping so
# scripts can use human-readable names like "Story Points".
# ============================================================

# Default location: same directory as this script
_JIRA_OPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
JIRA_FIELD_MAP="${JIRA_FIELD_MAP:-${_JIRA_OPS_DIR}/field-mapping.json}"

# jira_discover_fields [OUTPUT_FILE]
#
# Query /rest/api/3/field to get all fields (built-in + custom),
# build a name→id mapping, and save it to a JSON file.
# Run this once per Jira instance to bootstrap the mapping.
#
# Example:
#   jira_discover_fields
#   jira_discover_fields "/tmp/my-fields.json"
jira_discover_fields() {
    local output="${1:-$JIRA_FIELD_MAP}"
    local output_dir
    output_dir=$(dirname "$output")
    [[ -d "$output_dir" ]] || mkdir -p "$output_dir"

    jira_request GET "/rest/api/3/field"
    jira_check_response "200" "Discover fields" || return 1

    # Build { "Field Name": "field_id", ... } mapping
    echo "$RESPONSE_BODY" | jq 'map({(.name): .id}) | add' > "$output"

    local count
    count=$(jq 'length' "$output")
    echo -e "  ${_JO_GREEN}Saved ${count} field mappings to ${output}${_JO_NC}" >&2
}

# jira_field_id FIELD_NAME
#
# Look up a custom field ID by its human-readable name.
# Returns the field ID on stdout (e.g., "customfield_10028").
# Auto-discovers fields if the mapping file doesn't exist yet.
#
# Examples:
#   story_pts_field=$(jira_field_id "Story Points")
#   sprint_field=$(jira_field_id "Sprint")
#   jira_update_issue "ACM-123" "{\"fields\":{\"${story_pts_field}\":3}}"
jira_field_id() {
    local name="$1"

    # Auto-discover if mapping doesn't exist
    if [[ ! -f "$JIRA_FIELD_MAP" ]]; then
        echo -e "  ${_JO_YELLOW}Field mapping not found, discovering...${_JO_NC}" >&2
        jira_discover_fields || return 1
    fi

    local field_id
    field_id=$(jq -r --arg n "$name" '.[$n] // empty' "$JIRA_FIELD_MAP")

    if [[ -z "$field_id" ]]; then
        echo -e "  ${_JO_RED}Field '${name}' not found in mapping${_JO_NC}" >&2
        echo -e "  ${_JO_YELLOW}Run jira_discover_fields to refresh${_JO_NC}" >&2
        return 1
    fi

    echo "$field_id"
}

# jira_field_search PATTERN
#
# Search field names matching a pattern (case-insensitive grep).
# Useful for discovering field names interactively.
#
# Example:
#   jira_field_search "story"   # → "Story Points": "customfield_10028"
#   jira_field_search "sprint"  # → "Sprint": "customfield_10020"
jira_field_search() {
    local pattern="$1"

    if [[ ! -f "$JIRA_FIELD_MAP" ]]; then
        echo -e "  ${_JO_YELLOW}Field mapping not found, discovering...${_JO_NC}" >&2
        jira_discover_fields || return 1
    fi

    jq -r --arg p "$pattern" 'to_entries[] | select(.key | test($p; "i")) | "\(.key): \(.value)"' "$JIRA_FIELD_MAP"
}

# ============================================================
# Issue CRUD
# ============================================================

# jira_create_issue PAYLOAD
#
# Create a new Jira issue. Returns the issue key (e.g., "ACM-12345") on stdout.
# The payload must be a JSON string with the full issue fields.
#
# v3 note: description must be ADF format, use adf_* helpers to build it.
# v3 note: use "parent" field (not customfield) to set Epic parent.
#
# Example:
#   payload=$(jq -n '{fields:{project:{key:"ACM"},summary:"Test",issuetype:{name:"Task"}}}')
#   ISSUE_KEY=$(jira_create_issue "$payload") || exit 1
jira_create_issue() {
    local payload="$1"
    jira_request POST "/rest/api/3/issue" "$payload"
    jira_check_response "201" "Create issue" || return 1
    echo "$RESPONSE_BODY" | jq -r '.key'
}

# jira_get_issue ISSUE_KEY [FIELDS]
#
# Fetch an issue by key. Optionally specify comma-separated fields to reduce response size.
# Sets RESPONSE_BODY with the full issue JSON.
#
# Examples:
#   jira_get_issue "ACM-123"
#   jira_get_issue "ACM-123" "summary,status,parent"
#   echo "$RESPONSE_BODY" | jq '.fields.summary'
jira_get_issue() {
    local issue_key="$1" fields="${2:-}"
    local endpoint="/rest/api/3/issue/${issue_key}"
    [[ -n "$fields" ]] && endpoint="${endpoint}?fields=${fields}"
    jira_request GET "$endpoint"
    jira_check_response "200" "Get ${issue_key}" || return 1
}

# jira_update_issue ISSUE_KEY PAYLOAD
#
# Update an issue's fields. Accepts both "fields" and "update" style payloads.
# Returns 0 on success (HTTP 204 or 200).
#
# Examples:
#   # Set parent (link to Epic)
#   jira_update_issue "ACM-111" '{"fields":{"parent":{"key":"ACM-100"}}}'
#
#   # Update fixVersions
#   payload=$(jq -n --arg fv "v1.5.3" '{update:{fixVersions:[{set:[{name:$fv}]}]}}')
#   jira_update_issue "ACM-111" "$payload"
jira_update_issue() {
    local issue_key="$1" payload="$2"
    jira_request PUT "/rest/api/3/issue/${issue_key}" "$payload"
    if [[ "$RESPONSE_CODE" == "204" || "$RESPONSE_CODE" == "200" ]]; then
        return 0
    fi
    jira_check_response "204" "Update ${issue_key}"
    return 1
}

# jira_delete_issue ISSUE_KEY
#
# Delete an issue. Use with caution.
jira_delete_issue() {
    local issue_key="$1"
    jira_request DELETE "/rest/api/3/issue/${issue_key}"
    jira_check_response "204" "Delete ${issue_key}" || return 1
}

# ============================================================
# Search
# ============================================================

# jira_search JQL [FIELDS] [MAX_RESULTS]
#
# Search issues using JQL via GET /rest/api/3/search/jql.
# Sets RESPONSE_BODY with search results JSON.
#
# Note: The older POST /rest/api/3/search endpoint is deprecated.
#       This function uses the current GET /rest/api/3/search/jql endpoint.
#
# Examples:
#   jira_search 'project = ACM AND status = Open'
#   jira_search 'assignee = currentUser()' 'key,summary,status' 50
#   echo "$RESPONSE_BODY" | jq '.issues[].key'
jira_search() {
    local jql="$1" fields="${2:-key,summary,status}" max="${3:-100}"
    local encoded_jql
    encoded_jql=$(jq -rn --arg q "$jql" '$q|@uri')
    jira_request GET "/rest/api/3/search/jql?jql=${encoded_jql}&maxResults=${max}&fields=${fields}"
    jira_check_response "200" "Search" || return 1
}

# ============================================================
# Workflow Transitions
# ============================================================

# jira_get_transitions ISSUE_KEY
#
# List available transitions for an issue.
# Sets RESPONSE_BODY with transitions JSON.
#
# Example:
#   jira_get_transitions "ACM-123"
#   echo "$RESPONSE_BODY" | jq '.transitions[] | {id, name: .name}'
jira_get_transitions() {
    local issue_key="$1"
    jira_request GET "/rest/api/3/issue/${issue_key}/transitions"
    jira_check_response "200" "Get transitions for ${issue_key}" || return 1
}

# jira_transition ISSUE_KEY TARGET_STATUS
#
# Transition an issue to the named target status (e.g., "In Progress", "Done").
# Automatically looks up the transition ID by name.
# Returns 1 if the transition is not available for the issue's current state.
#
# Example:
#   jira_transition "ACM-123" "In Progress"
#   jira_transition "ACM-123" "Done"
jira_transition() {
    local issue_key="$1" target_status="$2"

    jira_request GET "/rest/api/3/issue/${issue_key}/transitions"
    if [[ "$RESPONSE_CODE" != "200" ]]; then
        echo -e "  ${_JO_RED}${issue_key}: Failed to get transitions (HTTP ${RESPONSE_CODE})${_JO_NC}" >&2
        return 1
    fi

    local tid
    tid=$(echo "$RESPONSE_BODY" | jq -r --arg s "$target_status" \
        '.transitions[] | select(.name == $s) | .id' | head -1)

    if [[ -z "$tid" || "$tid" == "null" ]]; then
        echo -e "  ${_JO_YELLOW}${issue_key}: '${target_status}' transition not available${_JO_NC}" >&2
        return 1
    fi

    jira_request POST "/rest/api/3/issue/${issue_key}/transitions" \
        "{\"transition\":{\"id\":\"${tid}\"}}"
    jira_check_response "204" "Transition ${issue_key} to ${target_status}" || return 1
}

# ============================================================
# Issue Links
# ============================================================

# jira_link_issues LINK_TYPE INWARD_KEY OUTWARD_KEY
#
# Create a link between two issues.
# Common link types: "Related", "Blocks", "Cloners", "Duplicate", "Test"
#
# The relationship reads as: INWARD_KEY <is linked to> OUTWARD_KEY
# For directional types like "Blocks": INWARD_KEY blocks OUTWARD_KEY
#
# Examples:
#   jira_link_issues "Related" "ACM-100" "ACM-200"
#   jira_link_issues "Test" "ACM-BUG" "ACM-TASK"     # BUG is tested by TASK
#   jira_link_issues "Blocks" "ACM-100" "ACM-200"     # 100 blocks 200
jira_link_issues() {
    local link_type="$1" inward_key="$2" outward_key="$3"
    local payload
    payload=$(jq -n --arg t "$link_type" --arg i "$inward_key" --arg o "$outward_key" \
        '{type:{name:$t},inwardIssue:{key:$i},outwardIssue:{key:$o}}')
    jira_request POST "/rest/api/3/issueLink" "$payload"
    jira_check_response "201" "Link ${inward_key} -> ${outward_key}" || return 1
}

# ============================================================
# Comments
# ============================================================

# jira_add_comment ISSUE_KEY COMMENT_ADF
#
# Add a comment to an issue. The comment body must be ADF format (v3 requirement).
# Use adf_doc + adf_paragraph to build simple comments.
#
# Example:
#   comment=$(adf_doc "[$(adf_paragraph "Build passed. PR: https://github.com/org/repo/pull/42")]")
#   jira_add_comment "ACM-123" "$comment"
jira_add_comment() {
    local issue_key="$1" comment_adf="$2"
    local payload
    payload=$(jq -n --argjson body "$comment_adf" '{body:$body}')
    jira_request POST "/rest/api/3/issue/${issue_key}/comment" "$payload"
    jira_check_response "201" "Add comment to ${issue_key}" || return 1
}

# jira_delete_comment ISSUE_KEY COMMENT_ID
#
# Delete a comment from an issue.
#
# Example:
#   jira_delete_comment "ACM-123" "16490675"
jira_delete_comment() {
    local issue_key="$1" comment_id="$2"
    jira_request DELETE "/rest/api/3/issue/${issue_key}/comment/${comment_id}"
    jira_check_response "204" "Delete comment ${comment_id} from ${issue_key}" || return 1
}

# ============================================================
# Remote Links (PR/MR association)
# ============================================================

# jira_add_remote_link ISSUE_KEY URL TITLE [ICON_URL]
#
# Attach an external URL (e.g., GitHub PR, GitLab MR) to an issue as a remote link.
# This is the standard way to associate PRs/MRs with Jira issues.
#
# Examples:
#   jira_add_remote_link "ACM-123" "https://github.com/org/repo/pull/42" "PR #42: fix auth"
#   jira_add_remote_link "ACM-123" "https://gitlab.com/org/repo/-/merge_requests/10" "MR !10" "https://gitlab.com/favicon.ico"
jira_add_remote_link() {
    local issue_key="$1" url="$2" title="$3" icon_url="${4:-}"
    local payload
    if [[ -n "$icon_url" ]]; then
        payload=$(jq -n --arg u "$url" --arg t "$title" --arg i "$icon_url" \
            '{object:{url:$u,title:$t,icon:{url16x16:$i}}}')
    else
        payload=$(jq -n --arg u "$url" --arg t "$title" \
            '{object:{url:$u,title:$t}}')
    fi
    jira_request POST "/rest/api/3/issue/${issue_key}/remotelink" "$payload"
    jira_check_response "201" "Add remote link to ${issue_key}" || return 1
}

# ============================================================
# Agile / Sprint (uses /rest/agile/1.0 API)
# ============================================================

# jira_get_boards PROJECT_KEY [MAX_RESULTS]
#
# List boards for a project.
# Sets RESPONSE_BODY with board list JSON.
#
# Example:
#   jira_get_boards "ACM"
#   echo "$RESPONSE_BODY" | jq '.values[] | "\(.id): \(.name)"'
jira_get_boards() {
    local project="$1" max="${2:-50}"
    jira_request GET "/rest/agile/1.0/board?projectKeyOrId=${project}&maxResults=${max}"
    jira_check_response "200" "Get boards for ${project}" || return 1
}

# jira_get_active_sprints BOARD_ID
#
# List active sprints for a board.
# Sets RESPONSE_BODY with sprint list JSON.
#
# Example:
#   jira_get_active_sprints 2697
#   echo "$RESPONSE_BODY" | jq '.values[] | "\(.id): \(.name)"'
jira_get_active_sprints() {
    local board_id="$1"
    jira_request GET "/rest/agile/1.0/board/${board_id}/sprint?state=active"
    jira_check_response "200" "Get active sprints for board ${board_id}" || return 1
}

# jira_get_sprint_issues SPRINT_ID [FIELDS] [MAX_RESULTS]
#
# List issues in a sprint.
# Sets RESPONSE_BODY with issue list JSON.
#
# Example:
#   jira_get_sprint_issues 34330 "key,summary,status,assignee" 50
#   echo "$RESPONSE_BODY" | jq '.issues[] | "\(.key): \(.fields.summary)"'
jira_get_sprint_issues() {
    local sprint_id="$1" fields="${2:-key,summary,status}" max="${3:-100}"
    jira_request GET "/rest/agile/1.0/sprint/${sprint_id}/issue?maxResults=${max}&fields=${fields}"
    jira_check_response "200" "Get issues for sprint ${sprint_id}" || return 1
}

# jira_move_to_sprint SPRINT_ID ISSUE_KEYS...
#
# Move one or more issues to a sprint. The sprint field cannot be set via
# /rest/api/3/issue — this Agile API endpoint is the only way.
#
# Examples:
#   jira_move_to_sprint 34330 "ACM-123"
#   jira_move_to_sprint 34330 "ACM-123" "ACM-456" "ACM-789"
jira_move_to_sprint() {
    local sprint_id="$1"; shift
    local issues_json
    issues_json=$(printf '%s\n' "$@" | jq -R . | jq -s '{issues:.}')
    jira_request POST "/rest/agile/1.0/sprint/${sprint_id}/issue" "$issues_json"
    jira_check_response "204" "Move issues to sprint ${sprint_id}" || return 1
}

# ============================================================
# ADF (Atlassian Document Format) Builders
#
# v3 requires ADF for rich text fields (description, comments).
# These helpers produce valid ADF JSON fragments that can be
# composed together and wrapped with adf_doc().
#
# Composition pattern:
#   1. Build content nodes (paragraphs, headings, list items)
#   2. Combine into arrays: "[$node1, $node2]"
#   3. Wrap with adf_doc: adf_doc "[$node1, $node2]"
# ============================================================

# adf_doc CONTENT_JSON_ARRAY
#
# Wrap content nodes in a valid ADF document envelope.
# Input: JSON array string of content nodes.
#
# Example:
#   adf_doc "[$(adf_paragraph "Hello"), $(adf_heading 2 "Section")]"
adf_doc() {
    local content="$1"
    jq -n --argjson c "$content" '{type:"doc",version:1,content:$c}'
}

# adf_paragraph TEXT
#
# Plain text paragraph node.
adf_paragraph() {
    local text="$1"
    jq -n --arg t "$text" \
        '{type:"paragraph",content:[{type:"text",text:$t}]}'
}

# adf_heading LEVEL TEXT
#
# Heading node (level 1-6).
adf_heading() {
    local level="$1" text="$2"
    jq -n --argjson l "$level" --arg t "$text" \
        '{type:"heading",attrs:{level:$l},content:[{type:"text",text:$t}]}'
}

# adf_bold_text TEXT
#
# Text node with bold mark. Returns a text node (not a paragraph).
# Wrap in a paragraph or list item as needed.
adf_bold_text() {
    local text="$1"
    jq -n --arg t "$text" '{type:"text",text:$t,marks:[{type:"strong"}]}'
}

# adf_link_text TEXT URL
#
# Text node with link mark.
adf_link_text() {
    local text="$1" url="$2"
    jq -n --arg t "$text" --arg u "$url" \
        '{type:"text",text:$t,marks:[{type:"link",attrs:{href:$u}}]}'
}

# adf_text TEXT
#
# Plain text node (no marks). Use inside paragraphs or list items.
adf_text() {
    local text="$1"
    jq -n --arg t "$text" '{type:"text",text:$t}'
}

# adf_kv_item KEY VALUE
#
# List item with "**Key:** Value" pattern — common in Jira descriptions.
# Returns a listItem node.
adf_kv_item() {
    local key="$1" value="$2"
    jq -n --arg k "${key}: " --arg v "$value" \
        '{type:"listItem",content:[{type:"paragraph",content:[
            {type:"text",text:$k,marks:[{type:"strong"}]},
            {type:"text",text:$v}
        ]}]}'
}

# adf_link_item TEXT URL
#
# List item with a single linked text. Useful for reference links.
adf_link_item() {
    local text="$1" url="$2"
    jq -n --arg t "$text" --arg u "$url" \
        '{type:"listItem",content:[{type:"paragraph",content:[
            {type:"text",text:$t,marks:[{type:"link",attrs:{href:$u}}]}
        ]}]}'
}

# adf_bullet_list ITEMS_JSON_ARRAY
#
# Bullet list wrapper. Input: JSON array of listItem nodes.
#
# Example:
#   items="[$(adf_kv_item "Version" "v1.5.3"), $(adf_kv_item "Type" "Z-Stream")]"
#   adf_bullet_list "$items"
adf_bullet_list() {
    local items="$1"
    jq -n --argjson i "$items" '{type:"bulletList",content:$i}'
}

# adf_table_row CELLS_ARRAY
#
# Table row from array of cell value strings (plain text).
# Each cell becomes a tableCell with a paragraph.
#
# Example:
#   adf_table_row '["Key", "Value", "Notes"]'
adf_table_row() {
    local cells="$1"
    echo "$cells" | jq '{type:"tableRow",content:[.[] | {type:"tableCell",content:[{type:"paragraph",content:[{type:"text",text:.}]}]}]}'
}

# adf_table_header_row HEADERS_ARRAY
#
# Table header row. Same as table_row but uses tableHeader cells.
adf_table_header_row() {
    local headers="$1"
    echo "$headers" | jq '{type:"tableRow",content:[.[] | {type:"tableHeader",content:[{type:"paragraph",content:[{type:"text",text:.}]}]}]}'
}

# adf_table ROWS_JSON_ARRAY
#
# Table wrapper. Input: JSON array of tableRow nodes (first row typically a header).
#
# Example:
#   header=$(adf_table_header_row '["Param", "Value"]')
#   row1=$(adf_table_row '["OCP_RELEASE", "4.15"]')
#   adf_table "[$header, $row1]"
adf_table() {
    local rows="$1"
    jq -n --argjson r "$rows" '{type:"table",attrs:{isNumberColumnEnabled:false,layout:"default"},content:$r}'
}

# ============================================================
# URL Title Detection
#
# Auto-detect a human-readable title from a URL.
# Used by link.sh and update.sh for remote link titles.
# ============================================================

# jira_url_title URL
#
# Detect URL type and return an appropriate title on stdout.
# GitHub PR -> "PR #N - repo", GitLab MR -> "MR !N - repo",
# Google Drive -> "Google Drive", Blog -> "Blog: slug",
# Other -> domain name.
#
# Example:
#   title=$(jira_url_title "https://github.com/org/repo/pull/42")
#   # -> "PR #42 - repo"
jira_url_title() {
    local url="$1"
    if echo "$url" | grep -qE 'github\.com/.*/pull/[0-9]+'; then
        local pr_num repo
        pr_num=$(echo "$url" | grep -oE 'pull/[0-9]+' | cut -d/ -f2)
        repo=$(echo "$url" | sed -E 's|.*github\.com/[^/]+/([^/]+)/.*|\1|')
        echo "PR #$pr_num - $repo"
    elif echo "$url" | grep -qE 'gitlab.*/-/merge_requests/[0-9]+'; then
        local mr_num repo
        mr_num=$(echo "$url" | grep -oE 'merge_requests/[0-9]+' | cut -d/ -f2)
        repo=$(echo "$url" | sed -E 's|.*/([^/]+)/-/.*|\1|')
        echo "MR !$mr_num - $repo"
    elif echo "$url" | grep -q 'drive.google.com'; then
        echo "Google Drive"
    elif echo "$url" | grep -q 'redhat.com/en/blog'; then
        local slug
        slug=$(echo "$url" | sed 's|.*/||' | tr '-' ' ')
        echo "Blog: $slug"
    else
        echo "$url" | sed -E 's|https?://([^/]+).*|\1|'
    fi
}
