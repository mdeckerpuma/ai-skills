---
name: vault
description: >
  Bidirectional sync bridge between the VSCode skills workspace and the .claude memory system.
  Use /vault to ensure all skill outputs are saved in the correct locations, CLAUDE.md files
  are current in both the global .claude root and the skills workspace, MEMORY.md stays under
  200 lines, and the master output index is up to date. Invoke manually or embed as the final
  step inside other SKILL.md files (journal, options-coach, etc.) to auto-sync after each run.
user-invocable: true
argument-hint: "bootstrap | sync | audit"
---

# Vault

The connective tissue between Claude's memory system and the VSCode skills workspace. On first
run it audits and reports. On subsequent runs it syncs outputs, regenerates CLAUDE.md files from
memory (memory is the source of truth), updates the master output index, and trims MEMORY.md
when it approaches 200 lines.

---

## Guardrails

- **Memory is master.** CLAUDE.md files are always regenerated FROM `.claude` memory — never
  the reverse. Never overwrite memory entries from CLAUDE.md content.
- **First run = audit only.** Do not create or modify any files on the first invocation until
  the user explicitly confirms they want to proceed.
- **Never delete output files.** Only move/copy misplaced files; never remove them.
- **MEMORY.md stays under 200 lines.** When trimming, keep the most-referenced entries —
  never silently drop entries the user has not approved for removal.
- **Never modify other skills' SKILL.md files** unless the user explicitly asks vault to
  embed a sync step into them.
- **Verify before indexing.** Only add a file to `index.json` after confirming it is
  readable and non-empty.

---

## Gotchas

- **First run with nothing in place** — creates folder structure and both CLAUDE.md files
  only after the user approves the audit report.
- **index.json missing** — treat this as bootstrap mode regardless of what else exists.
- **CLAUDE.md conflict** — memory is always the source of truth; if CLAUDE.md contains
  content not in memory, surface it to the user and ask if it should be saved to memory
  before overwriting.
- **Output file in wrong location** — if a skill saved a file to the wrong path, move it
  to the correct subfolder and log the move in index.json.
- **MEMORY.md has no access-frequency data yet** — on first trim, ask the user which entries
  look least important rather than guessing.
- **VSCode .vscode/settings.json already exists** — merge new keys, never overwrite the
  entire file.

---

## File Structure

All paths relative to the skills workspace root:
`C:\Users\mdecker\.claude\skills\`

```
C:\Users\mdecker\.claude\
├── CLAUDE.md                              ← global context (regenerated from memory)
│
└── skills\
    ├── CLAUDE.md                          ← skills-specific context (regenerated from memory)
    ├── .vscode\
    │   └── settings.json                  ← workspace VSCode config (vault-managed)
    ├── outputs\
    │   └── index.json                     ← master output log (all skills)
    │
    ├── journal\
    │   ├── SKILL.md
    │   └── outputs\
    │       ├── daily\           (one .md per day: 2026-06-10.md)
    │       ├── weekly\          (weekly rollups: 2026-W23.md)
    │       ├── sessions\        (per-conversation notes)
    │       └── metrics\         (mood/metric logs: mood-log.json)
    │
    ├── options-coach\
    │   ├── SKILL.md
    │   └── outputs\
    │       ├── scenarios\       (trade scenario walkthroughs)
    │       └── notes\           (concept notes / explanations)
    │
    ├── [other-skill]\
    │   ├── SKILL.md
    │   └── outputs\
    │       └── [type]\
    │
    └── vault\
        └── SKILL.md             ← this file
```

**Memory source of truth:**
`C:\Users\mdecker\.claude\projects\c--Users-mdecker--claude-skills\memory\`
- `MEMORY.md` — index of all memory files (must stay under 200 lines)
- Individual `*.md` memory files — user, feedback, project, reference types

---

## index.json Schema

```json
{
  "version": "1.0",
  "last_sync": "2026-06-10T14:30:00Z",
  "entries": [
    {
      "id": "uuid-v4",
      "date": "2026-06-10",
      "skill": "journal",
      "type": "daily",
      "file": "skills/journal/outputs/daily/2026-06-10.md",
      "summary": "One-line description of the output",
      "size_bytes": 1234,
      "verified": true,
      "timestamp": "2026-06-10T14:30:00Z"
    }
  ]
}
```

---

## CLAUDE.md Content Template

Both the global (`C:\Users\mdecker\.claude\CLAUDE.md`) and the skills-specific
(`C:\Users\mdecker\.claude\skills\CLAUDE.md`) should contain:

```markdown
# Context: Matthew Decker

## Who I Am
[User profile: role, trading focus, goals — regenerated from user memory files]

## Active Skills & Output Paths
[Map of each skill name → its outputs/ subfolder — regenerated from skill structure]

