---
name: build-doc
description: >
  Format-aware document and interface builder. Fires BEFORE building anything — runs a
  pre-build interview (quick or full depending on complexity), then builds with continuous
  organization and readability self-checks. Use this skill whenever the user asks to build,
  create, or make any of: an HTML page, HTML dashboard, HTML interface, Word document, Word
  doc, report, study guide, PowerPoint presentation, PowerPoint deck, Excel file, Excel
  spreadsheet, Excel tracker. Also fires on phrases like "build me a", "create a", "make a",
  "put together a" followed by a document/interface type. Always interview BEFORE building —
  never start writing content without completing the pre-build questions first.
user-invocable: true
argument-hint: "html | word | pptx | excel | [describe what to build]"
---

# Build-Doc

A two-phase skill: **interview first, build second**. Phase 1 asks what to build and how to
organize it. Phase 2 builds it with a silent readability/organization checklist running after
every section — interrupting only on failures, then showing a full review at the end.

Supports: HTML interfaces, Word documents (.docx), PowerPoint presentations (.pptx),
Excel workbooks (.xlsx). Each format gets its own question set and its own build method.

---

## Guardrails

- **Never start building without completing the pre-build interview.** Even if the request
  seems obvious, run the interview. No guessing.
- **Never overwrite an existing file without asking.** Check if the target path exists first.
  If it does: "A file already exists at [path]. Overwrite it? (yes/no)"
- **Never skip the self-check, even for simple one-page builds.** The checklist runs every
  time. Short builds still get checked — they just finish faster.
- **Never produce placeholder content.** No "Lorem ipsum", "[Insert here]", "TBD", or any
  stub text. Every section must contain real, complete content agreed on in the interview.
- **Never start Phase 2 (building) until Phase 1 (interview) produces a clear spec.** If
  answers are contradictory or incomplete, ask one follow-up before proceeding.
- **Stop completely on build error — no partial files.** If the build fails mid-way, do not
  leave a broken file. Report the error and wait for user direction.
- **Research-driven builds must use sources across all time frames.** Never rely only on
  pre-2020 studies. Always include the most recent available research (current year and
  prior year). Older foundational studies are fine to include alongside recent ones, but
  a build where every citation is 5+ years old fails this guardrail.

---

## Gotchas

- **Primary failure mode: right content, poor organization.** The most likely bad outcome is
  a wall of text with no visual hierarchy — correct information that a human cannot scan. The
  self-check is specifically calibrated to catch this. If anything fails the organization check,
  stop and fix it before moving to the next section.
- **Ambiguous format request** — "build me a report" or "create a tracker" without specifying
  the format. Always confirm: "What format? Word, Excel, HTML, or PowerPoint?"
- **Interview questions too generic** — if answers are vague (e.g., "just make it look good"),
  probe: "What does 'good' mean here — clean and minimal, color-coded, table-heavy, or
  something else?" Don't accept vague aesthetics as a spec.
- **COM automation errors (Word/PowerPoint/Excel)** — these tools use PowerShell COM.
  Existing Word processes can cause SaveAs failures (see the Options Study Guide history).
  Always kill stale WINWORD/EXCEL/POWERPNT processes before running the script.
- **File already open in another process** — if SaveAs throws a COM error, the output file
  is likely locked. Kill the process, delete the locked file, and re-run.
- **Quick vs Full misread** — "one-page" and "quick" signals quick mode. "Detailed", "full",
  "comprehensive", "study guide", "complete", or any multi-part ask signals full mode. When
  unsure, ask: "Quick build (3 questions) or full interview?"
- **Stale research** — the most common research failure is leaning on well-known older
  studies while missing newer findings that update or contradict them. Before finalizing
  any research-driven build, explicitly ask: "Do I have at least one source from the past
  12 months? From the past 24 months?" If no, use the `/deep-research` skill or WebSearch
  to fill the gap before writing content. Flag contested or outdated claims in the footnotes.

---

## Phase 1 — Pre-Build Interview

### Complexity Detection

Before asking anything, assess the request:

