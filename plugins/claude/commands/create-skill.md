---
argument-hint: [skill-name] or leave empty for interactive creation
description: Create a new Claude skill based on recent session workflow or conversation history
allowed-tools: [Write, Read, Glob, Bash, AskUserQuestion]
---

Create a new Claude skill that extends Claude's capabilities through modular instructions and supporting files. Skills are model-invoked (Claude autonomously decides when to use them) based on the description and context.

## Usage Examples

- `pdf-extractor` - Create a skill for extracting PDF content
- `api-testing` - Create a skill for API testing workflows
- Leave empty - Interactive mode with guided questions

## Skill Creation Process

1. **Determine Mode**: If skill name provided, use auto mode; otherwise, use interactive mode

2. **Interactive Mode** (no arguments):
   - Ask user about the skill's purpose and when it should be used
   - Ask what tools/capabilities the skill needs (Read, Write, Bash, etc.)
   - Ask if there are specific examples or workflows to include
   - Analyze recent conversation history to extract patterns

3. **Auto Mode** (skill name provided):
   - Analyze recent session messages and tool calls
   - Extract workflow patterns and common steps
   - Identify tools used and create appropriate restrictions
   - Generate skill based on detected patterns

4. **Generate Skill Structure**:
   - Create skill directory: `~/.claude/skills/$1/`
   - Write `SKILL.md` with YAML frontmatter and instructions
   - Optionally create supporting files (`reference.md`, `examples.md`, `scripts/`)

5. **Verify and Test**:
   - Check YAML syntax validity
   - Verify file paths are correct (Unix-style forward slashes)
   - Confirm skill description is specific and includes activation triggers

## Skill Types

**Personal Skills**: `~/.claude/skills/skill-name/`
- Available across all projects
- For individual workflows

**Project Skills**: `./.claude/skills/skill-name/`
- Shared with team via git
- For project-specific expertise

## SKILL.md Template Structure

```yaml
---
name: skill-name
description: Clear description of WHAT this does AND WHEN to use it. Include specific keywords and triggers for discoverability.
allowed-tools: [List, Of, Tools]  # Optional: restrict to specific tools
---

# Skill Name

Brief overview of the skill's purpose.

## When to Use This Skill

- Specific scenario 1
- Specific scenario 2
- Clear trigger conditions

## Instructions

Step-by-step guidance for Claude:

1. **Step Name**: Detailed description of what to do
   - Sub-step or consideration
   - Expected outcome

2. **Next Step**: Continue with clear actions

## Examples

### Example 1: [Scenario Name]
```
[Code or command example]
```

### Example 2: [Another Scenario]
```
[Code or command example]
```

## Best Practices

- Guideline 1
- Guideline 2
- Common pitfalls to avoid

## Tool Usage

[If applicable, describe how to use specific tools effectively]

## Output Format

[If applicable, describe expected output format]
```

## Description Best Practices

**Poor**: "Helps with documents"
**Good**: "Extract text and tables from PDFs, fill forms, merge documents. Use when working with PDF files, document processing, or form automation."

**Poor**: "Testing tool"
**Good**: "Run automated API tests with request/response validation. Use when testing REST endpoints, validating API responses, or debugging HTTP requests."

## Interactive Questions

When in interactive mode, ask:

1. **Purpose Question**:
   - Header: "Skill Purpose"
   - Question: "What should this skill help you accomplish?"
   - Options:
     - "Automate a repetitive task" - Streamline workflows you do often
     - "Add domain expertise" - Provide specialized knowledge in a field
     - "Integrate external tools" - Connect with APIs, CLIs, or services
     - "Improve code quality" - Review, test, or refactor code

2. **Activation Question**:
   - Header: "When to Use"
   - Question: "When should Claude automatically invoke this skill?"
   - Options:
     - "Specific keywords" - Trigger on certain terms or phrases
     - "File patterns" - Activate for specific file types/extensions
     - "Task context" - Use when user requests certain operations
     - "Always available" - Let Claude decide based on context

