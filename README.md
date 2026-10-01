# cc-plugins

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin marketplace — install skills to automate Git, Jira, and meta-development workflows directly in your terminal.

## Quick Start

```bash
# Add marketplace
/plugin marketplace add https://github.com/yanmxa/cc-plugins

# Install plugins
/plugin install git
/plugin install jira
/plugin install claude
/plugin install review
```

## Plugins

### git

Automates the full Git workflow — commit/push with DCO sign-off, create PRs (fork + branch + submit), list PRs across repos, squash commits, and batch rebase.

```
Bundled scripts: 01-fork-and-setup.sh, 03-create-pr.sh, show-prs.sh
```

### jira

Jira Cloud REST API v3 CLI and shell library. Sprint boards, issue CRUD, JQL search, workflow transitions, comments, links, and ADF builders — all from the terminal.

```
Bundled: jira-ops CLI + jira-ops.sh sourceable library
```

### review

Code review graded by the **evidence** behind each finding, never by how sure the
model says it is. `metrics` runs first (deterministic: a tool computed it), then
`review` fans out into independent angles — correctness, altitude, efficiency,
reuse, cross-file consistency, conventions — verifies each candidate three-state,
and sweeps for what the first pass missed. `defects`, `excess` and `intent` are
focused single-question modes over the same rules.

```
/review:review main     the pipeline: angles → verify → sweep
/review:excess          just "what can we delete"
```

### claude

Meta-development plugin for extending Claude Code itself — extract workflows into reusable slash commands or create specialized subagents.

### repost

Repurpose a YouTube video into a bilingual (EN/ZH) vertical clip and publish it to 视频号 / 公众号 / Bilibili — search, download, clean rolling auto-captions into whole sentences, translate, render portrait subtitles (in the letterbox band, never over the picture), design a cover, and drive the upload.

```
Bundled scripts: clean_srt.py, verticalize.py, make_cover.py
```

### demo

Animated product demos as a single HTML page that loops in the browser and renders to a crisp GIF/MP4 for a README or landing page. `comic` draws a black-and-white comic-style intro — ink outlines, halftone, stickers, sound effects, and time-driven motion — with a four-scene template and a finished nine-scene example.

```
Bundled: template.html, shoot.sh (one frame), render.sh (frames → GIF + MP4)
```

## How It Works

Each plugin bundles skills with `SKILL.md` definitions and supporting scripts. Skills use `${CLAUDE_SKILL_DIR}` for portable paths, so they work regardless of where Claude Code installs them.

```
plugins/
├── claude/                        # Meta-development
│   └── skills/
│       ├── create-command/
│       └── create-subagent/
├── git/                           # Git automation
│   └── skills/git/
│       └── scripts/               # Fork, PR, show-prs
├── jira/                          # Jira operations
│   └── skills/jira/
│       ├── scripts/               # CLI + shell library
│       └── references/            # API docs
└── review/                        # Code review, evidence-graded
    └── skills/
        ├── metrics/               # deterministic; runs first
        ├── review/                # angles → verify → sweep
        ├── defects/               # bugs only
        ├── excess/                # deletions only
        └── intent/                # spec only
```

## Contributing

PRs and issues welcome.

## License

MIT
