---
name: app-interviewer
description: >
  Structured intake interview for building web applications. Runs adaptive AskUserQuestion
  rounds to collect app type, data model, user roles, and features, then writes spec.json
  and SPEC.md to disk and automatically calls app-architect. Use this skill when the user
  describes an app idea in plain English, types /app-interviewer, or when any website-model
  skill (app-architect, crud-builder, form-builder, app-deployer) needs a spec that does
  not yet exist. Trigger phrases: "build me an app", "I want to build", "create a portal",
  "make a dashboard", "I need an internal tool", "/app-interviewer".
user-invocable: true
argument-hint: "brief plain-English description of the app idea"
---

# App Interviewer

Conducts a structured, adaptive intake interview that turns a vague app idea into a
complete machine-readable spec. Outputs two files — spec.json (consumed by app-architect
and other website-model skills) and SPEC.md (human-readable summary) — then calls
app-architect automatically to begin building.

---

## Guardrails

- **Never write the spec without showing a confirmation summary first.** Always display
  the full collected spec to the user and get an explicit thumbs-up before writing any file.
- **Never skip the data model step.** A spec with no defined entities/tables is unusable.
  Always define at least one entity with at least two fields before proceeding.
- **Never overwrite an existing spec.json without permission.** If spec.json already exists
  in the project folder, show the user what's there and ask: overwrite, merge, or cancel.
- **Never assume the auth strategy.** Always ask — do not default to "no auth" or silently
  pick an auth provider. Authentication decisions have downstream security implications.
- **Never chain to app-architect if the user cancels the confirmation.** If the user rejects
  the spec summary, go back and correct — never force-write and move on.

---

## Gotchas

- **Vague idea → over-guessing.** The most common failure is the user saying "build me a
  portal" and app-interviewer filling gaps with assumptions. Use multiple-choice options
  in AskUserQuestion to surface specifics the user hasn't verbalized — never fill a gap
  silently. If the idea is truly underspecified after two rounds, stop and say exactly
  what's missing.
- **Existing spec conflict.** If spec.json exists and is from a different app concept,
  overwriting it silently will corrupt the pipeline. Always check and surface the conflict.
- **Memory pre-fill collision.** If memory has a saved preference (e.g., "Supabase") but
  the user wants something different for this project, don't lock them in. Show the
  saved preference as the default option but always offer "use something different."
- **Single-table data model.** If the user describes a multi-entity app (e.g., clients +
  projects + invoices) but only defines one table, flag it: "This sounds like it needs
  [X, Y, Z] tables — want to define those now or keep it simple?"
- **No roles defined.** Some apps have no auth but still have role distinctions (admin vs
  public). Always ask about roles even when auth is "none."

---

## Steps

### 0 — Pre-flight checks

1. Check if `spec.json` already exists in the current project folder.
   - If it does: show the existing spec summary and ask → **Overwrite / Add to it / Cancel**
   - If canceled: stop immediately, do not run the interview.
2. Load memory from `C:\Users\mdecker\.claude\projects\...\memory\` and check for saved
   preferences: `preferred_frontend_stack`, `preferred_auth_provider`, `preferred_database`,
   `preferred_deploy_target`. Store any found values — they pre-fill later questions.

---

### 1 — Collect the app idea

Ask the user (plain text, not AskUserQuestion):
> "Describe the app in one or two sentences — what it does and who uses it."

If the user passed an argument to the skill (e.g., `/app-interviewer client intake portal`),
use that as the starting description and skip directly to Step 2.

---

### 2 — App type round (AskUserQuestion)

Ask 2 questions in one AskUserQuestion call:

**Q1 — App category**
> "What kind of app is this?"
- Client intake / intake portal (forms, submissions, file uploads)
- Reporting dashboard (charts, KPI cards, filterable tables)
- Internal tool / admin panel (CRUD, search, data management)
- Scheduling app (calendars, bookings, reminders)
- Onboarding portal (multi-step flows, progress tracking)
- Custom — I'll describe it

**Q2 — Complexity**
> "How complex is the data model?"
- Simple (1–3 tables, straightforward relationships)
- Medium (4–7 tables, some joins and foreign keys)
- Complex (8+ tables, multiple roles, complex permissions)
- Not sure — help me figure it out

---

### 3 — Data model round (AskUserQuestion)

Never skip this round. Ask 2 questions:

**Q1 — Primary entities**
> "What are the main things this app stores? (Select all that apply)"
*(multi-select — adapt options to the app description)*
- Users / Clients
- Projects / Jobs
- Invoices / Payments
- Appointments / Bookings
- Products / Inventory
- Documents / Files
- Custom — I'll name them

**Q2 — Key fields**
For each entity selected, ask:
> "For [entity], what are the key fields? (Select the most important)"
*(multi-select — offer common fields for the entity type)*
- Name, Email, Phone
- Status, Created date, Updated date
- Amount, Due date
- Notes, Description
- Custom field — I'll describe it

---

### 4 — User roles round (AskUserQuestion)

Ask 2 questions:

**Q1 — Auth requirement**
> "Does this app need user login / authentication?"
*(pre-fill with memory preference if available — show as "(your default)" label)*
- Yes — Supabase Auth
- Yes — Clerk
- Yes — custom / other
- No auth needed — public app

**Q2 — User roles**
> "What roles will users have?"
- Single role (everyone has the same access)
- Admin + Regular user (admin can manage data, users can view/submit)
- Admin + Staff + Client (three-tier access)
- Custom roles — I'll define them

---

### 5 — Features round (AskUserQuestion)

Ask 2 questions:

**Q1 — Core features**
> "Which features does this app need? (Select all that apply)"
*(multi-select)*
- Create / Edit / Delete records (CRUD)
- Search and filter data
- File uploads
- Email notifications
- Export to CSV / PDF
- Charts and analytics
- Multi-step forms / wizards
- Calendar / scheduling view

**Q2 — Deploy target**
> "Where should this app be deployed?"
*(pre-fill with memory preference if available)*
- Vercel (free, instant deploy)
- Azure Static Web Apps
- Railway (backend-heavy apps)
- Not sure — recommend one

---

### 6 — Spec confirmation

Compile all answers into a structured summary and display it to the user:

```
APP SPEC — [App Name]
────────────────────────────────
Type:        [category]
Complexity:  [simple/medium/complex]

