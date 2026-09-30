#!/usr/bin/env python3
"""Turn a 16:9 video into a 1080x1920 vertical clip with a top title band and
bottom bilingual (EN/ZH) subtitles burned in — for 视频号/抖音.

This machine's ffmpeg has no libass/drawtext, so text is rendered to transparent
PNGs with Pillow and composited: title as a static overlay, subtitles as an
alpha overlay track (qtrle via the concat demuxer, timed by cue durations).

Usage:
  /usr/bin/python3 verticalize.py \
      --video SRC.mp4 --en SRC.en.srt --title "标题" --out OUT.mp4 \
      [--zh zh.json]        # {"0":"中文", "1":"中文", ...} keyed by EN cue index
      [--zh-srt SRC.zh.srt] # fallback: reconstruct from YouTube rolling auto-caption

--zh (clean per-cue translation) is strongly preferred: the YouTube auto-caption
is rolling and drifts out of sync mid-video, so --zh-srt is a rough fallback only.
Run with /usr/bin/python3 (the interpreter that has Pillow), not brew python.
"""
import re, os, sys, json, subprocess, argparse, tempfile
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1920
FONT = "/System/Library/Fonts/Hiragino Sans GB.ttc"
PLATE = (28, 52, 40, 255)   # portrait title/subtitle plate — a solid green that coordinates with --bg


def sample_bg(video, dur):
    """Median color of the source frames' edge pixels — so portrait bands match the
    video's own background (a black-bg video gets black bands, no jarring seam)."""
    import tempfile
    tmp = tempfile.mkdtemp(prefix="bg_")
    for i, t in enumerate([dur*0.2, dur*0.5, dur*0.8]):
        subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-ss", f"{t:.1f}",
                        "-i", video, "-frames:v", "1", f"{tmp}/f{i}.png"], check=False)
    rs, gs, bs = [], [], []
    for i in range(3):
        p = f"{tmp}/f{i}.png"
        if not os.path.exists(p):
            continue
        im = Image.open(p).convert("RGB")
        w, h = im.size
        px = im.load()
        pts = ([(x, 2) for x in range(0, w, 40)] + [(x, h-3) for x in range(0, w, 40)] +
               [(2, y) for y in range(0, h, 40)] + [(w-3, y) for y in range(0, h, 40)])
        for x, y in pts:
            r, g, b = px[x, y]
            rs.append(r); gs.append(g); bs.append(b)
    if not rs:
        return "0x142a1f"
    rs.sort(); gs.sort(); bs.sort()
    m = len(rs)//2
    return f"0x{rs[m]:02x}{gs[m]:02x}{bs[m]:02x}"


def build_zoom_expr(specs, fps, ease=0.5):
    """Deliberate editorial punch-in (not a constant effect). `specs` are
    'START-END[@LEVEL][:FX,FY]' strings (seconds; LEVEL default 1.25; FX,FY the
    focus point as 0-1 fractions, default center). Returns zoompan z/x/y exprs:
    z=1 (full frame, no crop) between segments, easing up to LEVEL over `ease`s
    inside each segment and back out, zooming toward that segment's focus. Keep
    segments non-overlapping. Returns None if `specs` is empty."""
    segs = []
    for s in specs:
        m = re.match(r'^\s*([\d.]+)-([\d.]+)(?:@([\d.]+))?(?::([\d.]+),([\d.]+))?\s*$', s)
        if not m:
            raise SystemExit(f"bad --zoom-at spec {s!r} (want START-END[@LEVEL][:FX,FY])")
        t0, t1 = float(m.group(1)), float(m.group(2))
        lvl = float(m.group(3)) if m.group(3) else 1.25
        fx = float(m.group(4)) if m.group(4) else 0.5
        fy = float(m.group(5)) if m.group(5) else 0.5
        segs.append((t0, t1, lvl, fx, fy))
    if not segs:
        return None
    eif = max(1.0, ease * fps)
    def env(t0, t1):                       # trapezoid ramp in [0,1] over the segment
        return f"clip(min(min((on-{t0*fps:.1f})/{eif:.1f},({t1*fps:.1f}-on)/{eif:.1f}),1),0,1)"
    zterms, fxs, fys = [], ["0.5"], ["0.5"]
    for (t0, t1, lvl, fx, fy) in segs:
        e = env(t0, t1)
        zterms.append(f"({lvl-1:.4f})*{e}")           # z = 1 + max_i (lvl_i-1)*env_i
        if abs(fx-0.5) > 1e-6: fxs.append(f"({fx-0.5:.4f})*{e}")   # focus eases center->target
        if abs(fy-0.5) > 1e-6: fys.append(f"({fy-0.5:.4f})*{e}")
    z = zterms[0]
    for t in zterms[1:]:
        z = f"max({z},{t})"
    FX, FY = "+".join(fxs), "+".join(fys)
    return {"z": f"1+{z}",
            "x": f"clip(({FX})*iw-iw/zoom/2,0,iw-iw/zoom)",
            "y": f"clip(({FY})*ih-ih/zoom/2,0,ih-ih/zoom)"}


