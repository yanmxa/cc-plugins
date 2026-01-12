#!/bin/bash
# email-digest.sh - Fetch emails with parallel processing
# Usage:
#   email-digest.sh [time_range] [accounts]     - List emails
#   email-digest.sh --read account id1,id2,...  - Read email contents
#
# Arguments:
#   time_range: today, yesterday, last3days, last5days, or YYYY-MM-DD (default: today)
#   accounts: comma-separated account names or "all" (default: all)
#
# Examples:
#   email-digest.sh yesterday              # Yesterday's emails from all accounts
#   email-digest.sh today RedHat,163       # Today's emails from RedHat and 163
#   email-digest.sh --read RedHat 42590,42561,42538  # Read specific emails

set -euo pipefail

# Parse mode
MODE="list"
if [[ "${1:-}" == "--read" ]]; then
    MODE="read"
    shift
fi

if [[ "$MODE" == "read" ]]; then
    # Read email contents mode
    ACCOUNT="${1:?Account required}"
    IDS="${2:?Email IDs required (comma-separated)}"

    # Convert comma-separated IDs to AppleScript list format
    ID_LIST=$(echo "$IDS" | sed 's/,/, /g')

    osascript <<EOF 2>/dev/null
tell application "Mail"
    set idList to {$ID_LIST}
    set output to ""

    repeat with emailId in idList
        try
            set msg to first message of mailbox "INBOX" of account "$ACCOUNT" whose id is emailId
            set msgContent to content of msg
            set output to output & "---CONTENT:" & emailId & "---" & linefeed
            set output to output & msgContent & linefeed
        on error errMsg
            set output to output & "---CONTENT:" & emailId & "---" & linefeed
            set output to output & "[Error reading email: " & errMsg & "]" & linefeed
        end try
    end repeat

    return output
end tell
EOF
    exit 0
fi

# List emails mode
TIME_RANGE="${1:-today}"
ACCOUNTS="${2:-all}"

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Calculate date range based on time parameter
get_date_script() {
    local time_range="$1"
    case "$time_range" in
        today)
            echo 'set startDate to current date
set time of startDate to 0
set endDate to current date'
            ;;
        yesterday)
            echo 'set startDate to (current date) - 1 * days
set time of startDate to 0
set endDate to startDate + 1 * days - 1'
            ;;
        last3days)
            echo 'set startDate to (current date) - 3 * days
set time of startDate to 0
set endDate to current date'
            ;;
        last5days)
            echo 'set startDate to (current date) - 5 * days
set time of startDate to 0
set endDate to current date'
            ;;
        *)
            # Assume YYYY-MM-DD format
            echo "set startDate to date \"$time_range\"
set time of startDate to 0
set endDate to startDate + 1 * days - 1"
            ;;
    esac
}

DATE_SCRIPT=$(get_date_script "$TIME_RANGE")

# Function to fetch emails from a single account
fetch_account() {
    local account="$1"
    local output_file="$2"

    osascript <<EOF > "$output_file" 2>/dev/null || true
tell application "Mail"
    $DATE_SCRIPT

    set output to ""
    try
        set acct to account "$account"
        set inboxMailbox to mailbox "INBOX" of acct
        set theMessages to (every message of inboxMailbox whose date received >= startDate and date received <= endDate)

        repeat with msg in theMessages
            set output to output & "---EMAIL---" & linefeed
            set output to output & "ACCOUNT: $account" & linefeed
            set output to output & "ID: " & (id of msg) & linefeed
            set output to output & "FROM: " & (sender of msg) & linefeed
            set output to output & "SUBJECT: " & (subject of msg) & linefeed
            set output to output & "DATE: " & ((date received of msg) as string) & linefeed
            set output to output & "READ: " & (read status of msg) & linefeed
        end repeat
    on error errMsg
        set output to "---ERROR---" & linefeed & "ACCOUNT: $account" & linefeed & "MESSAGE: " & errMsg & linefeed
    end try

    return output
end tell
EOF
}

# Get list of accounts to process
if [[ "$ACCOUNTS" == "all" ]]; then
    ACCOUNT_LIST=$(osascript -e 'tell application "Mail" to get name of every account' 2>/dev/null | tr ',' '\n' | sed 's/^ *//' | xargs)
else
    ACCOUNT_LIST=$(echo "$ACCOUNTS" | tr ',' ' ')
fi

# Fetch emails from all accounts in parallel
PIDS=()
for account in $ACCOUNT_LIST; do
    fetch_account "$account" "$TEMP_DIR/${account//[^a-zA-Z0-9]/_}.txt" &
    PIDS+=($!)
done

# Wait for all background jobs
for pid in "${PIDS[@]}"; do
    wait "$pid" 2>/dev/null || true
done

# Combine results
cat "$TEMP_DIR"/*.txt 2>/dev/null || echo "No emails found"
