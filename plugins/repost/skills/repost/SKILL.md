---
name: repost
description: >
  Repurpose a YouTube video into a bilingual (EN/ZH) vertical clip and publish it
  to 视频号/公众号 (portrait) and/or Bilibili (landscape). Use when the user wants to
  search YouTube for a video to repost, download one, add 中英字幕 / turn a 横屏 video
  竖屏, design a cover, or publish to 视频号/公众号/抖音/B站. Whole pipeline or any single
  stage. Args may name a platform: wechat | bili | all.
allowed-tools: [Bash, Read, Write, AskUserQuestion]
---

# repost

End-to-end pipeline for a bilingual self-media channel: **search → download → edit
→ cover → publish**. The scripts live next to this file; do only the stages the
user asks for.

**Requirements:** `yt-dlp` + `ffmpeg` (download/render), `/usr/bin/python3` with
**Pillow** (the macOS system Python — it renders the subtitle/cover PNGs), and for
the publish stage the [`bsk`](https://github.com/anthropics/browser-skill)
BrowserSkill CLI with Chrome logged into the target platform. The scripts are
tuned for macOS (Hiragino Sans GB font); adjust `FONT` in the scripts on Linux.

Scripts (reference by absolute path):

- `${CLAUDE_SKILL_DIR}/scripts/clean_srt.py` — rebuild rolling auto-captions into sentences
- `${CLAUDE_SKILL_DIR}/scripts/verticalize.py` — composite the bilingual video
- `${CLAUDE_SKILL_DIR}/scripts/make_cover.py` — generate a designed cover

**Target platform** (from the args, e.g. `/repost <url> bili`): `wechat` = 视频号
(+公众号), `bili` = Bilibili, `all` = both. **Default is `wechat` (视频号 only).**
Bilibili requires the user to **explicitly opt in** (`bili` or `all`); if the args
don't mention it, publish to 视频号 only. The two need DIFFERENT renders: wechat
wants **portrait**; bili wants **`--layout bili`** (16:9). For `all`, translate
once and render both from the same cleaned srt + `zh.json`.

**Publishing is a side-effecting, outward-facing action.** Confirm the title,
creation declaration (转载/自制), and category with the user before the first or an
important publish unless they've told you to run fully automatically. **Reposts are
转载 / 内容为转载 + a source-credit line citing the original channel — never declare
自制 for someone else's video.** Only a login QR is truly un-automatable: hand it to
the user to scan.

## 1. Search (yt-dlp, never a browser)

```sh
yt-dlp "ytsearch10:<keywords>" --flat-playlist \
  --print "%(id)s | %(duration_string)s | %(view_count)s | %(title)s"
```

Search several queries, dedup, rank by views, confirm dates + subtitle availability,
then present a Top-N table (播放/时长/频道/标题/链接) and let the user pick. Add
`--cookies-from-browser chrome` if you hit "Sign in to confirm you're not a bot";
pull metadata serially — concurrency trips bot detection.

## 2. Download

```sh
yt-dlp -f "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]" \
  --write-subs --write-auto-subs --sub-langs "zh.*,en" --convert-subs srt \
  --write-thumbnail --convert-thumbnails jpg \
  -o "downloads/%(title)s.%(ext)s" "<URL>"
```

You need the `.en.srt` for step 3. Subs only: add `--skip-download`. See which subs
exist: `--list-subs`.

## 3. Edit — portrait, subtitles in the band, NEVER over the picture

**Default to `--layout portrait` for 视频号 — basically always, even for dense
dashboards / code / charts.** The video sits centered and the subtitles go in the
**top/bottom letterbox band (the empty margin), so they never cover the picture.** A
phone viewer sees the portrait video at full width anyway and can zoom for detail;
covering content with subtitles is the worse evil. Do NOT switch to landscape just
because content is dense.

`--layout landscape` is a rare exception (user asks, or it's useless unless it fills
16:9). **No subtitle background box/panel in ANY layout** — text sits on the video
with a heavy stroke (+ shadow); a box covers the picture. `verticalize.py` enforces
no-box everywhere.

Layouts: **portrait** (default) centers the video; title + subs sit on the dark band
(yellow heading + accent underline + a small gray `--kicker` English line). **bili**
= 16:9, video fills the frame, no burned title, bold yellow ZH over gray EN burned at
the bottom. **overlay** is auto-selected for 竖屏 sources (aspect ≥ 1.4): picture fills
the frame, small subs anchored low. Colors: ZH warm yellow `(255,231,150)` primary,
EN soft gray `(198,205,220)` secondary. Portrait bands default to `--bg auto` (samples
the video's bg; a light/whiteboard bg is auto-darkened). **Force `--bg 0x141414` for
mixed/warm-light screencasts** (light docs + dark terminal + webcam) — `auto` only
guards "too bright", not "warm but dim".

**Zoom is editorial, not an effect:** default is NO zoom. Only punch in for a specific
detail with `--zoom-at START-END[@LEVEL][:FX,FY]` (seconds; level default 1.25; FX,FY
0–1 focus) and ease back — never a constant breathing motion.

### The steps

1. **Clean the captions first.** YouTube auto-captions (EN and ZH) are rolling
   word-by-word — raw they duplicate garbage. Rebuild into whole sentences:

   ```sh
   DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 downloads/xxx.mp4)
   /usr/bin/python3 "${CLAUDE_SKILL_DIR}/scripts/clean_srt.py" \
     downloads/xxx.en.srt downloads/xxx.clean.en.srt "$DUR"
   ```

   Read the clean transcript so the title and translation are right.

2. **Translate every clean EN cue to Chinese yourself** → `zh.json` =
   `{"<cue-index>": "中文", ...}` (0-based keys matching the cleaned srt, `ensure_ascii=false`,
   corner-bracket 「」 quotes). Do NOT use YouTube's machine zh — it drifts out of sync
   mid-video. For a long transcript, delegate the translation to a subagent and verify
   the cue count matches.

3. **Render:**

   ```sh
   /usr/bin/python3 "${CLAUDE_SKILL_DIR}/scripts/verticalize.py" \
     --video downloads/xxx.mp4 --en downloads/xxx.clean.en.srt --zh zh.json \
     --layout portrait --bg 0x141414 \
     --title "中文标题" --kicker "English title · Source" \
     --out downloads/xxx-portrait.mp4
   ```

   (Bilibili: `--layout bili`, no `--bg`.) Size: `bsk upload` caps at **512MB** per
   file; `verticalize.py` adapts bitrate toward ~500MB, but for a long video pass
   `--bitrate 1800k` (≈ 300MB for 20 min) to stay comfortable.

4. **Verify sync — check video-vs-subtitle, not just EN-vs-ZH** (both subs share a
   track, so matching each other proves nothing about the picture). Grab frames near
   the middle AND end, confirm the *on-screen content* matches the subtitle there, and
   that `ffprobe` output duration ≈ source duration (a mismatch = zoompan/fps stretched
   the video into slow-motion desync — `verticalize.py` hard-errors on this). Every
   check must pass before publishing.

## 4. Cover — always a designed cover, never a black frame

The vertical clip opens on a black intro, so the platform's auto-cover is a black
screen. **Never ship that.** Generate a 3:4 cover (a big yellow keyword + a Chinese
one-line subtitle + optional English tagline):

```sh
/usr/bin/python3 "${CLAUDE_SKILL_DIR}/scripts/make_cover.py" \
  --keyword "BM25" --subtitle "AI Agent 搜索的意外利器" \
  --kicker "AI ENGINEER · SEARCH" --english "The unreasonable effectiveness of BM25" \
  --out downloads/xxx-cover.jpg
```

Add `--landscape` for a 16:9 cover (Bilibili). The subtitle font auto-shrinks to fit
two lines, so keep it to one punchy idea — an over-long subtitle just shrinks tiny.

## 5. Publish

Publish to whichever platforms the target calls for — see
`references/publishing.md` for the verified `bsk`-driven flow on each platform
(视频号 form fields, short-title ≤16 chars, the 转载/内容为转载 declaration + source,
cover upload, the large-file multipart-upload signals to wait for, the Bilibili
selectors, and which steps need the user's WeChat/B站 QR scan). After publishing,
report the published time from the platform's post-list page. **Dedup before
publishing** — check the post list and skip anything already up.
