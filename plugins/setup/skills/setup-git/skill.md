---
name: setup-git
description: Install git + GitHub CLI (gh) and configure global settings — user identity, editor, useful aliases, pull/push defaults, SSH key, gh auth, and global gitignore. Use this skill when the user mentions setting up git, configuring git, git global config, git setup, git aliases, SSH keys for git, gh CLI, GitHub CLI, GitHub authentication, or wants to set up git on a new machine.
allowed-tools: [Bash, Read, Write, Edit]
---

# Setup Git + GitHub CLI

Install git and GitHub CLI, then configure git for a new machine: identity, editor, pull/push defaults, aliases, credential helper, SSH key, gh auth, and global gitignore.

## What gets done (in order)

1. **Install git** via Homebrew (skips system git for newer version)
2. **Configure identity** — `user.name`, `user.email` (prompts if not given)
3. **Set defaults** — pull.rebase, push.autoSetupRemote, init.defaultBranch=main
4. **Set credential helper** — `osxkeychain` (macOS only)
5. **Define aliases** — `lg`, `st`, `co`, `br`, `unstage`, `last`, `aliases`
6. **Create global gitignore** — `~/.gitignore_global` (`.env`, `*.pem`, `*_rsa`, etc.)
7. **Generate SSH key** — `~/.ssh/id_ed25519` (if not present) + add to ssh-agent
8. **Install gh CLI** via Homebrew
9. **Run gh auth login** — interactive (uploads SSH key to GitHub automatically)

## Quick setup

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-git.sh

# Or with identity pre-set:
bash ${CLAUDE_SKILL_DIR}/scripts/setup-git.sh "Your Name" "you@example.com"
```

## ────────────────────────────────────────────────────────────────────
## How GitHub authentication works (the two-layer model)
## ────────────────────────────────────────────────────────────────────

There are **two independent credentials** between your machine and GitHub. You generally want both:

| Layer | What it is | Used for |
|-------|-----------|----------|
| **SSH key** | `~/.ssh/id_ed25519` keypair | `git clone git@github.com:...`, `git push`, `git pull` |
| **OAuth token** | Stored by `gh` in macOS Keychain | `gh pr create`, `gh repo view`, GitHub API calls, releases |

They serve different purposes — SSH for git operations over the SSH transport, OAuth for the gh CLI which talks to the REST/GraphQL API.

### The neat trick: `gh auth login` does both

When you run `gh auth login` and pick **GitHub.com → SSH → upload key → browser**, gh:
1. Opens a browser → you authorize via OAuth → token stored in Keychain
2. **Uploads your `~/.ssh/id_ed25519.pub` to GitHub for you** — no manual copy-paste into web settings

After that, both `git push` and `gh pr create` work.

### What setup-git.sh does on auth

```
1. SSH key exists?  → no  → generate id_ed25519 with email comment
                    → yes → keep
2. gh auth status?  → ok  → skip
                    → fail → run `gh auth login` interactively
```

When `gh auth login` runs, **make these choices**:

```
? What account do you want to log into?  → GitHub.com
? What is your preferred protocol?        → SSH
? Generate a new SSH key to add?          → No, use existing
? Choose SSH key                          → ~/.ssh/id_ed25519.pub  ← the one we just made
? Title for SSH key                       → <hostname-of-your-mac>
? How would you like to authenticate?     → Login with a web browser
```

Browser opens → enter the one-time code → done. SSH key gets uploaded automatically.

## After setup — verify

```bash
# git basics
git config --list --global

# Test SSH connection to GitHub
ssh -T git@github.com
# Expected: "Hi <username>! You've successfully authenticated..."

# Test gh
gh auth status
# Expected: "Logged in to github.com account <username>"

# Both should agree on your username
gh api user --jq .login
```

## Git aliases reference

| Alias | Expands to |
|-------|-----------|
| `git lg` | Pretty one-line log with graph |
| `git st` | `status -sb` |
| `git co` | `checkout` |
| `git br` | `branch` |
| `git unstage` | `reset HEAD --` |
| `git last` | `log -1 HEAD` |
| `git aliases` | List all defined aliases |

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `Permission denied (publickey)` on push | SSH key not on GitHub | `gh ssh-key add ~/.ssh/id_ed25519.pub` |
| `gh: command not found` after install | Homebrew bin not in PATH | Restart shell: `source ~/.zshrc` |
| `git push` works but `gh` says "not logged in" | OAuth missing, only SSH set up | Re-run `gh auth login` |
| Pushed to wrong account | Multiple identities, gh defaulted | `gh auth switch` or `gh auth login --hostname github.com` |
| `Cloning into ...` hangs | First-time host key prompt | `ssh -T git@github.com` once to accept |
| Need to use a 2nd GitHub account | Single SSH key can't auth as two users | Add per-host SSH config in `~/.ssh/config` (see below) |

## Multiple GitHub accounts (advanced)

If you need a separate GitHub identity (e.g. work + personal), generate a 2nd key and add to `~/.ssh/config`:

```
# ~/.ssh/config
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
```

Then clone with `git@github-work:org/repo.git` for the alt account.