def parse_srt(path):
    cues = []
    for b in re.split(r"\n\s*\n", open(path, encoding="utf-8").read().strip()):
        m = re.search(r"(\d+):(\d+):(\d+)[,.](\d+)\s*-->\s*(\d+):(\d+):(\d+)[,.](\d+)", b)
        if not m:
            continue
        g = list(map(int, m.groups()))
        s = g[0]*3600 + g[1]*60 + g[2] + g[3]/1000
        e = g[4]*3600 + g[5]*60 + g[6] + g[7]/1000
        lines = b.splitlines()
        i = [k for k, l in enumerate(lines) if "-->" in l][0]
        cues.append((s, e, " ".join(lines[i+1:]).strip()))
    return cues


def reconstruct_zh(zh_srt, en):
    """YouTube rolling auto-caption: last line of each real (>50ms) cue is the new
    fragment. Concatenate fragments falling in each EN window. Rough — drifts."""
    frags = []
    for s, e, t in parse_srt(zh_srt):
        if e - s < 0.05 or not t.strip():
            continue
        frags.append((s, [l for l in t.splitlines() if l.strip()][-1]))
    out = {}
    for i, (s, e, _) in enumerate(en):
        lo = s if i > 0 else 0
        hi = e if i < len(en)-1 else 10**9
        out[i] = "".join(txt for (fs, txt) in frags if lo-0.3 <= fs < hi).strip()
    return out


def wrap(draw, text, font, maxw, cjk):
    if cjk:
        # break between CJK chars, but keep latin/number runs (e.g. "Agent", "BM25") whole
        units = re.findall(r"[A-Za-z0-9][A-Za-z0-9.\-']*|\s+|[^A-Za-z0-9\s]", text)
    else:
        units = text.split()
    lines, cur = [], ""
    for u in units:
        if cjk:
            t = cur + u
        else:
            t = (cur + " " + u).strip()
        if draw.textlength(t.strip(), font=font) <= maxw or not cur.strip():
            cur = t
        else:
            lines.append(cur.strip())
            cur = u
    if cur.strip():
        lines.append(cur.strip())
    return lines


def draw_center(draw, lines, font, y, fill, stroke=3, shadow=False):
    for ln in lines:
        w = draw.textlength(ln, font=font)
        x = (W - w) / 2
        if shadow:                                    # soft drop shadow for a polished look
            draw.text((x + 3, y + 4), ln, font=font, fill=(0, 0, 0, 150))
        draw.text((x, y), ln, font=font, fill=fill,
                  stroke_width=stroke, stroke_fill=(0, 0, 0, 220))
        y += font.size + 14
    return y


