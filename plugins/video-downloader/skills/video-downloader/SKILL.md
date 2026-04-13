---
name: video-downloader
description: Download videos from YouTube and other sites using yt-dlp. Use this skill whenever the user wants to download, save, grab, or rip a video from a URL. Supports quality selection, subtitle download/embedding, format options, and audio extraction. Triggers on any video download request, even if the user just pastes a video link and says "download this".
allowed-tools: [Bash, Read, AskUserQuestion]
---

# Video Downloader

Download videos from YouTube and other supported sites via `yt-dlp`.

Script path: `${CLAUDE_SKILL_DIR}/scripts/download.py`

## Workflow

When the user gives a video URL, follow this two-step flow:

### Step 1: Probe — show the user what's available

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/download.py" "<URL>" --probe
```

This returns JSON with the video title, duration, available resolutions, and subtitle languages (both manual and auto-generated).

First, print a brief summary of the video (title, uploader, duration). Then mention notable metadata from the probe (e.g. "Manual English subtitles available", "Up to 4K resolution"). Then use `AskUserQuestion` to let the user pick options. **All options MUST come from the actual probe results — never offer resolutions, subtitle languages, or features that don't exist for this video.**

1. **Resolution** — List the top 3-4 resolutions from the probe's `resolutions` array. Only include resolutions that actually appear in the probe output. Add "(Recommended)" to 1080p if available since it balances quality and size. If the script's `-q` flag doesn't support a resolution (e.g. 1440p, 2160p), use `best` quality or invoke yt-dlp directly with `bestvideo[height<=N]`.
2. **Subtitles** — Use multiSelect. Always include "No subtitles". Then add options based on what the probe found: prioritize manual subtitles (`subtitles` field) over auto-generated ones, and mention which type they are. Include "English" and "Chinese (Simplified)" only if they exist in the probe output. Add "Embed into video" as a separate selectable option. Use `-s` for manual subs and `--auto-subs` for auto-generated ones.
3. **Format** — "mp4 (Recommended)", "webm", "mkv", "MP3 (audio only)".

After the user answers, map their choices to the download command flags and proceed to Step 2.

If the user already specified everything upfront (e.g. "download this in 720p with Chinese subs to ~/Videos"), skip the probe and go directly to Step 2.

### Step 2: Download with the chosen options

```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/download.py" "<URL>" [options]
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--probe` | Show video info only, don't download | — |
| `-q`, `--quality` | `best`, `2160p`, `1440p`, `1080p`, `720p`, `480p`, `360p`, `worst` | `best` |
| `-f`, `--format` | `mp4`, `webm`, `mkv` | `mp4` |
| `-a`, `--audio-only` | Extract audio as MP3 | off |
| `-o`, `--output` | Output directory | `~/Downloads` |
| `-s`, `--subs` | Subtitle languages (comma-separated, e.g. `en,zh-Hans`) | — |
| `--auto-subs` | Auto-generated subtitle languages | — |
| `--embed-subs` | Embed subtitles into the video file | off |

## Examples

Probe a video:
```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/download.py" "https://youtube.com/watch?v=abc" --probe
```

Download 1080p with embedded Chinese subtitles:
```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/download.py" "https://youtube.com/watch?v=abc" -q 1080p -s zh-Hans --embed-subs
```

Audio only:
```bash
python3 "${CLAUDE_SKILL_DIR}/scripts/download.py" "https://youtube.com/watch?v=abc" -a
```

## Supported Sites

yt-dlp supports 1000+ sites — YouTube, Bilibili, Twitter/X, Instagram, TikTok, Vimeo, etc.
