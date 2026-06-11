---
name: app-iterator
description: >
  Evolves an existing generated app by applying change requests. Accepts any type of change
  — schema (add/remove/rename fields and entities), features (add dashboard, wizard form),
  routes, roles, or stack config. Shows a blueprint.json diff for user confirmation before
  writing. Produces an impact list of affected files, lets the user choose what to
  regenerate, then calls the relevant build skills (crud-builder, dashboard-builder,
  form-builder) to regenerate those files. Appends to CHANGELOG.md and updates memory.
  Never auto-deploys — always hands off to /app-deployer. Trigger phrases: "update the app",
  "add a field to", "add a new entity", "change the schema", "iterate on the app",
  "/app-iterator".
user-invocable: true
argument-hint: "project name + change description (e.g., 'my-app add a notes field to clients')"
---

# App Iterator

The post-deploy evolution skill. Takes a natural-language change request, translates it into
blueprint.json modifications, shows the user exactly what will change, produces an impact
list of affected files, lets the user choose what to regenerate, and calls the relevant
build skills to do so. Handles any blueprint change type: schema, features, routes, roles,
or stack. Tracks all iterations in CHANGELOG.md and memory. Never touches blueprint.json
without confirmation. Never auto-deploys.

---

## Guardrails

- **Never modify blueprint.json without showing the diff first.** Always compute the full
  diff between the current blueprint and the proposed new version, display it clearly, and
  wait for explicit user confirmation (`yes` / `no`) before writing. No exceptions.
- **Never auto-deploy after regeneration.** After all regen steps complete, always stop and
  print:
  > "Regeneration complete. Run /app-deployer to push these changes to Vercel."
  Never call app-deployer automatically.
- **Never start writing if the change request is ambiguous.** If the request could mean
  multiple things (e.g., "add a status field" — text? boolean? enum?), resolve the ambiguity
  first by asking a clarifying question before proposing any blueprint changes.
- **Never proceed if blueprint.json doesn't exist.** Hard stop:
  > "No blueprint.json found for this project. Run /app-architect first to create one."
- **Never delete project files.** Regeneration replaces file content — it never removes
  HTML/JS files from disk. If a field is removed from an entity, regenerate that entity's
  pages with the field gone, but do not delete the page file itself.

---

## Gotchas

- **Ambiguous change request.** The most likely source of bad output. "Add a status field"
  could be `text`, `boolean`, `enum (active/inactive/pending)`, or a FK reference. Before
  proposing a blueprint change, resolve every ambiguous element:
  > "For the 'status' field on [entity]: should this be a text input, a checkbox (boolean),
  > or a dropdown with specific values? If dropdown, what values?"
  One clarifying question per ambiguous element — don't batch them into a wall.

- **Blueprint updated but downstream regen fails.** If the user confirms the blueprint diff
  but a downstream skill (crud-builder, etc.) fails mid-run, blueprint.json and project
  pages will be out of sync. Per the recovery rule: stop immediately and do NOT write the
  blueprint. Show the user what would have changed and tell them to fix the blocker before
  retrying.

- **Removing a field that has live data in Supabase.** Removing a field from blueprint.json
  and regenerating pages removes the field from the UI — but the Supabase column still
  exists with data. Always warn when removing a field:
  > "Removing '[field]' from blueprint will remove it from all generated pages. The column
  > still exists in your Supabase table — delete it manually via Supabase Table Editor if
  > you want to remove the data too."

- **User manually edited a generated file.** If the user customized a generated page, regen
  will overwrite those changes. Before regenerating any file, check if it has been modified
  since last generation (compare against CHANGELOG.md timestamp). If modified, warn:
  > "[entity]-list.html was modified after last generation. Regenerating will overwrite your
  > changes. Continue? (yes/no)"

- **Adding a new entity mid-project.** A new entity requires not just its CRUD pages but
  also updates to `index.html` nav, `routes.js`, and potentially `dashboard.html` if a
  dashboard exists. The impact list must include these shared files, not just the new
  entity's pages.