def draw_subs(img, draw, en_lines, f_en, zh_lines, f_zh, y_top, box, stroke=3, shadow=False):
    """Bilingual block: ZH warm-yellow (primary), EN soft gray (secondary).
    `box`=True draws a translucent panel behind the text (landscape, over busy
    16:9 video). Otherwise NO box — text sits directly on the band (portrait) or
    straight on the video (vertical overlay / bilibili), where a heavy `stroke`
    (+ optional `shadow`) keeps it readable without a plate covering the picture."""
    block = len(en_lines)*(f_en.size+14) + (24 if (zh_lines and en_lines) else 0) + len(zh_lines)*(f_zh.size+14)
    if box:
        widths = [draw.textlength(l, font=f_en) for l in en_lines] + [draw.textlength(l, font=f_zh) for l in zh_lines]
        bw = max(widths) if widths else 0
        pad_x, pad_y = 44, 26
        draw.rounded_rectangle([(W-bw)/2 - pad_x, y_top - pad_y, (W+bw)/2 + pad_x, y_top + block + pad_y - 8],
                               radius=30, fill=(10, 12, 20, 120), outline=(255, 255, 255, 22), width=2)
    y = draw_center(draw, en_lines, f_en, y_top, (198, 205, 220, 255), stroke=stroke, shadow=shadow)
    if zh_lines:
        draw_center(draw, zh_lines, f_zh, y + (24 if en_lines else 0), (255, 231, 150, 255), stroke=stroke, shadow=shadow)
    return block


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--video", required=True)
    ap.add_argument("--en", required=True)
    ap.add_argument("--title", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--zh")
    ap.add_argument("--zh-srt", dest="zh_srt")
    ap.add_argument("--layout", choices=["portrait", "landscape", "bili"], default="portrait",
                    help="portrait/landscape for 视频号; 'bili' = 16:9 landscape for Bilibili (no burned title, bold yellow bilingual subs at the bottom).")
    ap.add_argument("--bg", default="auto",
                    help="portrait band color: 'auto' samples the video's own bg (black stays black, no jarring seam), or an ffmpeg color like 0x142a1f / black")
    ap.add_argument("--bitrate", help="video bitrate e.g. 8M; default adapts to fit bsk's 512MB upload cap")
    ap.add_argument("--kicker", default="", help="small line under the title (e.g. English title / source)")
    ap.add_argument("--zh-only", dest="zh_only", action="store_true",
                    help="draw ONLY the Chinese line (no EN). Use when the SOURCE already has burned-in captions (usually English) — add just a small ZH translation instead of a full bilingual set.")
    ap.add_argument("--zoom-at", dest="zoom_at", nargs="*", default=[],
                    help="DELIBERATE punch-in segments (editorial zoom): the picture stays full & still, and only at these moments eases IN to enlarge a detail, holds, then eases back OUT. "
                         "Each: 'START-END[@LEVEL][:FX,FY]' in seconds, LEVEL like 1.25 (default 1.25), FX,FY = focus point as 0-1 fractions of the frame to zoom toward (default 0.5,0.5 = center). "
                         "e.g. --zoom-at 12-18 95-110@1.3:0.3,0.5 . Omit for no zoom at all. NOT a constant/breathing effect.")
    args = ap.parse_args()
    global W, H
    if args.layout in ("landscape", "bili"):
        W, H = 1920, 1080

    dur = float(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=nw=1:nk=1", args.video]).strip())
    vw, vh_src = [int(x) for x in subprocess.check_output([
        "ffprobe", "-v", "error", "-select_streams", "v", "-show_entries",
        "stream=width,height", "-of", "csv=p=0:nk=1", args.video]).decode().strip().split(",")[:2]]
    vh = round(W * vh_src / vw / 2) * 2                     # scaled video height (even)
    # 视频号 overlays its own UI (account, description, action buttons) over the
    # bottom of the video in-feed, so keep burned content out of that band.
    UI_RESERVE = 440
    land = args.layout == "landscape"
    # Bilibili: 16:9 landscape, video fills the frame, NO burned title, bold yellow
    # bilingual subs burned at the bottom (Bilibili has its own title + no in-player
    # bottom UI, so nothing to reserve for and no band needed).
    bili = args.layout == "bili"
    # A portrait/tall SOURCE (e.g. a 9:16 Short) can't be shrunk into a band without
    # the content becoming tiny, so instead FILL the frame and OVERLAY: title in the
    # usually-empty top area, subtitles on a translucent panel above the UI-reserve
    # zone. Same translucent-panel drawing as landscape, but portrait dimensions.
    overlay = (not land and not bili) and (vh_src / vw >= 1.4)
    if land or bili or overlay:
        vh = H                                             # source fills the frame
        video_y = 0
    else:
        video_y = int((H - UI_RESERVE - vh) / 2) & ~1      # center in the safe zone above the platform UI
    video_bottom = video_y + vh
    maxw = W - 100
    bg = sample_bg(args.video, dur) if args.bg == "auto" else args.bg
    # Subtitle/title colors (warm yellow, soft gray) are tuned for DARK bands. If
    # --bg auto sampled a LIGHT background (e.g. a whiteboard video), seamless-but-
    # light bands make the text unreadable — so darken it to a neutral dark instead.
    if args.bg == "auto":
        r, g, b = (int(bg[2:4], 16), int(bg[4:6], 16), int(bg[6:8], 16))
        if (0.2126 * r + 0.7152 * g + 0.0722 * b) > 140:   # luminance too high for light text
            bg = "0x141414"
    # PLATE (portrait text lives directly on the band now, no plate) — bg drives the look

    en = [(s, e, t) for s, e, t in parse_srt(args.en) if t]
    if args.zh:
        raw = json.load(open(args.zh, encoding="utf-8"))
        zh = {int(k): v for k, v in raw.items()}
    elif args.zh_srt:
        zh = reconstruct_zh(args.zh_srt, en)
    else:
        zh = {}

    # Font sizes per layout. Vertical-overlay text sits DIRECTLY on the video (no
    # box), so it runs smaller to avoid covering the picture; landscape uses a panel.
    ts, es, zs = (48, 38, 52) if bili else (44, 30, 40) if overlay else (48, 36, 46) if land else (62, 40, 52)
    f_title = ImageFont.truetype(FONT, ts)
    f_en = ImageFont.truetype(FONT, es)
    f_zh = ImageFont.truetype(FONT, zs)
    f_kicker = ImageFont.truetype(FONT, 28 if overlay else 34)
    frames = tempfile.mkdtemp(prefix="vfx_")

    # Static title overlay. Vertical OVERLAY draws NO title — a Short plays full-
    # frame and a burned title just clutters the top / covers content; the cover
    # and description already carry it. So only landscape/banded-portrait get one.
    ti = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(ti)
    if not overlay and not bili:
        title_y = 30 if land else 150
        tlines = wrap(d, args.title, f_title, maxw - 80, cjk=True)
        if land:                                           # landscape: translucent pill over the busy video
            tw = max(d.textlength(l, font=f_title) for l in tlines)
            th = len(tlines)*(f_title.size+16)
            d.rounded_rectangle([(W-tw)/2-42, title_y-22, (W+tw)/2+42, title_y+th+6],
                                radius=28, fill=(16, 18, 26, 200), outline=(255, 255, 255, 26), width=2)
        for i, ln in enumerate(tlines):
            w = d.textlength(ln, font=f_title)
            d.text(((W - w)/2, title_y + i*(f_title.size+16)), ln, font=f_title,
                   fill=(255, 220, 70, 255), stroke_width=2, stroke_fill=(0, 0, 0, 235))
        if not land:                                       # banded portrait: yellow accent bar + kicker
            by = title_y + len(tlines)*(f_title.size+16) + 12
            d.rounded_rectangle([W/2-70, by, W/2+70, by+9], radius=5, fill=(255, 220, 70, 255))
            if args.kicker:
                kw = d.textlength(args.kicker, font=f_kicker)
                d.text(((W-kw)/2, by+28), args.kicker, font=f_kicker, fill=(150, 172, 158, 255))
    ti.save(f"{frames}/title.png")
    Image.new("RGBA", (W, H), (0, 0, 0, 0)).save(f"{frames}/blank.png")

    # One PNG per cue: EN above, ZH below. Portrait -> bottom black band; landscape -> over video, near bottom.
    for i, (s, e, en_txt) in enumerate(en):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(img)
        en_lines = [] if args.zh_only else wrap(dd, en_txt, f_en, maxw, cjk=False)
        zh_lines = wrap(dd, zh.get(i, ""), f_zh, maxw, cjk=True) if zh.get(i) else []
        block = len(en_lines)*(f_en.size+14) + (24 if (zh_lines and en_lines) else 0) + len(zh_lines)*(f_zh.size+14)
        if bili:
            y = H - 60 - block                             # bilibili: burned at the bottom of the 16:9 frame
        elif land:
            y = H - 150 - block                            # above the platform's bottom UI overlay
        elif overlay:
            y = H - 300 - block                            # anchored low (bottom ~300px in): stays off the mid-frame content, above 视频号's bottom UI
        else:
            y = video_bottom + (H - UI_RESERVE - video_bottom - block)/2  # centered between video and reserved band
        # NO background box/panel behind subtitles in ANY layout (user rule): a
        # box/panel covers the picture. Text sits straight on the video/band and
        # relies on a heavy stroke (+shadow) for contrast. Landscape overlays the
        # video, so it needs the heavy stroke too.
        draw_subs(img, dd, en_lines, f_en, zh_lines, f_zh, y, box=False,
                  stroke=(5 if (overlay or bili or land) else 3), shadow=(bili or land))
        img.save(f"{frames}/c{i:03d}.png")

    # Concat list: gaps -> blank, each cue -> its png, timed by duration
    with open(f"{frames}/list.txt", "w") as f:
        t = 0.0
        last = "blank.png"
        for i, (s, e, _) in enumerate(en):
            if s - t > 0.04:
                f.write(f"file 'blank.png'\nduration {s-t:.3f}\n")
            f.write(f"file 'c{i:03d}.png'\nduration {max(0.04, e-s):.3f}\n")
            last = f"c{i:03d}.png"
            t = e
        if dur - t > 0.04:
            f.write(f"file 'blank.png'\nduration {dur-t:.3f}\n")
            last = "blank.png"
        f.write(f"file '{last}'\n")

    # Deliberate editorial punch-in (NOT a constant/breathing effect): the picture
    # stays full & still, and only at the --zoom-at segments does it ease IN to
    # enlarge a chosen detail, hold, then ease back OUT to full frame. Between
    # segments z=1 (whole frame, nothing cropped). zoompan emits at its own `fps`
    # regardless of source rate, so we normalize to `fps` BEFORE it (else a 50fps
    # source replays at 30fps -> slow-motion desync).
    ow, oh = (W, H) if (land or bili or overlay) else (W, vh)
    # overlay/bili fill the frame preserving aspect (pad if the source isn't exactly
    # W:H); plain landscape/portrait just scale to their slot.
    sc = (f"scale={ow}:{oh}:force_original_aspect_ratio=decrease,pad={ow}:{oh}:(ow-iw)/2:(oh-ih)/2:{bg}"
          if (overlay or bili) else f"scale={ow}:{oh}")
    zexpr = build_zoom_expr(args.zoom_at, 30) if args.zoom_at else None
    if zexpr:
        vid = (f"{sc},fps=30,"
               f"zoompan=z='{zexpr['z']}':x='{zexpr['x']}':y='{zexpr['y']}':d=1:s={ow}x{oh}:fps=30")
    else:
        vid = sc
    if land or bili or overlay:
        base = f"[0:v]{vid}[base];"
    else:
        base = f"[0:v]{vid},pad={W}:{H}:0:{video_y}:{bg}[base];"
    fc = (base +
          f"[1:v]fps=15,format=rgba[subs];[base][subs]overlay=0:0[b1];"
          f"[b1][2:v]overlay=0:0[out]")
    # 视频号 allows up to ~2GB, but bsk's upload staging caps at 512MB, so keep the
    # file under that. Default: high quality (8 Mbps cap), only dropping bitrate for
    # long videos to target ~500MB. Override with --bitrate to force a value.
    if args.bitrate:
        bv = args.bitrate
    else:
        kbps = min(8000, max(2500, int(500 * 8 * 1024 / dur)))
        bv = f"{kbps}k"
    subprocess.check_call([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-stats",
        "-i", args.video, "-f", "concat", "-safe", "0", "-i", f"{frames}/list.txt",
        "-loop", "1", "-i", f"{frames}/title.png",
        "-filter_complex", fc, "-map", "[out]", "-map", "0:a",
        "-c:v", "h264_videotoolbox", "-b:v", bv, "-c:a", "aac",
        "-movflags", "+faststart", "-shortest", args.out])
    # Guard: output must match the source length. A mismatch means a filter
    # (e.g. zoompan replaying at the wrong fps) stretched/slowed the video out
    # of sync with the audio — catch it here instead of shipping a broken clip.
    out_dur = float(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=nw=1:nk=1", args.out]))
    if abs(out_dur - dur) > 1.0:
        raise SystemExit(f"ERROR: output {out_dur:.1f}s != source {dur:.1f}s "
                         f"(video/audio out of sync). Aborting.")
    print(f"OK layout={'overlay' if overlay else args.layout} cues={len(en)} bv={bv} bg={bg} "
          f"dur={out_dur:.1f}s -> {args.out}")


if __name__ == "__main__":
    main()
