---
name: web
description: "Read web pages as plain text using lynx. Use for docs, blogs, wikis, READMEs, articles. Triggers: read page, fetch url, open link, web page, browse, read site, what does this page say."
license: MIT
compatibility: opencode
metadata:
  category: web
---

# web — Read Web Pages

## Tool

```bash
lynx -dump -nolist -width=120 "URL"
```

Flags:
- `-dump` → render page as plain text to stdout
- `-nolist` → omit link reference list at bottom
- `-width=120` → wrap at 120 chars for readability

## Usage

Call via `bash` tool. Example:

```bash
lynx -dump -nolist -width=120 "https://docs.example.com/api"
```

## When Output Too Long

Pipe through `head` or `tail`:

```bash
lynx -dump -nolist -width=120 "URL" | head -200
```

Or search within page:

```bash
lynx -dump -nolist -width=120 "URL" | grep -i -A5 "section heading"
```

## Limitations

- **No JavaScript** — SPAs (React/Vue/Next) render blank or broken
- **No cookies/auth** — gated content won't load
- **Tables** — rendered but may look odd in complex layouts

Works great for: documentation sites, Wikipedia, GitHub pages, blogs, static sites, man pages online, RFC specs.

## Do

- Use full URL with protocol (`https://...`)
- Pipe to `head -N` if page is massive
- Quote the URL

## Don't

- Use on JS-heavy sites (Twitter, Reddit modern, SPAs)
- Expect images or media content
- Forget protocol prefix