## Standing Rules
[Extracted from feedback memory files — preferences, constraints, behavior rules]
```

The skills CLAUDE.md may contain additional skills-workspace-specific rules not in the global one.

---

## .vscode/settings.json Template

```json
{
  "claudeCode.preferredLocation": "panel",
  "files.exclude": {
    "**/.git": true,
    "**/node_modules": true
  },
  "files.associations": {
    "*.md": "markdown",
    "SKILL.md": "markdown",
    "CLAUDE.md": "markdown",
    "MEMORY.md": "markdown"
  },
  "editor.wordWrap": "on",
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.patterns": {
    "SKILL.md": "outputs"
  }
}
```

Merge with any existing `.vscode/settings.json` — never overwrite entirely.

---

## Steps

### Mode Detection

Before any action, determine which mode to run:

- If `skills/outputs/index.json` **does not exist** → **Bootstrap Mode**
- Otherwise → **Sync Mode**
- If the user passed `audit` as an argument → **Audit Mode** (report only, no writes)

---

### Bootstrap Mode

Run this only on the very first invocation when `index.json` is absent.

1. **Audit the current state.** Scan and report:
   - Which skill folders exist under `skills/`
   - Which have an `outputs/` subfolder vs. which don't
   - Whether `CLAUDE.md` exists at `C:\Users\mdecker\.claude\CLAUDE.md`
   - Whether `CLAUDE.md` exists at `skills\CLAUDE.md`
   - Whether `.vscode\settings.json` exists inside `skills\`
   - Current line count of `MEMORY.md`
   - Any output files found outside their expected folders (misplaced)

2. **Present the report.** Show a clear summary table:
   ```
   AUDIT REPORT — /vault bootstrap
   ─────────────────────────────────────────
   ✓ / ✗  Global CLAUDE.md at .claude root
   ✓ / ✗  Skills CLAUDE.md at skills root
   ✓ / ✗  .vscode/settings.json in skills/
   ✓ / ✗  outputs/index.json exists
   ✓ / ✗  journal/outputs/ subfolders (daily, weekly, sessions, metrics)
   ✓ / ✗  options-coach/outputs/ subfolders (scenarios, notes)
   ─────────────────────────────────────────
   MEMORY.md: [N] lines (limit: 200)
   Misplaced files: [list or "none"]
   ```

3. **Ask for confirmation.** Say: "Ready to create the missing structure? I'll create
   folders, CLAUDE.md files, index.json, and .vscode/settings.json. No existing files
   will be deleted or overwritten." Wait for yes/no.

4. **If confirmed, create everything:**
   - All missing `outputs/` subfolders for journal and options-coach
   - `outputs/index.json` (empty entries array, current timestamp)
   - `skills/.vscode/settings.json` using the template above (merge if exists)
   - `skills/CLAUDE.md` generated from current memory files
   - `C:\Users\mdecker\.claude\CLAUDE.md` generated from current memory files
   - Any other `[skill]/outputs/` folders for remaining installed skills

5. **Confirm completion.** List every file created/modified with its full path.

---

### Sync Mode

Run this on all subsequent invocations (when `index.json` already exists).

1. **Scan for new outputs.** Check each `skills/*/outputs/**` for files added since
   `last_sync` timestamp in `index.json`.

2. **Verify each new file.**
   - Confirm file exists and is readable
   - Confirm file is non-empty (size > 0 bytes)
   - Confirm it is in the correct subfolder for its type (e.g., daily journal entry
     belongs in `journal/outputs/daily/`, not the root `outputs/`)

3. **Move misplaced files.** If a file is in the wrong location, move it to the correct
   subfolder and note the move.

4. **Update index.json.** Append one entry per new verified file. Set `verified: true`.
   Update `last_sync` to current timestamp.

5. **Regenerate CLAUDE.md files.** Read all memory files from
   `C:\Users\mdecker\.claude\projects\c--Users-mdecker--claude-skills\memory\`.
   Regenerate both CLAUDE.md files using the template above. Memory is always master.
   If CLAUDE.md contains content not found in any memory file, surface it:
   > "Found content in CLAUDE.md not in memory: [excerpt]. Save to memory before
   > overwriting? (yes/no)"

6. **Check MEMORY.md line count.**
   - If under 180 lines: no action.
   - If 180–199 lines: warn the user: "MEMORY.md is at [N] lines (limit: 200).
     Consider trimming soon."
   - If 200+ lines: identify the least-referenced entries (ones not cited in CLAUDE.md
     and not from a recent session). Present them to the user:
     > "MEMORY.md is over 200 lines. These entries appear least-referenced: [list].
     > Remove them? (yes/no/select)"
     Wait for explicit approval before deleting any entry.

7. **Report sync results.** Print a compact summary:
   ```
   VAULT SYNC — 2026-06-10 14:30
   ──────────────────────────────
   New outputs indexed: [N]
   Misplaced files moved: [N]
   CLAUDE.md regenerated: global + skills
   MEMORY.md: [N] lines
   index.json last_sync updated
   ```

---

### Audit Mode (`/vault audit`)

Read-only scan. Same as Bootstrap step 1-2, but works at any time. Reports current state
without making any changes. Useful for a quick health check before a big session.

---

## Embedding in Other Skills

To embed vault sync at the end of another skill, add this as the final step in that
skill's SKILL.md:

```markdown
### Final Step — Vault Sync

After saving the output file, invoke `/vault` to:
- Verify the file was saved correctly
- Add it to `outputs/index.json`
- Confirm CLAUDE.md is current

The vault skill handles this automatically. No user action needed unless a conflict
or verification failure is reported.
```

Add this section to: `journal/SKILL.md` and `options-coach/SKILL.md` after the user
reviews and approves this spec.

---

## Memory Allocation

Key paths this skill reads and writes:

| Path | Purpose |
|------|---------|
| `C:\Users\mdecker\.claude\CLAUDE.md` | Global context file (vault-managed) |
| `C:\Users\mdecker\.claude\skills\CLAUDE.md` | Skills context file (vault-managed) |
| `C:\Users\mdecker\.claude\skills\outputs\index.json` | Master output log |
| `C:\Users\mdecker\.claude\skills\.vscode\settings.json` | VSCode workspace config |
| `C:\Users\mdecker\.claude\projects\c--Users-mdecker--claude-skills\memory\` | Memory source of truth |
| `C:\Users\mdecker\.claude\projects\c--Users-mdecker--claude-skills\memory\MEMORY.md` | Memory index (200-line limit) |
| `C:\Users\mdecker\.claude\skills\journal\outputs\` | Journal output root |
| `C:\Users\mdecker\.claude\skills\options-coach\outputs\` | Options-coach output root |
