# llms.txt Generator

Generates a machine-readable summary of SGOS documentation optimized for LLM consumption.

## What it does

1. Scans all markdown files in `docs/`
2. Sends each to Claude for summarization (maximizing semantic density)
3. Outputs a single `llms.txt` file with all facts, no prose
4. Caches summaries by content hash to avoid redundant API calls

## Output

- `/llms.txt` — committed to repo, ~27% of original size
- `/docs/static/llms.txt` — symlink for web access at `sgos-infra.sgl.as/llms.txt`

## Usage

```bash
cd /path/to/sgos-infra
python3 tools/llms-txt/generate-llms-txt.py
```

## Requirements

- Python 3.10+
- `claude` CLI installed and authenticated

## Excluding documents

Add `human_only: true` to front matter to exclude prose/narrative content:

```yaml
---
title: Why We Built SGOS
human_only: true
---
```

## Caching

Summaries are cached in `.llms-cache.json` (gitignored). Cache key is content hash — only changed files are re-summarized.

First run: slow (calls Claude for each doc)
Subsequent runs: instant (uses cache)

## Ordering

Documents are sorted by:
1. `intro.md` first
2. Directory grouping (`apps/`, `infrastructure/`)
3. `sidebar_position` within each section

## Regenerating

To force full regeneration:

```bash
rm .llms-cache.json
python3 tools/llms-txt/generate-llms-txt.py
```

## Output format

```
# SGOS Documentation - LLM Reference
# Generated: 2026-01-15 14:28
# Source: https://sgos-infra.sgl.as
# Entries: 12

---
## Document Title
path: docs/path/to/file.md
url: https://sgos-infra.sgl.as/path/to/file

Dense summary with all facts, identifiers, URLs, specs. No prose or formatting.
```