**Quick mode triggers** (3–4 questions):
- "one-page", "simple", "quick", "cheat sheet", "basic", "one-tab"
- Short noun phrases: "a login page", "a budget tracker", "a timeline slide"
- The user gives a very specific, narrow request

**Full mode triggers** (format-specific question set):
- "detailed", "full", "comprehensive", "in-depth", "complete"
- Multi-part: "a study guide with 7 chapters", "a 10-slide deck"
- Anything involving multiple sections, sheets, or slides
- The request is open-ended or scope is unclear

**When in doubt:** Ask one question first — "Quick build (3 questions) or full interview?"

---

### Universal Questions (always asked in both modes)

Always ask these 3–4 questions regardless of mode:

1. **Format confirmation** — "What format: HTML, Word (.docx), PowerPoint (.pptx), or
   Excel (.xlsx)?" (skip if already clear from the request)
2. **Core content** — "What is this about and what must it include?" Get specifics. If
   the answer is vague, probe for the 3–5 main topics or sections.
3. **Audience** — "Who will read or use this?" (just you, a team, clients, beginners,
   experts?) This determines vocabulary level and how much explanation is needed.
4. **Output path** — "Where should I save this?" Default suggestions by format:
   - HTML → saved to **both** locations automatically:
     - `C:\htmls\[name].html` (primary — short URL for browser)
     - `C:\Users\mdecker\.claude\skills\Builds\htmls\[name].html` (archive copy)
   - Word → `C:\Users\mdecker\.claude\skills\build-doc\outputs\word\[name].docx`
   - PowerPoint → `C:\Users\mdecker\.claude\skills\build-doc\outputs\pptx\[name].pptx`
   - Excel → `C:\Users\mdecker\.claude\skills\build-doc\outputs\excel\[name].xlsx`
   User can override any of these. For HTML, always write the primary file first,
   then copy it to the archive location. Confirm both paths in the build summary.

---

### Format-Specific Questions (full mode only)

Run these AFTER the universal questions, tailored to the detected format:

#### Word (.docx)
- How many sections or chapters? What are their names/topics?
- Should it include tables? If yes, how many and what data?
- Page target (e.g., 5 pages, 10 pages, no limit)?
- Any specific formatting rules: font, margins, heading style, color scheme?

#### HTML Interface
- **Style approach (ask this first for HTML):**
  > "Style approach for this HTML build?"
  > - **Clean / functional** — optimized for data density and readability. Organized layout,
  >   clear hierarchy, neutral colors, no distractions. Best for dashboards, reference pages,
  >   trackers, study tools.
  > - **Design-forward** — distinctive aesthetic, memorable visuals, creative layout. Best
  >   for landing pages, portfolios, presentations, anything meant to impress.
  >
  > If the user picks **design-forward**, hand off to the `/frontend-design` skill
  > immediately after the interview. Pass the full spec (content, layout, audience, path)
  > as context. `frontend-design` owns the entire HTML build — do not run the
  > build-doc HTML build steps for that run.
  >
  > If the user picks **clean / functional**, continue with build-doc's own HTML build
  > steps below (semantic HTML, system-ui font, readable defaults).

- Layout style: single column, two-column, dashboard (card grid), tabbed interface?
- Color scheme: dark mode, light mode, brand colors, or minimal/plain?
- **Interactivity is always included.** Do not ask whether to add it — ask which type:
  "What kind of interactivity fits this best?" Options: tabbed sections, collapsible
  accordions, filterable/searchable tables, animated counters, hover tooltips, a sticky
  nav with smooth scroll, or a combination. Default to at least tabs or collapsibles if
  the user has no preference.
- Should it be self-contained (one .html file) or separate CSS/JS files?

#### PowerPoint (.pptx)
- How many slides? What goes on each slide (title + bullets? title + table? full-image?)
- Audience and presentation context: internal/external, formal/informal?
- Dark or light theme? Any specific colors?
- Should slides include presenter notes?

#### Excel (.xlsx)
- How many sheets? What does each sheet contain?
- Data entry, reporting/display, or both?
- Are formulas or calculations needed? Describe them.
- Should it include filters, freeze panes, drop-down lists, or conditional formatting?

---

