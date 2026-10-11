---
name: comic
description: Make a black-and-white comic-style animated product demo — a single HTML page of timed scenes (logo slam, terminal walkthroughs, sessions messaging each other, feature grids) that loops in the browser and renders to a crisp GIF/MP4 for a README or landing page. Use whenever the user wants an animated intro, demo video, product showcase, README GIF, "动画介绍 / 动图 / 宣传动画", or asks for a comic / manga / ink / hand-drawn look for a demo — even if they only say "make the intro video better" or "the README GIF looks dull".
allowed-tools: [Bash, Read, Write, Edit]
---

# Comic demo

One HTML file *is* the video: a timeline of scenes on a 1280×720 stage. It plays and loops in the browser, and `?t=<seconds>` freezes any frame, so a headless browser can render every frame exactly and ffmpeg stitches them into a GIF/MP4.

Files:

| file | what it is |
|---|---|
| `${CLAUDE_SKILL_DIR}/assets/template.html` | Start here. Four scenes (intro · work · talk · outro), the comic CSS, and the timeline engine. |
| `${CLAUDE_SKILL_DIR}/scripts/shoot.sh` | `shoot.sh <html> <t> [out.png]` — one frame at second `t`. |
| `${CLAUDE_SKILL_DIR}/scripts/render.sh` | `render.sh <html> <out.gif> [fps=12] [jobs=8]` — every frame → GIF + MP4. |
| `${CLAUDE_SKILL_DIR}/references/example-san-intro.html` | A finished 9-scene intro (models picker, subagents, a workflow graph with a write/critic loop, session groups, self-learning, a deploy ring, a feature grid). Read it when you need a pattern the template lacks. |

## Workflow

1. Copy the template next to the project (`site/intro.html` or similar) and replace the brand, copy and scenes. Each scene is `<section class="scene" id="X" data-start="S" data-dur="D">` plus a `RUN.X(lt)` function driven by local time `lt`, and an optional `CAPS.X` entry for the left caption column. Scenes must not overlap: when you lengthen one, shift every later `data-start`.
2. Preview with `shoot.sh` at the moments that matter — mid-typing, mid-flight, the end state — and **look at the PNGs**. Tile several with `ffmpeg … xstack` to review a whole pass at once.
3. Open the page for the user (`open file.html`) and iterate on their feedback.
4. Render with `render.sh`, check the size, replace the README asset.

## The look

- **Ink on paper only.** Black, white, greys. A single colour of emphasis is ink itself: inverted black blocks with white text mark the selected/running/lit thing. Adding colour back makes it look cheap fast.
- **Ink outlines + solid offset shadows** (`2.5px solid #111`, `6px 6px 0 #111`) on every window, card, node and tile.
- **Comic type, readable body.** Bangers for logos, titles, terms and stickers; Comic Neue for caption glosses; a mono for terminal content. Never put body text in Bangers.
- **Outlined hollow words for emphasis** in titles (`color:#fff; -webkit-text-stroke; text-shadow`), not a second colour.
- **Halftone vignette background**: dots thicker toward the edges, a faint wash in the centre. A flat centre reads as a mistake; even dots everywhere read as flat.
- **The logo is drawn, not typed.** A big outlined, tilted wordmark with a spark, not `<Name />` code-looking text. A small version of the same mark sits top-left on inner scenes and hides where the big one is on screen.

## Motion

Everything is a pure function of time. That is what lets `?t=` render the motion itself, not just the end state. Use the helpers:

- `show(el, lt, t0)` — rise in with a small pop. Use it for rows, panels and lines.
- `stamp(id, lt, t0, t1, rot, over)` — slap a sticker or sound effect on with an overshoot, slightly askew. Use it for cards, tags and tiles.
- `burst(g, lt, t0, cx, cy, r0, squash)` — action lines radiating out. Use it once for the logo, once for a "goes everywhere" moment.
- `typeInto` / `cursor` / `spin` — typing, caret, spinner.

Seek mode disables CSS transitions on purpose: a frozen frame that caught a transition half-way depends on machine load and flickers across the GIF. Never rely on CSS transitions for anything that must appear in the render.

Things that went wrong before and why:

- **Scene transitions.** Wipes, ink panels and sweeping strokes all read as noise or made viewers dizzy. A plain cross-fade between scenes is enough.
- **Sound effects everywhere.** Keep to two or three — ZIP!, DONE!, APPROVED! — each on screen for about a second, at a real event.
- **Chrome pinned to every frame** (a corner label, a dark progress track). It reads as stuck UI. Show a tagline once as a sticker in the intro; keep the progress track faint, with only the played part in ink.

## Telling the story

- **Work before talk.** When sessions or agents message each other, each side does several real steps (Read, Edit, Bash, tests) before it sends anything. Messages flying back and forth with nothing in between look fake. Cut any message that only confirms — "fixed, tests pass" after a correction is redundant.
- **Messages are rows, not boxes.** A message keeps the same layout as every other row; only its marker becomes a tiny speech bubble (outline = sent, filled = received). Boxed bubbles inside a terminal are loud and break alignment.
- **Show the flight.** An envelope arcs from the sending row to where the receiver's next row will appear, with three short motion lines behind it. Compute both ends from element offsets every frame, not fixed coordinates — panes scroll and a fixed path ends up pointing at the wrong row.
- **Make processes visible.** A loop such as write ↔ critic draws one arc per pass, so three revisions show three arcs. A background step such as "reviewing this session…" spins long enough (about 1.5s) to read before its result appears, and a dashed line appears only when it starts, marking where the work ends.
- **Variety.** Two examples of the same feature should differ in shape: a parallel fan-out vs. a loop, not two fan-outs.
- **Pace.** Features every competitor has (model switching, subagents) get 3–4 seconds; the distinctive ones get the time.

## Layout

- The caption column and the right panel share one vertical centre: both live in the same `top:104px; height:496px` band.
- The right column ends where the right margin is, *including* the 6px offset shadow (`left:494px; width:708px`).
- A lone window is never shorter than the caption beside it — the engine sets its `min-height` from the caption every frame.
- Every terminal row is `marker column · content · right-aligned meta`, so markers, text and numbers line up across rows. Shorten text rather than let it wrap or clip.
- Check alignment on a tiled sheet of frames; the user will notice a 6px misalignment.

## Rendering

`render.sh` shoots at the native 1280×720 and never scales down; downscaling is what makes README GIFs blurry. Black-and-white art needs few colours, so it encodes with a 32-colour palette and no dithering: sharp edges, and roughly 5–10 MB for about a minute at 12fps. Report the size; GitHub has trouble displaying images over about 10 MB, and if one is that large, drop to 8fps before you drop resolution. The MP4 next to it is for the landing page and social posts.

Rendering takes minutes, and every edit invalidates it. Run it in the background, and stop and restart it when the page changes.
