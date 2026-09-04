---
name: web-search
description: "Search the web from the CLI (no browser, no MCP) and hand chosen result URLs to the web skill for reading. Use when the user asks to search the internet, find articles/libraries/docs on a topic, or look something up online. Triggers: search the web, search online, find information about, look up, google it, what libraries exist for."
license: MIT
compatibility: opencode
metadata:
  category: web
---

# web-search — Find Pages, Then Read Them

This skill only *finds* candidate URLs. It never reads page content itself —
once you've picked a result, hand its URL to the **web** skill
(`lynx -dump -nolist -width=120 "URL"`) to actually read it.

Never point `lynx` (or any HTTP client) directly at a search engine's results
page (`google.com/search`, `bing.com/search`, `duckduckgo.com/?q=`, etc.) —
that's what triggers CAPTCHAs and blocks. Always go through the tools below.

## Why not Google

`googler` is no longer maintained/available (removed from Homebrew). Google's
non-JS results page is hostile to any non-browser client — it can serve a
visual reCAPTCHA within the first few requests, sometimes on the very first
one from a cloud/VPS IP. Don't build around it.

## Primary tool — ddgr (DuckDuckGo)

```bash
ddgr --json -n 10 "scala opensearch client library" | jq -c '.[] | {title, url, abstract}'
```

- `--json` → structured output, easy to reason over
- `-n 10` → number of results (keep it modest — 5-10 is plenty)
- No API key. Scraping-based, so it's for **occasional, human-paced queries**,
  not tight loops. It degrades gracefully: instead of a CAPTCHA it serves a
  plain-text "unusual traffic from your computer network" interstitial when
  it detects abuse.

### Detecting a DDG block

If `ddgr --json` returns an empty array, non-JSON output, or you see
"unusual traffic" text on the raw HTML fallback below, DDG has rate-limited
this IP. Don't retry immediately — either wait, or switch to the fallback
tool.

## Fallback 1 — surfraw (multi-engine, rotate on block)

`surfraw` gives access to many search engines' result pages through one CLI,
which is useful for rotating engines when one is rate-limiting you. Point its
browser at `lynx -dump` so output is scriptable text instead of opening a GUI
browser:

```bash
export BROWSER='lynx -dump -nolist -width=120'
sr -p mojeek "scala opensearch client library"      # Mojeek — lightweight, scraper-tolerant
sr -p startpage "scala opensearch client library"   # Startpage
sr -p ddg "scala opensearch client library"          # DuckDuckGo, via surfraw instead of ddgr
```

- `sr -p <elvi> <query>` prints the rendered results page to stdout (via
  `$BROWSER`) instead of opening a real browser.
- `sr -elvi` lists all available search engines (`elvi`) if you want others.
- Prefer **Mojeek** or **Startpage** as first fallbacks — both are known to
  be far more tolerant of non-JS/scraper clients than Google or Bing. Avoid
  `sr google` / `sr bing` for the same CAPTCHA reasons as above.

## Fallback 2 — raw HTML dump (no extra binary)

If neither `ddgr` nor `surfraw` is installed, DuckDuckGo's no-JS HTML
endpoint can be read directly with `lynx` (same tool the **web** skill
already uses):

```bash
lynx -dump -nolist -width=120 "https://html.duckduckgo.com/html/?q=scala+opensearch+client+library"
```

This is the same engine/leniency as `ddgr`, just without JSON structure —
parse titles/URLs from the text dump.

## Workflow

1. Run `ddgr --json -n 10 "<query>"`.
2. If blocked (empty/garbled output), try `sr -p mojeek "<query>"` or
   `sr -p startpage "<query>"`, then the raw HTML dump as last resort.
3. Look at titles/URLs/abstracts, pick the most relevant 1-3 results — don't
   auto-fetch everything, snippets are often misleading.
4. Hand each chosen URL to the **web** skill to actually read the content.

## Requirements

- `ddgr` (`brew install ddgr`)
- `surfraw` (`brew install surfraw`) — optional, only needed as fallback
- `jq` — optional, for parsing `ddgr --json` cleanly

Both are installed by `kdev setup`.

## Don't

- Don't scrape Google or Bing directly — CAPTCHA territory.
- Don't loop dozens of queries back-to-back — pace requests like a human.
- Don't read page content with this skill — that's the **web** skill's job.
