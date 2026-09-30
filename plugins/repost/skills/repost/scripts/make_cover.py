#!/usr/bin/env python3
"""Generate a 3:4 (1080x1440) cover image that HIGHLIGHTS the content — never a
black video frame. Dark gradient bg, a big yellow keyword, a white subtitle, a
small english tagline and the channel handle. This is the channel's cover style.

Usage (run with /usr/bin/python3 — it has Pillow):
  /usr/bin/python3 make_cover.py \
      --keyword "BM25" --subtitle "AI Agent 搜索的意外利器" \
      --kicker "AI ENGINEER · SEARCH & RETRIEVAL" \
      --english "The unreasonable effectiveness of BM25" \
      --out downloads/xxx-cover.jpg

--keyword is the one punchy hook (kept short: a term/number). --subtitle is the
Chinese one-liner (wraps to <=2 lines). --kicker/--english/--handle are optional.
Pick a keyword+subtitle that state what the video is about at a glance.
"""
import argparse
from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1440          # default 3:4 (视频号); --landscape switches to 16:9 (B站)
FONT = "/System/Library/Fonts/Hiragino Sans GB.ttc"
YELLOW = (255, 206, 10)
WHITE = (245, 245, 245)
GRAY = (150, 155, 170)


def wrap_cjk(draw, text, font, maxw):
    import re
    units = re.findall(r"[A-Za-z0-9][A-Za-z0-9.\-']*|\s+|[^A-Za-z0-9\s]", text)
    lines, cur = [], ""
    for u in units:
        t = cur + u
        if draw.textlength(t.strip(), font=font) <= maxw or not cur.strip():
            cur = t
        else:
            lines.append(cur.strip())
            cur = u
    if cur.strip():
        lines.append(cur.strip())
    return lines


def center(d, txt, font, y, fill):
    w = d.textlength(txt, font=font)
    d.text(((W - w) / 2, y), txt, font=font, fill=fill)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--keyword", required=True)
    ap.add_argument("--subtitle", required=True)
    ap.add_argument("--kicker", default="")
    ap.add_argument("--english", default="")
    ap.add_argument("--handle", default="@AI-Minion   中英双语")
    ap.add_argument("--landscape", action="store_true", help="16:9 (1920x1080) cover for Bilibili instead of the default 3:4")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    global W, H
    if a.landscape:
        W, H = 1920, 1080

    img = Image.new("RGB", (W, H))
    px = img.load()
    top, bot = (10, 10, 16), (14, 22, 46)
    for y in range(H):
        t = y / H
        row = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(W):
            px[x, y] = row
    d = ImageDraw.Draw(img)

    maxw = W - 140
    # keyword size shrinks if long so it always fits one line
    ks = 200 if a.landscape else 240
    f_kw = ImageFont.truetype(FONT, ks)
    while d.textlength(a.keyword, font=f_kw) > maxw and ks > 90:
        ks -= 10
        f_kw = ImageFont.truetype(FONT, ks)
    f_kick = ImageFont.truetype(FONT, 34)
    # Subtitle: shrink the font until the whole line fits in <=2 lines, so we
    # NEVER truncate mid-word (the old [:2] slice silently dropped overflow).
    sub_size = 80 if a.landscape else 92
    f_sub = ImageFont.truetype(FONT, sub_size)
    while len(wrap_cjk(d, a.subtitle, f_sub, maxw)) > 2 and sub_size > 44:
        sub_size -= 4
        f_sub = ImageFont.truetype(FONT, sub_size)
    f_en = ImageFont.truetype(FONT, 34)
    f_tag = ImageFont.truetype(FONT, 36)

    sub_lines = wrap_cjk(d, a.subtitle, f_sub, maxw)[:2]
    en_lines = wrap_cjk(d, a.english, f_en, maxw)[:2] if a.english else []
    # measure the stacked block (kicker, keyword, underline, subtitle, english) and center it
    kick_h = (f_kick.size + 30) if a.kicker else 0
    block = kick_h + ks + 40 + 70 + len(sub_lines)*(f_sub.size+18) + (20 + len(en_lines)*(f_en.size+8) if en_lines else 0)
    y = max(60, (H - block) // 2 - 20)

    if a.kicker:
        center(d, a.kicker, f_kick, y, GRAY); y += kick_h
    center(d, a.keyword, f_kw, y, YELLOW); y += ks + 30
    d.rectangle([(W/2 - 90, y), (W/2 + 90, y + 10)], fill=YELLOW); y += 70
    for ln in sub_lines:
        center(d, ln, f_sub, y, WHITE); y += f_sub.size + 18
    if en_lines:
        y += 20
        for ln in en_lines:
            center(d, ln, f_en, y, GRAY); y += f_en.size + 8
    if a.handle:
        center(d, a.handle, f_tag, H - 110, (120, 125, 140))

    if a.out.lower().endswith((".jpg", ".jpeg")):
        img.save(a.out, quality=90)
    else:
        img.save(a.out)
    print(f"cover -> {a.out} ({W}x{H})")


if __name__ == "__main__":
    main()
