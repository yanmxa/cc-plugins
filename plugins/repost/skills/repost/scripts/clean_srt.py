#!/usr/bin/env python3
"""Collapse a YouTube rolling auto-caption .srt into clean, sentence-segmented
cues. Rolling captions repeat the previous tail and append a new fragment as the
last line of each real (>50ms) cue; we take those fragments, then re-segment on
sentence punctuation with length/duration caps.

Usage: /usr/bin/python3 clean_srt.py IN.srt OUT.srt [total_seconds]
"""
import re, sys

MAX_CHARS = 90
MAX_DUR = 5.5


ZW = str.maketrans("", "", "​‌‍﻿")  # zero-width chars render as tofu in Hiragino


def parse(path):
    cues = []
    text = open(path, encoding="utf-8").read().translate(ZW).strip()
    for b in re.split(r"\n\s*\n", text):
        m = re.search(r"(\d+):(\d+):(\d+)[,.](\d+)\s*-->\s*(\d+):(\d+):(\d+)[,.](\d+)", b)
        if not m:
            continue
        g = list(map(int, m.groups()))
        s = g[0]*3600 + g[1]*60 + g[2] + g[3]/1000
        e = g[4]*3600 + g[5]*60 + g[6] + g[7]/1000
        lines = [l for l in b.splitlines()]
        i = [k for k, l in enumerate(lines) if "-->" in l][0]
        cues.append((s, e, lines[i+1:]))
    return cues


def fmt(t):
    h = int(t//3600); m = int(t % 3600//60); s = int(t % 60); ms = int(round((t-int(t))*1000))
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"


def main():
    src, out = sys.argv[1], sys.argv[2]
    total = float(sys.argv[3]) if len(sys.argv) > 3 else None

    # Extract new fragments (last non-empty line of each real cue), deduped.
    frags = []
    for s, e, lines in parse(src):
        if e - s < 0.05:
            continue
        ne = [l.strip() for l in lines if l.strip()]
        if not ne:
            continue
        f = ne[-1]
        if f in ("[music]", "[Music]", "[applause]"):
            continue
        if frags and frags[-1][1] == f:
            continue
        frags.append((s, f))

    # Re-segment fragments into clean cues.
    cues, cur, start = [], "", None
    for idx, (s, f) in enumerate(frags):
        if start is None:
            start = s
        cur = (cur + " " + f).strip()
        nxt = frags[idx+1][0] if idx+1 < len(frags) else (total or s+MAX_DUR)
        ends_sent = cur.endswith((".", "?", "!", "…"))
        if ends_sent or len(cur) >= MAX_CHARS or (nxt - start) >= MAX_DUR:
            cues.append((start, nxt, cur))
            cur, start = "", None
    if cur:
        cues.append((start, total or start+MAX_DUR, cur))

    with open(out, "w", encoding="utf-8") as fh:
        for i, (s, e, t) in enumerate(cues, 1):
            fh.write(f"{i}\n{fmt(s)} --> {fmt(e)}\n{t}\n\n")
    print(f"clean cues={len(cues)} -> {out}")


if __name__ == "__main__":
    main()