Data Model:
  [Entity 1]: [field1], [field2], ...
  [Entity 2]: [field1], [field2], ...

Auth:        [provider or none]
Roles:       [list of roles]

Features:
  ✓ [feature 1]
  ✓ [feature 2]
  ...

Deploy:      [target]
────────────────────────────────
```

Ask the user:
> "Does this look right? (Yes — write spec / No — go back and fix something)"

If **No**: ask which section to fix and re-run that round only. Do not restart the whole
interview.

---

### 7 — Write spec files

Write two files to the project folder
(`C:\Users\mdecker\.claude\skills\website model\projects\[app-name-kebab]\`):

**spec.json**
```json
{
  "name": "[app-name]",
  "type": "[category]",
  "complexity": "[simple|medium|complex]",
  "entities": [
    { "name": "[Entity]", "fields": ["field1", "field2"] }
  ],
  "auth": {
    "required": true,
    "provider": "[supabase|clerk|none]"
  },
  "roles": ["admin", "user"],
  "features": ["crud", "search", "file-uploads"],
  "deploy": "[vercel|azure|railway]"
}
```

**SPEC.md** — human-readable version of the same data, in plain markdown with a table per entity.

Confirm both files were written before continuing.

---

### 8 — Save preferences to memory

For any new preferences learned (stack, auth provider, database, deploy target), write a
memory entry to `C:\Users\mdecker\.claude\projects\c--Users-mdecker--claude-skills\memory\`
using the existing memory format. Only write if the preference differs from or adds to what
was already stored.

---

### 9 — Hand off to app-architect

After both spec files are confirmed on disk, say:
> "Spec written. Handing off to app-architect now."

Then invoke the `app-architect` skill, passing the path to spec.json as the argument.

---

## Embedded Skills & Callouts

- **app-architect** — called automatically in Step 9 after spec is written
- Called by: `app-architect`, `crud-builder`, `form-builder`, `dashboard-builder`,
  `app-deployer` — any of these can invoke app-interviewer when no spec.json is found
- **vault** — run after SKILL.md is written (per user's Phase 4 answer)

---

## Memory Allocation

Reads and writes user-level memory for:
- `preferred_frontend_stack` — HTML/JS or React
- `preferred_auth_provider` — Supabase Auth, Clerk, none
- `preferred_database` — Supabase, Firebase, PlanetScale, etc.
- `preferred_deploy_target` — Vercel, Azure, Railway

Project outputs live at:
```
C:\Users\mdecker\.claude\skills\website model\projects\[app-name]\
├── spec.json      ← machine-readable spec for app-architect
└── SPEC.md        ← human-readable spec summary
```

---

## Versioning & Iteration

- If the interview regularly misses a needed field → add it to the relevant AskUserQuestion
  round in Steps 2–5.
- If app-architect frequently asks for info not in the spec → that info belongs in Step 5
  features round or a new step.
- If users frequently answer "No — go back and fix something" on the same section → that
  section's questions are ambiguous; rewrite the options.
- After 5+ real runs → add eval cases noting what spec shapes produced good vs bad app-architect
  outputs.
