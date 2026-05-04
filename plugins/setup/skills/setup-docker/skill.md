---
name: setup-docker
description: Install OrbStack on macOS — a fast, lightweight Docker runtime that replaces Docker Desktop. Ships with docker daemon, CLI, compose, buildx, Kubernetes, and Linux VM support. Use this skill when the user mentions installing docker, docker setup, OrbStack, container runtime on Mac, or wants Docker without Docker Desktop's bloat.
allowed-tools: [Bash, Read, Write, Edit]
---

# Setup Docker (via OrbStack)

Install **OrbStack** as the macOS Docker runtime. It's the fastest option on Apple Silicon, free for personal use, and ships with everything you need.

## Why OrbStack

| | OrbStack | Docker Desktop | Colima |
|--|----------|----------------|--------|
| Startup | **2-3s** | 30-60s | 5-10s |
| Memory at idle | **<1GB** | 4-8GB | 1-2GB |
| File mount speed | **5-10× faster** | Slow | Slow |
| GUI | Menu bar icon only | Heavy dashboard | None |
| Personal use | **Free** | Free | Free |
| Kubernetes built-in | ✅ one toggle | ✅ but slower | ❌ separate setup |
| Linux VMs included | ✅ | ❌ | ❌ |

OrbStack on Apple Silicon is significantly faster than the alternatives — that's the main reason to pick it.

## What gets installed

Just one cask: **`orbstack`**. It bundles:
- Docker daemon + CLI
- `docker compose`
- `docker buildx` (multi-arch)
- Kubernetes (toggle in settings)
- Linux VM support (`orb create`)

No need to install `docker`, `docker-compose`, `docker-buildx` separately — they all come with it.

## Quick setup

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/setup-docker.sh
```

The script:
1. Installs `orbstack` via Homebrew cask
2. Opens the app once to trigger the setup wizard
3. Tells you how to verify

After install, **OrbStack auto-starts** when you run any docker command — no manual `colima start` needed.

## Verify

```bash
docker run hello-world
docker compose version
docker buildx version
```

## Daily use

```bash
# Just use docker normally — OrbStack handles starting the VM
docker ps
docker compose up
docker build .

# CLI controls (optional — menu bar icon does the same)
orb status            # show VM state
orb stop              # stop VM (frees ~1GB RAM)
orb start             # start VM (rarely needed — auto-starts on docker call)
orb delete            # nuke the VM and start over
```

## Multi-architecture builds

OrbStack is `arm64` native on Apple Silicon. To build/run x86 images:

```bash
docker run --platform linux/amd64 ubuntu:22.04
docker buildx build --platform linux/amd64,linux/arm64 -t myimg .
```

## Kubernetes (optional)

Open OrbStack → Settings → Kubernetes → toggle on. `kubectl` will work against the cluster automatically:

```bash
kubectl get nodes
kubectl run nginx --image=nginx
```

## Linux VMs (bonus)

OrbStack can run lightweight Linux VMs side-by-side with Docker:

```bash
orb create ubuntu my-vm    # creates an Ubuntu VM
orb shell my-vm             # SSH into it (just-works, file sharing pre-mounted)
```

Faster than UTM/Parallels for "just give me a Linux shell" use cases.

## License note

OrbStack is **free for personal use** and **free for non-commercial use**. Companies pay $8/user/month. For an individual developer working on personal projects or contributing to OSS, free.

## Useful aliases (already in setup-zsh)

```
alias d='docker'
alias dc='docker compose'
```
