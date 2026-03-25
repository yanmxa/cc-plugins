#!/usr/bin/env python3
"""Format Jira issues JSON into grouped markdown tables.

Usage: echo "$JSON" | python3 _format_issues.py [--labels] [--sprint-mark]

Options:
  --labels       Include Labels column (used by sprint.sh)
  --sprint-mark  Prefix titles with pin emoji for active sprint issues (used by issues.sh)

Environment variables (field IDs):
  SP_FIELD       Story Points custom field ID
  AT_FIELD       Activity Type custom field ID
  SPRINT_FIELD   Sprint custom field ID (only needed with --sprint-mark)
"""

import sys, json, re, os
from collections import defaultdict

# Parse flags
show_labels = '--labels' in sys.argv
show_sprint_mark = '--sprint-mark' in sys.argv

# Read and clean input (strip ANSI codes, fix invalid escapes)
raw = sys.stdin.read()
raw = re.sub(r'\x1b\[[0-9;]*m', '', raw)
raw = re.sub(r'\\(?!["\\\/bfnrtu])', r'\\\\', raw)
data = json.loads(raw, strict=False)

issues = data.get('issues', [])

# Sort by status then priority
STATUS_ORDER = {'New': 0, 'In Progress': 1, 'Code Review': 2, 'Resolved': 3, 'Closed': 4}
PRIORITY_ORDER = {'Blocker': 0, 'Critical': 1, 'Major': 2, 'Normal': 3, 'Minor': 4, 'Undefined': 5}
PRIORITY_DOT = {
    'Blocker': '\U0001f534',   # red
    'Critical': '\U0001f534',  # red
    'Major': '\U0001f7e0',     # orange
    'Normal': '\U0001f535',    # blue
    'Minor': '\u26aa',         # white
}

issues.sort(key=lambda i: (
    STATUS_ORDER.get(i['fields']['status']['name'], 9),
    PRIORITY_ORDER.get((i['fields'].get('priority') or {}).get('name', ''), 9)
))

sp_field = os.environ.get('SP_FIELD', 'customfield_10028')
at_field = os.environ.get('AT_FIELD', 'customfield_10464')
sprint_field = os.environ.get('SPRINT_FIELD', 'customfield_10020')

jira_url = 'https://issues.redhat.com/browse'
stats = defaultdict(lambda: {'count': 0, 'sp': 0})
grouped = defaultdict(list)

for i in issues:
    f = i['fields']
    typ = (f.get('issuetype') or {}).get('name', '')
    key = i['key']
    summary = (f.get('summary') or '')[:60]
    if len(f.get('summary', '') or '') > 60:
        summary += '...'
    status = (f.get('status') or {}).get('name', '')
    priority = (f.get('priority') or {}).get('name', '')
    dot = PRIORITY_DOT.get(priority, '')
    sp_val = f.get(sp_field) or ''
    sp_str = str(sp_val) if sp_val not in ('', None) else ''
    if sp_str == 'None':
        sp_str = ''
    act = f.get(at_field)
    activity = act.get('value', '') if isinstance(act, dict) else ''
    components = ', '.join(c['name'] for c in (f.get('components') or []))

    affects = [v['name'] for v in (f.get('versions') or [])]
    fixed = [v['name'] for v in (f.get('fixVersions') or [])]
    ver_parts = []
    if affects:
        ver_parts.append('A:' + ','.join(affects))
    if fixed:
        ver_parts.append('F:' + ','.join(fixed))
    versions = ' '.join(ver_parts)

    # Key column with parent link
    parent_key = (f.get('parent') or {}).get('key', '')
    sep = '/' if not show_labels else ' - '
    if parent_key:
        key_col = f'[{parent_key}]({jira_url}/{parent_key}){sep}[{key}]({jira_url}/{key})'
    else:
        key_col = f'[{key}]({jira_url}/{key})'

    # Sprint mark for issues.sh
    title_prefix = ''
    if show_sprint_mark:
        sprints = f.get(sprint_field) or []
        in_active = any(s.get('state') == 'active' for s in sprints if isinstance(s, dict))
        if in_active:
            title_prefix = '\U0001f4cc '

    # Build row
    row = f'| {typ} | {dot} | {key_col} | {title_prefix}{summary} | {sp_str} | {activity} | {components} | {versions} |'
    if show_labels:
        labels = ', '.join(f.get('labels') or [])
        row = f'| {typ} | {dot} | {key_col} | {summary} | {sp_str} | {activity} | {components} | {versions} | {labels} |'
    grouped[status].append(row)

    sp_num = float(sp_val) if sp_val and str(sp_val) not in ('', 'None') else 0
    stats[status]['count'] += 1
    stats[status]['sp'] += sp_num

total_count = sum(v['count'] for v in stats.values())
total_sp = sum(v['sp'] for v in stats.values())
print(f'**{total_count} issues | {total_sp:.0f} SP**')
print()

# Table headers
if show_labels:
    header = '| Type | Pri | Key | Title | SP | Activity | Components | Versions | Labels |'
    sep_line = '|------|-----|-----|-------|----|----------|------------|----------|--------|'
else:
    header = '| Type | Pri | Key | Title | SP | Activity | Components | Versions |'
    sep_line = '|------|-----|-----|-------|----|----------|------------|----------|'

for s in sorted(grouped.keys(), key=lambda x: STATUS_ORDER.get(x, 9)):
    cnt = stats[s]['count']
    sp = stats[s]['sp']
    print(f'### {s} ({cnt} issues | {sp:.0f} SP)')
    print()
    print(header)
    print(sep_line)
    for row in grouped[s]:
        print(row)
    print()
