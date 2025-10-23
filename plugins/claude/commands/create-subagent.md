---
argument-hint: [subagent-name] or leave empty for interactive creation
description: Create a new Claude subagent based on recent session workflow or conversation history
allowed-tools: [Write, Read, Glob, Bash, AskUserQuestion, Grep]
---

Create a new Claude subagent - a specialized AI assistant with its own context window and custom configuration. Subagents are automatically invoked by Claude based on task context or can be explicitly requested.

## Usage Examples

- `code-reviewer` - Create a code review specialist subagent
- `api-tester` - Create an API testing subagent
- `spec-analyst` - Create a requirements analysis subagent
- Leave empty - Interactive mode with guided questions

## Subagent Creation Process

1. **Determine Mode**: If subagent name provided, use auto mode; otherwise, use interactive mode

2. **Interactive Mode** (no arguments):
   - Ask user about the subagent's role and specialization
   - Ask what tasks/scenarios should trigger this subagent
   - Ask what tools/capabilities the subagent needs
   - Ask what model to use (sonnet, opus, haiku, or inherit)
   - Analyze recent conversation history to extract workflow patterns

3. **Auto Mode** (subagent name provided):
   - Analyze recent session messages and tool calls
   - Extract workflow patterns, common steps, and decision points
   - Identify tools used frequently in the workflow
   - Detect domain/context from file patterns and commands
   - Generate subagent based on detected patterns

4. **Generate Subagent File**:
   - Create file: `~/.claude/agents/$1.md` (user-level) or `./.claude/agents/$1.md` (project-level)
   - Write YAML frontmatter with metadata
   - Craft detailed system prompt with role, responsibilities, and workflow
   - Include deliverable templates if applicable

5. **Verify and Test**:
   - Check YAML syntax validity
   - Verify description includes clear activation triggers
   - Confirm tools list is appropriate
   - Test invocation with example scenario

## Storage Locations

**User-Level**: `~/.claude/agents/subagent-name.md`
- Available across all projects
- For personal workflow automation

**Project-Level**: `./.claude/agents/subagent-name.md`
- Shared with team via git
- For project-specific expertise
- Higher priority than user-level (overrides on name conflict)

**Default**: User-level unless project context detected or user specifies

## Subagent File Structure

```markdown
---
name: subagent-identifier
description: Clear description of role AND when to invoke. Include specific keywords and scenarios for automatic activation.
tools: Read, Write, Bash, Grep, Glob  # Optional: comma-separated list
model: sonnet  # Optional: sonnet, opus, haiku, or inherit
---

# Role Definition

You are a [specific role] specializing in [domain/task]. When invoked, you [primary objective].

## Core Responsibilities

1. **[Responsibility 1]**: Detailed description of what you do
2. **[Responsibility 2]**: Another key responsibility
3. **[Responsibility 3]**: Additional responsibilities

## Workflow

When activated, follow these steps:

1. **Initial Analysis**:
   - Analyze the current state/context
   - Identify key issues or requirements
   - Ask clarifying questions if needed

2. **Main Task Execution**:
   - Perform primary task with specific approach
   - Use appropriate tools and techniques
   - Follow best practices and standards

3. **Quality Checks**:
   - Verify work meets criteria
   - Run tests/validations
   - Document findings

4. **Deliverables**:
   - Produce specific outputs
   - Provide recommendations
   - Update relevant documentation

## Best Practices

- [Best practice 1]
- [Best practice 2]
- [Common pitfall to avoid]

## Quality Criteria

- [Criterion 1]: [Standard/threshold]
- [Criterion 2]: [Standard/threshold]
- [Criterion 3]: [Standard/threshold]

## Output Format

[Template or structure for agent's deliverables]

## Example Scenarios

**Scenario 1**: [Description]
- Input: [What triggers this]
- Action: [What you do]
- Output: [What you produce]

**Scenario 2**: [Another scenario]
- Input: [Trigger]
- Action: [Process]
- Output: [Result]
```

## YAML Frontmatter Fields

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| **name** | Yes | Lowercase identifier with hyphens | `code-reviewer`, `api-tester` |
| **description** | Yes | Role + activation triggers + keywords | See examples below |
| **tools** | No | Comma-separated tool list; inherits all if omitted | `Read, Write, Bash` |
| **model** | No | Model alias or inherit from parent | `sonnet`, `opus`, `haiku`, `inherit` |

## Description Best Practices

**Poor**: "Helps review code"
**Good**: "Expert code review specialist. Reviews code for quality, security, and maintainability. Use immediately after writing or modifying code, before commits, or when refactoring."

**Poor**: "API testing tool"
**Good**: "API testing specialist. Validates REST endpoints, response schemas, error handling, and performance. Use when testing APIs, debugging HTTP requests, or validating backend services."