## Phase 2 — Build

### Before Writing Any Content

1. Read relevant memory files from
   `C:\Users\mdecker\.claude\projects\c--Users-mdecker--claude-skills\memory\` to load
   any saved style preferences (fonts, colors, formatting rules) before starting.
2. Confirm the output path. If the file already exists, ask before overwriting.
3. Kill any stale processes for the target format before running COM automation:
   ```powershell
   Get-Process WINWORD  -ErrorAction SilentlyContinue | Stop-Process -Force  # Word
   Get-Process EXCEL    -ErrorAction SilentlyContinue | Stop-Process -Force  # Excel
   Get-Process POWERPNT -ErrorAction SilentlyContinue | Stop-Process -Force  # PowerPoint
   ```
4. State the build plan before starting: "Building [X] with [N] sections/slides/sheets.
   Saving to [path]. Starting now..."

---

### Research Requirements (for data-driven builds)

If the build requires external facts, statistics, or studies — apply these rules before
writing a single line of content:

**Source time distribution — required for every research build:**

| Time Frame | Minimum Required | Purpose |
|---|---|---|
| Current year (2026) or prior year (2025) | At least 2 sources | Recency — captures what has changed |
| Last 5 years (2021–2026) | Majority of sources | Core evidence base |
| Foundational / classic research | Fine to include | Context and original theory |

**Rules:**
- Use `/deep-research` or WebSearch to find recent sources before writing. Do not rely
  solely on training-data knowledge for facts, statistics, or study results.
- For each major claim, note the year of the source. If the most recent source on a topic
  is older than 3 years, search for updates — the field may have moved.
- Distinguish between **foundational** (theory, mechanism — older sources OK) and
  **current** (statistics, prevalence, platform behavior — must be recent). A 1938
  Skinner paper is fine for explaining variable ratio reinforcement. A 2018 screen time
  stat is not current enough for a 2026 dashboard.
- At the end of research, run a time-coverage check: "Do I have sources from 2025 or
  2026? If not, what recent search would fill that gap?"
- Label contested or methodologically weak claims inline (e.g., "widely cited but not
  peer-reviewed" or "correlation; causation debated").

---

### Self-Check Checklist

Run this checklist silently after **every section, slide, or sheet** you complete. Report
only on **failures** — passing checks are silent. At the very end, show the full summary table.

#### Organization Checks
- [ ] **Heading present** — Does this section/slide have a clear, descriptive heading?
- [ ] **Logical grouping** — Is content grouped so related items are together? No random mixing.
- [ ] **No walls of text** — Paragraphs are ≤ 5 lines. Longer content is broken up with bullets or sub-headings.
- [ ] **Table discipline** — All tables have bold headers, consistent column widths, and alternating row shading or clear borders.
- [ ] **Visual separation** — Is there clear spacing between sections? A reader's eye should be able to find the start of a new topic instantly.

#### Readability Checks
- [ ] **Cold-read test** — Would a human reading this for the first time understand what they're looking at without being told?
- [ ] **Hierarchy is visible** — Main points are clearly bigger/bolder than sub-points. The visual weight matches the content importance.
- [ ] **No jargon without definition** — Any technical term used is explained on first appearance (or is known to the audience confirmed in the interview).
- [ ] **Consistent styling** — Font, size, and color are consistent with the rest of the document. No one-off rogue formatting.
- [ ] **No filler** — Every sentence or row adds something. Ask: "If I removed this, would the reader miss anything important?" If no, cut it.

#### On Failure
If any check fails: **stop, fix the section, re-check, then continue**. Do not proceed to
the next section with a failed check. Tell the user what failed and what you changed:
> "Organization check: 'No walls of text' failed in section [X] — split into 3 bullets
> instead of a 4-line paragraph. Fixed."

---

### Build Methods by Format

#### Word (.docx)
Use PowerShell Word COM automation. Follow the exact patterns from the Options Study Guide
build script (`C:\Users\mdecker\.claude\skills\docx\build-options-guide.ps1`):
- Single-quoted strings for all content (never double-quoted — encoding issues)
- Apostrophes escaped as `''` in single-quoted strings
- No em dashes — use ` - ` (space-hyphen-space) instead
- Table cursor fix: `$sel.Start = $tbl.Range.End; $sel.End = $tbl.Range.End` after every table
- Page setup: 0.75" margins, 10pt Arial, US Letter
- Save with: `$doc.SaveAs([ref]$out, [ref]16)`

#### HTML Interface
Write a single self-contained `.html` file unless the user requested separate CSS/JS.
Structure:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Title]</title>
  <style>/* All styles inline */</style>
</head>
<body><!-- Content --></body>
<script>/* All JS inline */</script>
</html>
```
Use semantic HTML (`<section>`, `<article>`, `<header>`, `<table>`). Every table gets
`<thead>` with `<th>` elements. Font: system-ui or Arial. Default color scheme: clean
white background, dark text, accent color for headers.

