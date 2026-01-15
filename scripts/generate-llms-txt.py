#!/usr/bin/env python3
"""Generate llms.txt from Docusaurus documentation.

Scans docs/**/*.md, summarizes each with Claude, outputs condensed
LLM-optimized reference file. Caches summaries to avoid redundant API calls.

Usage:
    python scripts/generate-llms-txt.py

Requirements:
    - Python 3.10+
    - claude CLI installed and authenticated
"""

import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

# Configuration
DOCS_DIR = Path("docs")
CACHE_FILE = Path(".llms-cache.json")
OUTPUT_FILE = Path("llms.txt")
STATIC_LINK = Path("docs/static/llms.txt")
BASE_URL = "https://sgos-infra.sgl.as"

SUMMARIZE_PROMPT = """You are compressing documentation into LLM-optimized reference text.

INPUT DOCUMENT:
{content}

TASK:
Produce a summary that maximizes semantic density, factual completeness, and retrievability.

RULES:
- Extract ALL concrete facts: names, URLs, IPs, ports, statuses, connections, specs
- Preserve technical identifiers exactly (sgos-phone, 100.67.57.25, etc.)
- Remove prose, explanations, context-setting, transitions
- Remove formatting artifacts (headers, bullets, tables) - output plain text
- Use terse notation: "Phone (sgos-phone, phone.sgl.as, Live): voicemail processing via Placetel"
- Compress related items: "Servers: Hornbill (apps, 100.67.57.25), Toucan (control, 100.102.199.98)"
- No introductions, conclusions, or meta-commentary
- Output raw facts only, optimized for retrieval

OUTPUT: Dense reference text, one paragraph, no line breaks unless separating major sections."""


