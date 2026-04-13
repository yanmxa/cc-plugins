#!/usr/bin/env python3
"""Video downloader using yt-dlp."""

import argparse
import json
import os
import shutil
import subprocess
import sys


def ensure_ytdlp():
    """Install yt-dlp if not available."""
    if shutil.which("yt-dlp"):
        return
    print("yt-dlp not found, installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "yt-dlp"])
    user_bin = os.path.expanduser("~/.local/bin")
    if user_bin not in os.environ.get("PATH", ""):
        os.environ["PATH"] = user_bin + os.pathsep + os.environ.get("PATH", "")
    if not shutil.which("yt-dlp"):
        print("ERROR: yt-dlp installed but not found on PATH.", file=sys.stderr)
        sys.exit(1)


def probe(url):
    """Fetch video metadata and print available options as JSON."""
    cmd = ["yt-dlp", "--no-playlist", "-j", url]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Failed to fetch video info: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    info = json.loads(result.stdout)

    # Collect unique resolutions from formats
    resolutions = set()
    for f in info.get("formats", []):
        h = f.get("height")
        if h and f.get("vcodec", "none") != "none":
            resolutions.add(h)
    resolutions = sorted(resolutions, reverse=True)

    # Collect available subtitle languages
    subs = {}
    for lang, tracks in info.get("subtitles", {}).items():
        # Pick the best name available
        name = None
        for t in tracks:
            if t.get("name"):
                name = t["name"]
                break
        subs[lang] = name or lang
    auto_subs = {}
    for lang, tracks in info.get("automatic_captions", {}).items():
        name = None
        for t in tracks:
            if t.get("name"):
                name = t["name"]
                break
        auto_subs[lang] = name or lang

    output = {
        "title": info.get("title"),
        "duration": info.get("duration_string") or info.get("duration"),
        "uploader": info.get("uploader"),
        "resolutions": [f"{h}p" for h in resolutions],
        "subtitles": subs,
        "auto_subtitles": auto_subs,
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))


QUALITY_MAP = {
    "best": "bestvideo+bestaudio/best",
    "2160p": "bestvideo[height<=2160]+bestaudio/best[height<=2160]",
    "1440p": "bestvideo[height<=1440]+bestaudio/best[height<=1440]",
    "1080p": "bestvideo[height<=1080]+bestaudio/best[height<=1080]",
    "720p": "bestvideo[height<=720]+bestaudio/best[height<=720]",
    "480p": "bestvideo[height<=480]+bestaudio/best[height<=480]",
    "360p": "bestvideo[height<=360]+bestaudio/best[height<=360]",
    "worst": "worstvideo+worstaudio/worst",
}


def download(url, quality="best", fmt="mp4", audio_only=False, output_dir=None,
             subs=None, auto_subs=None, embed_subs=False):
    if output_dir is None:
        output_dir = os.path.expanduser("~/Downloads")
    os.makedirs(output_dir, exist_ok=True)

    output_template = os.path.join(output_dir, "%(title)s.%(ext)s")
    cmd = ["yt-dlp", "--no-playlist", "-o", output_template]

    if audio_only:
        cmd += ["-x", "--audio-format", "mp3"]
    else:
        fmt_select = QUALITY_MAP.get(quality, QUALITY_MAP["best"])
        cmd += ["-f", fmt_select, "--merge-output-format", fmt]

    # Subtitle options
    if subs:
        cmd += ["--write-sub", "--sub-langs", subs]
    if auto_subs:
        cmd += ["--write-auto-sub", "--sub-langs", auto_subs]
    if embed_subs and not audio_only:
        cmd.append("--embed-subs")

    cmd.append(url)

    print(f"Downloading: {url}")
    print(f"Quality: {quality} | Format: {'mp3 (audio)' if audio_only else fmt} | Output: {output_dir}")
    if subs:
        print(f"Subtitles: {subs}")
    if auto_subs:
        print(f"Auto subtitles: {auto_subs}")
    if embed_subs:
        print("Subtitles will be embedded into the video")
    print(f"Command: {' '.join(cmd)}\n")

    result = subprocess.run(cmd)
    if result.returncode == 0:
        print(f"\nDone! File saved to: {output_dir}")
    else:
        print(f"\nDownload failed with exit code {result.returncode}", file=sys.stderr)
        sys.exit(result.returncode)


def main():
    parser = argparse.ArgumentParser(description="Download videos with yt-dlp")
    parser.add_argument("url", help="Video URL")
    parser.add_argument("--probe", action="store_true",
                        help="Show video info (resolutions, subtitles) as JSON, don't download")
    parser.add_argument("-q", "--quality", default="best",
                        choices=["best", "2160p", "1440p", "1080p", "720p", "480p", "360p", "worst"])
    parser.add_argument("-f", "--format", default="mp4", dest="fmt",
                        choices=["mp4", "webm", "mkv"])
    parser.add_argument("-a", "--audio-only", action="store_true")
    parser.add_argument("-o", "--output", default=None, help="Output directory")
    parser.add_argument("-s", "--subs", default=None,
                        help="Download subtitles for these languages (comma-separated, e.g. en,zh-Hans)")
    parser.add_argument("--auto-subs", default=None,
                        help="Download auto-generated subtitles (comma-separated language codes)")
    parser.add_argument("--embed-subs", action="store_true",
                        help="Embed subtitles into the video file")
    args = parser.parse_args()

    ensure_ytdlp()

    if args.probe:
        probe(args.url)
    else:
        download(args.url, args.quality, args.fmt, args.audio_only, args.output,
                 args.subs, args.auto_subs, args.embed_subs)


if __name__ == "__main__":
    main()