**Interactivity is mandatory on every HTML build.** Every HTML file must include at least
one of the following — chosen to fit the content, not bolted on randomly:

| Interactive Element | When to Use | Implementation |
|---|---|---|
| Sticky nav + smooth scroll | Any multi-section page | `position: fixed` nav, `scroll-behavior: smooth`, anchor links |
| Tabbed sections | Content with 3+ parallel categories | JS `classList.toggle('active')` on tab click |
| Collapsible accordions | Long lists, FAQs, details that clutter | `<details>`/`<summary>` or JS toggle |
| Filterable table | Any data table with 8+ rows | JS filter on `input` event, hide non-matching rows |
| Searchable content | Reference pages, dashboards | Input field filtering visible sections or rows |
| Animated counters | Stat/number-heavy pages | JS count-up on page load or scroll-into-view |
| Hover tooltips | Tables or charts with extra context | CSS `:hover` + `::after` pseudo-element |
| Dark/light mode toggle | Any dashboard or reference tool | JS toggle class on `<body>`, CSS variables |

**Minimum baseline for any HTML build:** sticky nav (if multi-section) + at least one
content interaction (tabs, accordion, filter, or counter). A static HTML page with no JS
and no interactive elements fails the self-check and must be revised before saving.

#### PowerPoint (.pptx)
Use PowerShell PowerPoint COM automation:
```powershell
$ppt = New-Object -ComObject PowerPoint.Application
$ppt.Visible = 1
$pres = $ppt.Presentations.Add()
# Add slides, set layouts, add text boxes, set fonts
$pres.SaveAs($out, 24)  # 24 = ppSaveAsOpenXMLPresentation (.pptx)
$pres.Close(); $ppt.Quit()
```
Standard slide structure: title placeholder (font 28pt bold) + content placeholder (font
18pt). Title slide uses a different layout. Keep slides uncluttered — max 6 bullet points
per slide. Presenter notes go in `$slide.NotesPage.Shapes[2].TextFrame.TextRange.Text`.

#### Excel (.xlsx)
Use PowerShell Excel COM automation:
```powershell
$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false; $xl.DisplayAlerts = $false
$wb = $xl.Workbooks.Add()
# Add/rename sheets, populate cells, apply formatting
$wb.SaveAs($out, 51)  # 51 = xlOpenXMLWorkbook (.xlsx)
$wb.Close($false); $xl.Quit()
```
Always: freeze the top row (`$sheet.Rows.Item(2).Select(); $xl.ActiveWindow.FreezePanes = $true`),
bold headers, auto-fit columns (`$sheet.UsedRange.Columns.AutoFit()`), and apply table
formatting (alternating row colors) for any data range with 3+ rows.

---

### End-of-Build Summary

After finishing the last section and closing the file, show this table:

```
BUILD COMPLETE — [filename].[ext]
─────────────────────────────────────────────────────
Format:         [Word | HTML | PowerPoint | Excel]
Saved to:       [full path]
File size:      [X KB]
Sections built: [N]

SELF-CHECK SUMMARY
──────────────────
Section / Slide / Sheet    | All Checks Passed?  | Issues Fixed
─────────────────────────────────────────────────────────────
[Section 1]                | YES                 | —
[Section 2]                | YES (1 fix)         | Wall of text → bullets
[Section N]                | ...                 | ...
─────────────────────────────────────────────────────────────
Overall: [N] checks run, [N] passed on first try, [N] fixed inline.
```

