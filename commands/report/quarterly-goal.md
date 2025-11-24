---
argument-hint: [goal-topic] [percentage-target] (e.g., "AI automation" "30")
description: Create a quarterly goal statement based on a simple template
allowed-tools: []
---

Create a concise quarterly goal statement following a proven template format. This command helps you quickly draft professional, measurable goals for personal development or team objectives.

## Implementation Steps

1. **Gather Information**: Ask the user for:
   - Goal topic/focus area (e.g., "AI automation", "code quality", "team collaboration")
   - Target percentage or metric if applicable (default: 30%)
   - Specific tasks or areas to focus on (e.g., "PR submissions, Jira operations")
   - Whether this includes team sharing component

2. **Generate Goal Statement**: Create a goal following this template structure:
   - Title: Brief, clear heading
   - Opening: "My goal for this quarter is to use [method] to [achieve] more than [X%] of [target area]"
   - Tasks: List 2-4 specific tasks or focus areas
   - Validation: "I will track my time to confirm this method enhances my productivity by [benefit]"
   - Team impact (optional): "Additionally, I will share and promote [workflows/practices] with the team to improve overall team efficiency"

3. **Present Goal**: Output the formatted goal statement as copyable text for the user

## Usage Examples

- `/report/quarterly-goal "AI automation" 30` - Create goal for AI-driven workflow automation with 30% target
- `/report/quarterly-goal "code review efficiency" 40` - Create goal for improving code review process
- `/report/quarterly-goal "testing coverage"` - Create goal with default 30% target

## Template Structure

```
# [Goal Title]

My goal for this quarter is to use [method/approach] to [accomplish] more than [X%] of [target area], such as [task 1], [task 2], and [task 3]. I will track my time to confirm this method enhances my productivity by [specific benefit]. Additionally, I will share and promote [deliverable] with the team to improve overall team efficiency.
```

## Notes

- Keep goals concise and focused (3-5 sentences max)
- Include measurable targets (percentages, time saved, etc.)
- Specify concrete tasks and deliverables
- Consider both personal and team impact
- Default to conservative targets (30%) for realistic achievement