3. **Tools Question** (multiSelect: true):
   - Header: "Required Tools"
   - Question: "Which tools should this skill have access to?"
   - Options:
     - "File operations" - Read, Write, Edit, Glob
     - "Shell commands" - Bash execution
     - "Web access" - WebFetch, WebSearch
     - "All tools" - No restrictions (don't set allowed-tools)

4. **Examples Question**:
   - Header: "Examples"
   - Question: "Should we extract examples from recent conversation?"
   - Options:
     - "Yes, use recent workflow" - Analyze and extract from history
     - "I'll provide examples" - Let me describe specific cases
     - "Skip examples for now" - Just create basic structure
     - "Include both" - Use history and let me add more

## Workflow Extraction Logic

When extracting from recent conversation:

1. **Identify Tool Patterns**:
   - Track frequently used tools (Read, Write, Bash, etc.)
   - Note file patterns (e.g., `**/*.py`, `*.md`)
   - Extract common commands or operations

2. **Detect Step Sequences**:
   - Find repeated action sequences
   - Group related operations together
   - Identify decision points or conditions

3. **Extract Examples**:
   - Capture actual commands run
   - Include file paths and patterns used
   - Preserve successful workflows

4. **Generate Instructions**:
   - Convert patterns into reusable steps
   - Replace specific values with placeholders
   - Add context and rationale

## Supporting Files

Optionally create additional files:

- `reference.md` - Detailed technical documentation
- `examples.md` - Additional usage examples
- `scripts/` - Utility scripts (Python, Bash, etc.)
- `templates/` - Reusable file templates

## Validation Checks

Before finalizing:

1. **YAML Frontmatter**:
   - Valid syntax (proper indentation, quotes)
   - Required fields present (name, description)
   - Tools list properly formatted

2. **Description Quality**:
   - Includes both WHAT and WHEN
   - Contains specific keywords for discoverability
   - Avoids vague terms like "helps with" or "tool for"

3. **Instructions Clarity**:
   - Steps are numbered and descriptive
   - Examples are concrete and runnable
   - Best practices are actionable

4. **File Paths**:
   - Use forward slashes (Unix style)
   - Absolute paths when needed
   - Verify directory exists

## Output Format

After creation, provide:

```
✅ Skill created successfully: skill-name
   Location: ~/.claude/skills/skill-name/
   Files created:
   - SKILL.md
   - [reference.md if applicable]
   - [examples.md if applicable]

📝 Next Steps:
   1. Review the skill description for clarity
   2. Test the skill by triggering its use case
   3. Refine based on actual usage
   4. Consider adding to project if team-relevant

🔍 To use this skill:
   Just mention the use case naturally, and Claude will invoke it automatically
   Example: "Help me [skill use case]"
```

## Notes

- Skills are invoked automatically by Claude based on context, not by user commands
- Keep skills focused on ONE specific capability for better discoverability
- Test skills with team members before sharing project skills
- Use `allowed-tools` to restrict capabilities and improve security
- Skills can include scripts in any language (Python, Bash, JavaScript, etc.)
- Skills are loaded dynamically - no restart needed after creation

## Examples

```bash
# Interactive mode - guided creation
/claude:create-skill

# Auto mode - extract from recent PDF work
/claude:create-skill pdf-processor

# Auto mode - create testing skill
/claude:create-skill api-integration-tester

# Auto mode - create from Jira workflow
/claude:create-skill jira-automation
```

## Debugging Skills

If Claude doesn't use your skill:

1. Make description more specific with concrete keywords
2. Verify file exists at correct path: `ls -la ~/.claude/skills/skill-name/`
3. Check YAML syntax: `head -20 ~/.claude/skills/skill-name/SKILL.md`
4. Ensure skills don't overlap in scope
5. Test with explicit mention: "Use the [skill-name] skill to..."

## Skill Categories

Common skill categories to consider:

- **Document Processing**: PDF, DOCX, XLSX, PPTX manipulation
- **Testing & QA**: Automated testing, API validation, debugging
- **Integration**: External API/CLI integration, webhook handling
- **Code Quality**: Linting, formatting, review automation
- **Workflow Automation**: Git operations, CI/CD, deployment
- **Domain Expertise**: Security auditing, performance optimization, accessibility
- **Communication**: Report generation, documentation, status updates