---

## Steps

### 0 — Pre-flight

1. Identify the project. Accept project name from argument, or list available projects and
   ask the user to pick one.

2. Read `blueprint.json`. Validate it is well-formed with `app.name`, `schema[]`,
   `routes[]`, `components[]`. If missing or malformed, stop.

3. Read `CHANGELOG.md` from the project folder (if it exists) to understand iteration
   history. Note the last iteration date — used for modified-file detection in Gotchas.

4. Load memory: `iteration_[app-name-kebab]` — last iteration summary.

---

### 1 — Parse and clarify the change request

Parse the user's change request into one or more structured change operations:

| Change request pattern | Operation type |
|------------------------|---------------|
| "add [field] to [entity]" | `schema.add-field` |
| "remove [field] from [entity]" | `schema.remove-field` |
| "rename [field] to [newname] on [entity]" | `schema.rename-field` |
| "add [entity] entity" | `schema.add-entity` |
| "remove [entity] entity" | `schema.remove-entity` |
| "add [feature]" (dashboard, wizard form) | `feature.add` |
| "add [role] role" | `roles.add` |
| "change deploy target to [target]" | `stack.update` |
| "add [route]" | `routes.add` |

For each parsed operation, check for ambiguity (see Gotchas). Ask one clarifying question
per ambiguous element and wait for the answer before proceeding.

Once all ambiguities are resolved, summarize the parsed operations:
```
CHANGE REQUEST PARSED — [App Name]
──────────────────────────────────
Operations:
  1. schema.add-field: clients.notes (textarea, optional)
  2. schema.add-field: clients.status (text, enum: active|inactive|pending)

Ready to show blueprint diff? (yes/no)
```

---

### 2 — Generate blueprint diff

Apply the parsed operations to an in-memory copy of blueprint.json. Do NOT write to disk
yet. Generate a human-readable diff:

```
BLUEPRINT DIFF
──────────────────────────────────
schema.clients.fields:
  + { "name": "notes", "type": "text" }
  + { "name": "status", "type": "text", "note": "enum: active|inactive|pending" }

No other changes.
──────────────────────────────────
Apply this change to blueprint.json? (yes/no)
```

If the user says no, stop — do not modify any file.
If the user says yes, write the updated blueprint.json to disk.

---

### 3 — Build impact list

After blueprint is written, analyze which project files are affected by the changes. Map
each operation type to its impact:

| Operation | Affected files |
|-----------|---------------|
| `schema.add-field` on entity X | `[x]-list.html`, `[x]-form.html`, `[x]-detail.html`, `[x]-delete.html` |
| `schema.remove-field` on entity X | Same 4 CRUD pages |
| `schema.rename-field` on entity X | Same 4 CRUD pages |
| `schema.add-entity` X | All 4 new CRUD pages + `index.html` + `routes.js` + `dashboard.html` (if exists) |
| `schema.remove-entity` X | Warn user (page files not deleted — only flagged) |
| `feature.add` dashboard | `dashboard.html` + `charts-config.json` |
| `feature.add` wizard form | `[entity]-wizard.html` + `[entity]-wizard-config.json` + `[entity]-confirm.html` |
| `roles.add` | `auth-guard.js` + `rls-policies.sql` |
| `stack.update` | `vercel.json` (if deploy target changed) |

Display the impact list and let the user choose what to regenerate:

```
IMPACT LIST — [App Name]
──────────────────────────────────
Files affected by this change:
  [✓] pages/clients-list.html
  [✓] pages/clients-form.html
  [✓] pages/clients-detail.html
  [✓] pages/clients-delete.html

Select which files to regenerate:
  1. All of the above (recommended)
  2. Select individually
  3. Skip regeneration — I'll handle it manually
```

If the user selects "individually", list each file with a yes/no prompt.

---

### 4 — Regenerate selected files

For each selected file, call the relevant skill:

| Files | Skill to call |
|-------|--------------|
| `[entity]-*.html` (CRUD pages) | `/crud-builder` with entity name argument |
| `dashboard.html` | `/dashboard-builder` |
| `[entity]-wizard.html` | `/form-builder` |
| `auth-guard.js`, `rls-policies.sql` | `/auth-integrator` |
| `index.html`, `routes.js` | Regenerate inline (simple nav/route updates) |

Before calling each skill, announce it:
> "Calling /crud-builder to regenerate clients pages..."

If any skill call fails — stop immediately. Do not call subsequent skills. Report:
> "Regeneration stopped: /crud-builder failed. Blueprint.json has been updated but
> [list of files] have NOT been regenerated. Fix the issue and re-run /app-iterator
> or call /crud-builder directly."

---

### 5 — Update CHANGELOG.md and memory

Append to `projects\[app-name]\CHANGELOG.md`:

```markdown
## Iteration [N] — [timestamp]

**Change request:** [original user request]

**Blueprint changes:**
[paste the diff from Step 2]

**Files regenerated:**
[list of files regenerated]

**Next step:** Run /app-deployer to deploy these changes.
```

If CHANGELOG.md doesn't exist, create it with a header:
```markdown
# Changelog — [App Name]

Generated by app-iterator. Each entry documents one iteration of changes.
```

Write to memory:
- `iteration_[app-name-kebab]`: iteration summary
  ```
  App: [App Name]
  Iteration: [N]
  Last change: [summary of operations]
  Files regenerated: [N]
  Blueprint version: [timestamp]
  Awaiting deploy: yes
  ```

---

### 6 — Confirm and handoff

Print final confirmation:

```
ITERATION [N] COMPLETE — [App Name]
──────────────────────────────────────────────
Blueprint updated: blueprint.json ✓
Files regenerated: [N]
  [list of regenerated files]

CHANGELOG.md updated (Iteration [N])
──────────────────────────────────────────────
NEXT: Run /app-deployer to push these changes to Vercel.
```

---

## Embedded Skills & Callouts

- **Called by**: user manually (`/app-iterator`), or suggested by `app-deployer` after first deploy
- **Calls**: `/crud-builder`, `/dashboard-builder`, `/form-builder`, `/auth-integrator`
  (whichever skills are needed for the selected regen set)
- **Reads**: `blueprint.json`, `CHANGELOG.md`, all existing project files (for modified-file detection)
- **Writes**: `blueprint.json` (updated), `CHANGELOG.md` (appended), all regenerated page files
- **Memory reads**: `iteration_[app-name]` — last iteration summary
- **Memory writes**: `iteration_[app-name]` — updated iteration record

---

## Memory Allocation

Reads:
- `iteration_[app-name-kebab]` — last iteration context (iteration count, last change, deploy status)

Writes after completion:
- `iteration_[app-name-kebab]` — updated with new iteration number, change summary, files regenerated

Project files written/updated:
```
C:\Users\mdecker\.claude\skills\website model\projects\[app-name]\
├── blueprint.json          ← updated with change operations
├── CHANGELOG.md            ← appended with new iteration entry
└── pages\                  ← regenerated files (varies by change)
    js\                     ← regenerated shared files (varies by change)
```

---

## Versioning & Iteration

- If schema migrations are needed (altering live Supabase tables) → add a Step 3b that
  generates an `ALTER TABLE` SQL snippet alongside the impact list, so the user knows
  what to run in Supabase before deploying.
- If the ambiguity-check in Step 1 is too aggressive (asks too many questions for obvious
  changes) → add a "simple change" fast path that skips clarification for unambiguous
  single-field additions.
- If modified-file detection produces false positives → add a `generated-at` comment header
  to each generated file and compare that timestamp against the blueprint's last-written
  timestamp instead of CHANGELOG.md.
- After 5+ real iterations → review CHANGELOG.md patterns. If the same change type appears
  repeatedly (e.g., always adding a `notes` field), consider making it a blueprint default
  for new entities.