**Poor**: "Requirements analyst"
**Good**: "Requirements analyst and project scoping expert. Elicits comprehensive requirements, creates user stories with acceptance criteria, and generates project briefs. Use when starting new projects, analyzing requirements, or creating specifications."

## Interactive Questions

When in interactive mode, ask:

1. **Role Question**:
   - Header: "Agent Role"
   - Question: "What specialized role should this subagent fulfill?"
   - Options:
     - "Code quality expert" - Review, refactor, and improve code
     - "Testing specialist" - Write and run tests, validate functionality
     - "Architecture advisor" - Design systems, plan structure
     - "Domain expert" - Provide specialized domain knowledge

2. **Activation Question**:
   - Header: "Activation"
   - Question: "When should Claude automatically invoke this subagent?"
   - Options:
     - "After code changes" - Proactively review new/modified code
     - "Specific keywords" - Trigger on certain terms (requirements, test, etc.)
     - "File patterns" - Activate for specific file types/projects
     - "Explicit request only" - Only when user directly asks

3. **Tools Question** (multiSelect: true):
   - Header: "Tool Access"
   - Question: "Which tools should this subagent have access to?"
   - Options:
     - "File operations" - Read, Write, Edit, Glob, Grep
     - "Shell commands" - Bash execution
     - "Web access" - WebFetch, WebSearch
     - "All tools (no restrictions)" - Inherits all available tools

4. **Model Question**:
   - Header: "Model"
   - Question: "Which AI model should power this subagent?"
   - Options:
     - "Sonnet (recommended)" - Balanced performance and speed
     - "Opus (advanced)" - Most capable, slower, expensive
     - "Haiku (fast)" - Quick responses, lighter tasks
     - "Inherit from parent" - Use same model as main conversation

5. **Scope Question**:
   - Header: "Scope"
   - Question: "Where should this subagent be available?"
   - Options:
     - "User-level (all projects)" - Save to ~/.claude/agents/
     - "Project-level (this project)" - Save to ./.claude/agents/
     - "Let me decide later" - Recommend based on context
     - "Both locations" - Create in both with option to choose

## Workflow Extraction Logic

When extracting from recent conversation:

1. **Identify Domain Patterns**:
   - Analyze file types worked with (*.py, *.go, *.ts, etc.)
   - Track command patterns (pytest, npm test, git, curl, etc.)
   - Detect frameworks/libraries mentioned
   - Identify problem domains (testing, debugging, deployment, etc.)

2. **Extract Tool Usage**:
   - Count tool invocations (Read: 15, Bash: 8, Write: 5, etc.)
   - Identify essential vs. optional tools
   - Note tool sequences (Read → Edit → Bash pattern)
   - Determine if web access needed

3. **Detect Workflow Steps**:
   - Find repeated action sequences
   - Identify decision points and conditionals
   - Extract verification/validation patterns
   - Note output/deliverable formats

4. **Generate System Prompt**:
   - Define clear role based on domain
   - Structure responsibilities from patterns
   - Create step-by-step workflow
   - Add quality criteria and best practices
   - Include example scenarios from actual history

5. **Set Activation Triggers**:
   - Extract keywords from user messages
   - Identify file patterns from glob/grep usage
   - Note explicit requests ("test this", "review code")
   - Generate description with trigger keywords

## Subagent Categories & Examples

### Code Quality & Review
- **code-reviewer**: Reviews for quality, security, maintainability
- **refactoring-expert**: Improves code structure and design
- **security-auditor**: Identifies vulnerabilities and security issues

### Testing & QA
- **test-writer**: Creates comprehensive test suites
- **test-runner**: Executes tests, diagnoses failures
- **qa-validator**: Validates functionality against requirements

### Architecture & Design
- **backend-architect**: Designs server-side systems
- **frontend-architect**: Plans client application structure
- **database-designer**: Models data structures and schemas

### Development Specialists
- **api-developer**: Builds and documents REST/GraphQL APIs
- **ui-implementer**: Creates user interfaces
- **integration-specialist**: Connects external services

### Analysis & Planning
- **spec-analyst**: Elicits requirements, creates user stories
- **spec-architect**: Designs system structure and interfaces
- **spec-planner**: Breaks work into granular tasks

### DevOps & Operations
- **deployment-specialist**: Handles releases and deployments
- **monitoring-expert**: Sets up observability and alerts
- **infrastructure-engineer**: Manages cloud resources

### Domain Experts
- **performance-optimizer**: Improves speed and efficiency
- **accessibility-expert**: Ensures WCAG compliance
- **localization-specialist**: Handles i18n/l10n

## Multi-Agent Coordination

Subagents can work together in workflows:

```bash
# Sequential workflow
"Use spec-analyst to analyze requirements, then spec-architect to design the system"

# Parallel tasks
"Have code-reviewer check quality while test-runner validates functionality"

# Handoff pattern
"spec-planner should create tasks, then spec-developer implements them"
```

## Advanced Patterns

### Hub-and-Spoke Coordination
Main agent coordinates multiple specialized subagents:
- Main agent receives user request
- Delegates to appropriate specialists
- Collects and synthesizes results

### Pipeline Workflow
Sequential phases with quality gates:
1. **Planning**: spec-analyst → spec-architect → spec-planner
2. **Development**: spec-developer → test-writer
3. **Validation**: code-reviewer → qa-validator

### Specialist On-Demand
Invoke domain experts as needed:
- Security audit: security-auditor
- Performance issue: performance-optimizer
- Accessibility review: accessibility-expert

## Output Format

After creation, provide:

```
✅ Subagent created successfully: [name]
   Location: ~/.claude/agents/[name].md (or project-level)
   Role: [Role description]
   Model: [sonnet/opus/haiku/inherit]
   Tools: [tool list or "all tools"]

📋 Subagent Details:
   - Activates on: [keywords, patterns, or scenarios]
   - Primary responsibilities: [list]
   - Key capabilities: [list]

🔍 How to Use:
   Automatic: Claude will invoke when context matches
   Explicit: "Use the [name] subagent to [task]"

🧪 Test Command:
   Try: "Use the [name] subagent to [example scenario]"

📝 Next Steps:
   1. Test the subagent with a relevant task
   2. Refine system prompt based on results
   3. Add to project agents if team-relevant
   4. Document use cases for team members
```

## Validation Checks

Before finalizing:

1. **YAML Syntax**:
   - Valid frontmatter delimiters (---)
   - Proper field names (name, description, tools, model)
   - Correct tool list format (comma-separated)
   - Valid model value (sonnet/opus/haiku/inherit)

2. **Description Quality**:
   - Includes role definition
   - Contains activation triggers
   - Has specific keywords
   - Describes when to use

3. **System Prompt**:
   - Clear role definition
   - Structured responsibilities
   - Step-by-step workflow
   - Quality criteria
   - Example scenarios

4. **Tool Restrictions**:
   - Appropriate for task
   - Not too restrictive
   - Not unnecessarily permissive
   - Consider security implications

## Notes

- **Context Isolation**: Each subagent has its own context window, preventing main conversation pollution
- **Automatic Invocation**: Claude Code proactively invokes subagents based on description and context
- **Explicit Invocation**: Users can request specific subagents: "Use the [name] subagent to..."
- **Priority**: Project-level subagents override user-level when names conflict
- **Tool Inheritance**: Omit `tools` field to inherit all available tools
- **Model Inheritance**: Use `model: inherit` to match parent conversation's model
- **Version Control**: Project subagents can be committed to git for team sharing
- **No Restart Needed**: Subagents are loaded dynamically

## Examples

```bash
# Interactive mode - guided creation with questions
/claude:create-subagent

# Auto mode - extract from recent code review work
/claude:create-subagent code-reviewer

# Create API testing specialist
/claude:create-subagent api-tester

# Create requirements analyst
/claude:create-subagent spec-analyst

# Create performance optimizer
/claude:create-subagent performance-optimizer
```

## Debugging Subagents

If Claude doesn't invoke your subagent:

1. **Check file location**:
   ```bash
   ls -la ~/.claude/agents/[name].md
   ls -la ./.claude/agents/[name].md
   ```

2. **Verify YAML syntax**:
   ```bash
   head -10 ~/.claude/agents/[name].md
   ```

3. **Test description clarity**: Make it more specific with trigger keywords

4. **Explicit invocation test**: "Use the [name] subagent to [task]"

5. **Check tool restrictions**: Ensure required tools aren't blocked

6. **Review logs**: Run `claude --debug` for error messages

## Related Commands

- `/agents` - Built-in interactive agent manager
- `/claude:create-skill` - Create a skill (model-invoked instructions)
- `/claude:create-command` - Create a slash command (user-invoked)

## Skill vs. Subagent vs. Command

| Feature | Skill | Subagent | Slash Command |
|---------|-------|----------|---------------|
| **Invocation** | Model-invoked | Model-invoked | User-invoked |
| **Context** | Main conversation | Isolated context | Main conversation |
| **Use Case** | Domain expertise | Complex workflows | Quick automation |
| **Location** | `~/.claude/skills/` | `~/.claude/agents/` | `~/.claude/commands/` |
| **Format** | Folder with SKILL.md | Single .md file | Single .md file |
| **Best For** | Adding capabilities | Task specialization | User shortcuts |

Choose subagents when:
- Task requires isolated context (large operations)
- Multiple specialized roles needed (multi-agent coordination)
- Proactive invocation desired (automatic delegation)
- Different model needed for sub-task