Then ask: "Want me to open the file now, or are there any sections you'd like me to revise?"

---

## Steps (Execution Order)

1. **Detect request.** Auto-trigger fires on build keywords + format type. If manual `/build-doc`
   with argument, parse the argument for format and topic hints.

2. **Complexity check.** Determine quick vs full interview mode from the request language.

3. **Run pre-build interview.** Universal questions first (always). Format-specific questions
   second (full mode only). Do not start building until all required answers are in hand.

4. **Read memory.** Load style preferences from `.claude` memory before writing a single line
   of content.

5. **Confirm output path.** Check if file exists. Ask before overwriting.

6. **Kill stale processes.** Run the appropriate process-kill command for the target format.

7. **Build section by section.** After each section/slide/sheet, run the full self-check
   checklist silently. Fix failures inline before continuing. Surface fixes to the user.

8. **Update TOC / index if applicable.** Word docs: update Table of Contents.
   Excel: update named ranges or sheet index if present.

9. **Save the file.** Use the format-specific `SaveAs` call. Verify the file exists at the
   target path and size > 0 bytes after saving.

10. **Show end-of-build summary table** (section × check results).

11. **Save any new style decisions to memory.** If the user confirmed preferences (font,
    color scheme, layout style) that are not already in memory, save them to a feedback or
    user memory file.

12. **Call `/vault`** to index the new output file and update CLAUDE.md.

---

## Embedded Skills and Callouts

- **`docx/build-options-guide.ps1`** — reference implementation for Word COM automation.
  All Word builds must follow its patterns (single-quoted strings, cursor fix after tables,
  SaveAs format constant). Do not reinvent the approach; adapt the script.
- **`/frontend-design`** — called instead of the build-doc HTML build steps when the user
  selects "design-forward" in the HTML style question. Pass the full spec gathered in the
  interview (content, layout, audience, interactivity, output path) as context. Do not
  run both — `frontend-design` owns the build entirely for that run.
- **`/vault`** — called as the final step after every successful build. Indexes the output
  file in `outputs/index.json` and regenerates CLAUDE.md from memory.
- **`/interview`** — the pre-build interview in Phase 1 uses the same AskUserQuestion
  multi-choice pattern as the interview skill. It is NOT a call to `/interview` — the
  questions are embedded here and tailored to document building.

---

## Memory Allocation

| What | Where | Purpose |
|------|-------|---------|
| Style preferences (fonts, colors, margins) | `.claude` memory — user or feedback type | Loaded at build start; avoids re-asking every time |
| New style decisions confirmed in this run | `.claude` memory — written after build | Persists preferences for future builds |
| Output files | `build-doc/outputs/[format]/` (default) or user-specified path | One subfolder per format: word/, html/, pptx/, excel/ |
| PowerShell build scripts | `build-doc/scripts/` | One script per format, generated per build, saved for reference |

Sub-files:

```
build-doc/
├── SKILL.md            ← this file
├── outputs/
│   ├── word/
│   ├── html/
│   ├── pptx/
│   └── excel/
└── scripts/            ← generated PowerShell COM scripts saved here after each build
```

---

## Versioning and Iteration

- **If the skill misfires on non-build requests** → tighten the `description` trigger phrases.
  Add "do NOT fire on" examples to the description.
- **If organization self-checks miss real problems** → add new check items to the Organization
  or Readability checklist. Be specific: "max 3 items in a table cell", "no sentence over
  30 words in a slide", etc.
- **If a format's COM automation breaks** → save the fix to `build-doc/scripts/` and note
  the gotcha. Check the Word script history for the cursor-after-table fix as a pattern.
- **After 5+ real builds** → add eval cases to `build-doc/evals/evals.json`:
  - Known-good request → expected spec output
  - Known-ambiguous request → expected clarifying question
  - Known failure mode → expected recovery behavior
- **If the user confirms a format preference** (e.g., "always use dark mode for HTML") →
  write it to memory immediately so the next build loads it without asking.