def get_file_hash(content: str) -> str:
    """SHA256 hash of content."""
    return hashlib.sha256(content.encode()).hexdigest()[:16]


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Extract YAML front matter and body from markdown."""
    if not content.startswith("---"):
        return {}, content

    match = re.match(r"^---\n(.*?)\n---\n(.*)$", content, re.DOTALL)
    if not match:
        return {}, content

    frontmatter_str, body = match.groups()

    # Simple YAML parsing (no external deps)
    frontmatter = {}
    for line in frontmatter_str.split("\n"):
        if ":" in line:
            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip()
            # Handle booleans
            if value.lower() == "true":
                value = True
            elif value.lower() == "false":
                value = False
            # Handle numbers
            elif value.isdigit():
                value = int(value)
            # Strip quotes
            elif value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            frontmatter[key] = value

    return frontmatter, body


def doc_path_to_url(path: Path) -> str:
    """Convert filesystem path to documentation URL."""
    # docs/apps/overview.md -> /apps/overview
    relative = path.relative_to(DOCS_DIR)
    url_path = str(relative).replace(".md", "").replace(".mdx", "")

    # Handle index files
    if url_path.endswith("/index"):
        url_path = url_path[:-6]
    elif url_path == "index":
        url_path = ""

    # intro.md -> /
    if url_path == "intro":
        url_path = ""

    return f"{BASE_URL}/{url_path}" if url_path else BASE_URL


def summarize_with_claude(content: str) -> str:
    """Call Claude CLI to summarize content."""
    prompt = SUMMARIZE_PROMPT.format(content=content[:15000])  # Limit input size

    try:
        result = subprocess.run(
            ["claude", "-p", prompt, "--output-format", "text"],
            capture_output=True,
            text=True,
            timeout=120,
        )

        if result.returncode != 0:
            print(f"  Claude error: {result.stderr}", file=sys.stderr)
            return ""

        return result.stdout.strip()

    except subprocess.TimeoutExpired:
        print("  Claude timeout", file=sys.stderr)
        return ""
    except FileNotFoundError:
        print("  Claude CLI not found - is it installed?", file=sys.stderr)
        sys.exit(1)


def load_cache() -> dict:
    """Load summary cache from disk."""
    if CACHE_FILE.exists():
        return json.loads(CACHE_FILE.read_text())
    return {}


def save_cache(cache: dict):
    """Save summary cache to disk."""
    CACHE_FILE.write_text(json.dumps(cache, indent=2))


def get_sort_key(md_file: Path, frontmatter: dict) -> tuple:
    """Generate sort key based on directory and sidebar_position."""
    # Get directory depth and name for grouping
    relative = md_file.relative_to(DOCS_DIR)
    parts = list(relative.parts[:-1])  # Directory parts

    # Sidebar position (default to 999 if not set)
    position = frontmatter.get("sidebar_position", 999)

    # intro.md should come first
    if md_file.name == "intro.md":
        return (0, 0, "")

    # Sort by: directory path, then sidebar_position, then filename
    return (1, len(parts), "/".join(parts), position, md_file.name)


def main():
    print("Generating llms.txt...")

    cache = load_cache()
    entries = []
    stats = {"cached": 0, "generated": 0, "skipped": 0}

    # Find all markdown files and pre-parse for sorting
    md_files = list(DOCS_DIR.rglob("*.md")) + list(DOCS_DIR.rglob("*.mdx"))

    # Parse frontmatter for sorting
    files_with_frontmatter = []
    for md_file in md_files:
        if md_file.name.startswith("_"):
            continue
        content = md_file.read_text()
        frontmatter, _ = parse_frontmatter(content)
        files_with_frontmatter.append((md_file, frontmatter, content))

    # Sort by sidebar position
    files_with_frontmatter.sort(key=lambda x: get_sort_key(x[0], x[1]))

    for md_file, frontmatter, content in files_with_frontmatter:
        relative_path = str(md_file)
        _, body = parse_frontmatter(content)

        # Skip human-only content
        if frontmatter.get("human_only"):
            print(f"  SKIP (human_only): {relative_path}")
            stats["skipped"] += 1
            continue

        # Skip empty or very short files
        if len(body.strip()) < 100:
            print(f"  SKIP (too short): {relative_path}")
            stats["skipped"] += 1
            continue

        title = frontmatter.get("title", md_file.stem.replace("-", " ").title())
        file_hash = get_file_hash(content)
        cache_key = relative_path

        # Check cache
        if cache.get(cache_key, {}).get("hash") == file_hash:
            print(f"  CACHED: {relative_path}")
            summary = cache[cache_key]["summary"]
            stats["cached"] += 1
        else:
            print(f"  GENERATING: {relative_path}")
            summary = summarize_with_claude(f"# {title}\n\n{body}")
            if summary:
                cache[cache_key] = {
                    "hash": file_hash,
                    "summary": summary,
                    "title": title,
                }
                stats["generated"] += 1
            else:
                print(f"  FAILED: {relative_path}")
                continue

        entries.append({
            "title": title,
            "path": relative_path,
            "url": doc_path_to_url(md_file),
            "summary": summary,
        })

    # Save updated cache
    save_cache(cache)

    # Generate llms.txt
    output_lines = [
        "# SGOS Documentation - LLM Reference",
        f"# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        f"# Source: {BASE_URL}",
        f"# Entries: {len(entries)}",
        "",
    ]

    for entry in entries:
        output_lines.extend([
            "---",
            f"## {entry['title']}",
            f"path: {entry['path']}",
            f"url: {entry['url']}",
            "",
            entry["summary"],
            "",
        ])

    OUTPUT_FILE.write_text("\n".join(output_lines))

    # Create symlink in static folder for web access
    STATIC_LINK.parent.mkdir(parents=True, exist_ok=True)
    if STATIC_LINK.is_symlink():
        STATIC_LINK.unlink()
    if not STATIC_LINK.exists():
        # Relative symlink from docs/static/ to repo root
        STATIC_LINK.symlink_to("../../llms.txt")

    print(f"\nDone! Generated {OUTPUT_FILE}")
    print(f"  Cached: {stats['cached']}, Generated: {stats['generated']}, Skipped: {stats['skipped']}")


if __name__ == "__main__":
    main()
