---
name: app-architect
description: >
  Technical blueprint designer for the website-model app generation pipeline. Takes
  spec.json produced by app-interviewer and outputs a complete blueprint.json covering
  database schema, API routes, frontend components, and locked tech stack decisions.
  Pure design skill — never writes code. Use when app-interviewer completes and calls
  this skill automatically, or invoke manually with /app-architect when a spec.json
  exists but no blueprint.json has been produced yet. Trigger phrases: "design the
  architecture", "create the blueprint", "architect the app", "/app-architect".
user-invocable: true
argument-hint: "path to spec.json, or project name"
---

# App Architect

Transforms a validated spec.json into a complete technical blueprint that every downstream
build skill (crud-builder, form-builder, dashboard-builder, app-deployer) can consume
without ambiguity. Covers schema, routes, components, and stack — nothing more. Never
writes application code.

---

## Guardrails

- **Never write code.** blueprint.json is a design artifact. No SQL, no JavaScript, no
  HTML. If a downstream skill needs generated code, that is its job, not this skill's.
- **Never contradict spec.json.** If spec.json specifies Clerk for auth, blueprint.json
  must also specify Clerk. Stack decisions in spec.json are locked — architect only resolves
  fields that spec left blank by reading memory preferences.
- **Never overwrite an existing blueprint.json without permission.** If a blueprint already
  exists in the project folder, surface it and ask: Overwrite / Merge / Cancel.
- **Never skip the schema step.** Every app needs at least one defined table with at least
  two fields. A schemaless blueprint is invalid — crud-builder and form-builder cannot
  function without it.
- **Never silently fill missing spec fields.** If spec.json is missing a required field,
  stop immediately and report exactly what is missing. Suggest re-running app-interviewer.

---

## Gotchas

- **Schema mismatch.** The most common failure: the blueprint schema doesn't match the app's
  actual needs. Always derive tables directly from `spec.entities[]` — don't invent tables
  not mentioned in the spec, and don't drop entities the spec listed. If a relationship
  is implied (e.g., "projects belong to clients") but not explicit, surface it:
  "The spec implies a clients→projects relationship — adding a `client_id` FK to projects.
  Correct?"
- **Missing spec fields.** If spec.json lacks required fields (entities, auth, features),
  stop and report. Do not guess. Example message:
  > "spec.json is missing `entities`. Cannot design a schema without them. Please re-run
  > app-interviewer to fill this gap."
- **Auth routes defaulting to public.** When defining API routes, always check each route
  against `spec.auth.required` and `spec.roles`. If auth is required but a route isn't
  assigned a role, flag it rather than defaulting to public.
- **Component list missing features.** Cross-check every item in `spec.features[]` against
  the component list. If a feature (e.g., "file uploads") has no component that handles it,
  add one or flag the gap.
- **Stack conflict between spec and memory.** If memory says "React" but spec.json says
  "html-js", spec.json wins. Always prefer explicit spec values over implicit memory defaults.

---

## Steps

### 0 — Pre-flight

1. Locate `spec.json` in the project folder:
   `C:\Users\mdecker\.claude\skills\website model\projects\[project-name]\spec.json`
   If not found, stop:
   > "No spec.json found for this project. Run /app-interviewer first."

2. Check if `blueprint.json` already exists in the same folder.
   If it does, show a one-line summary and ask: **Overwrite / Merge / Cancel**.
   If canceled, stop immediately.

3. Load memory preferences:
   - `preferred_frontend_stack`
   - `preferred_auth_provider`
   - `preferred_database`
   - `preferred_deploy_target`

4. Read spec.json fully. Validate that these fields exist:
   `name`, `type`, `entities` (at least 1), `auth`, `roles`, `features`, `deploy`
   If any are missing, stop and report exactly which fields are absent.

---

### 1 — Resolve tech stack

Build the `stack` block for blueprint.json using this priority order:
1. Explicit value in spec.json (highest priority — never override)
2. Memory preference
3. Sensible default (Supabase Postgres, Vercel, HTML/JS)

```json
"stack": {
  "frontend": "html-js",
  "auth": "supabase",
  "database": "supabase-postgres",
  "deploy": "vercel"
}
```

---

### 2 — Design the database schema

For each entity in `spec.entities[]`:
- Create one table entry
- Add standard fields automatically: `id` (uuid, PK), `created_at` (timestamp)
- Map the entity's listed fields to typed columns:
  - Name/email/phone/text → `text`
  - Amount/price → `numeric`
  - Date → `date` or `timestamp`
  - Boolean flags → `boolean`
  - Status → `text` with a note suggesting an enum
- Add foreign key fields for any implied relationships (e.g., `project.client_id → clients.id`)
- If a relationship is implied but not stated, surface it to the user before adding:
  > "Adding [FK] to [table] — is this correct?"

If auth is required, always include a `users` table (or confirm one exists) with at minimum:
`id`, `email`, `role`, `created_at`.

---

### 3 — Define API routes

For each entity and each feature in spec.json, define the required routes:

| Pattern | When to include |
|---------|----------------|
| `GET /api/[entity]` | Always (list) |
| `POST /api/[entity]` | If CRUD or form feature |
| `GET /api/[entity]/:id` | If detail view needed |
| `PUT /api/[entity]/:id` | If CRUD feature |
| `DELETE /api/[entity]/:id` | If CRUD feature |
| `POST /api/upload` | If file-uploads feature |
| `GET /api/export` | If export feature |
| `GET /api/analytics` | If charts/analytics feature |

For every route, set:
- `auth`: true/false (from spec.auth.required)
- `roles`: which roles can access (from spec.roles)
- `description`: one-line plain English description of what it does

Flag any route that handles sensitive data (user records, payments) as `sensitive: true`.

---

### 4 — List frontend components

For each page/view the app needs, define one component entry:

```json
{
  "name": "ClientList",
  "route": "/clients",
  "type": "list",
  "data": ["clients"],
  "roles": ["admin", "staff"],
  "features": ["search", "filter", "crud"]
}
```

Component types: `list`, `detail`, `form`, `dashboard`, `auth`, `landing`

Derive components from:
- One list + one form per entity (if CRUD feature)
- One dashboard component (if charts/analytics feature)
- One multi-step form (if multi-step forms feature)
- One upload component (if file-uploads feature)
- Auth pages (login, signup) if auth is required

Cross-check: every item in `spec.features[]` must map to at least one component.
Flag any feature with no component.

---

### 5 — Write blueprint.json

Write to:
`C:\Users\mdecker\.claude\skills\website model\projects\[project-name]\blueprint.json`

Full structure:

```json
{
  "version": "1.0",
  "app": {
    "name": "[app-name]",
    "type": "[category]",
    "complexity": "[simple|medium|complex]"
  },
  "stack": {
    "frontend": "html-js",
    "auth": "supabase",
    "database": "supabase-postgres",
    "deploy": "vercel"
  },
  "schema": [
    {
      "table": "[entity]",
      "fields": [
        { "name": "id", "type": "uuid", "primaryKey": true },
        { "name": "[field]", "type": "[text|numeric|date|boolean|timestamp]" }
      ],
      "foreignKeys": [
        { "field": "[fk_field]", "references": "[other_table].id" }
      ]
    }
  ],
  "routes": [
    {
      "path": "/api/[entity]",
      "method": "GET",
      "auth": true,
      "roles": ["admin"],
      "sensitive": false,
      "description": "[what it does]"
    }
  ],
  "components": [
    {
      "name": "[ComponentName]",
      "route": "/[path]",
      "type": "[list|detail|form|dashboard|auth|landing]",
      "data": ["[entity]"],
      "roles": ["admin"],
      "features": ["search", "crud"]
    }
  ]
}
```

Confirm the file was written before continuing.

---

### 6 — Show build menu

After blueprint.json is confirmed on disk, display:

```
BLUEPRINT READY — [App Name]
────────────────────────────────────
Schema:     [N] tables
Routes:     [N] endpoints
Components: [N] pages
Stack:      [frontend] + [auth] + [database] → [deploy]
────────────────────────────────────
What would you like to build next?

  1. /crud-builder   — generate CRUD pages for all entities
  2. /form-builder   — build intake forms and multi-step wizards
  3. /dashboard-builder — build charts and KPI dashboard
  4. /app-deployer   — deploy the app to [deploy target]
```

Highlight the most relevant option based on app type:
- Internal tool / admin panel → suggest crud-builder first
- Intake portal → suggest form-builder first
- Reporting dashboard → suggest dashboard-builder first

Wait for the user to choose — do not auto-chain.

---

## Embedded Skills & Callouts

- **Called by**: `app-interviewer` (automatically after spec is written)
- **Calls**: none — presents a build menu and waits for user selection
- **Consumed by**: `crud-builder`, `form-builder`, `dashboard-builder`, `app-deployer`
  (all read blueprint.json as their input)

---

## Memory Allocation

Reads user-level memory for stack preferences (read-only — never writes to memory):
- `preferred_frontend_stack`
- `preferred_auth_provider`
- `preferred_database`
- `preferred_deploy_target`

Project files:
```
C:\Users\mdecker\.claude\skills\website model\projects\[app-name]\
├── spec.json        ← input (written by app-interviewer)
└── blueprint.json   ← output (written by this skill)
```

---

## Versioning & Iteration

- If crud-builder frequently asks for info not in blueprint.json → add that field to Step 5
  schema or component structure.
- If the build menu suggestions are wrong for a given app type → update the Step 6 priority
  logic for that type.
- If schema mismatch errors are common → add a Step 2 validation pass that explicitly asks
  "Did I capture all the relationships correctly?" before writing.
- After 5+ real runs → compare blueprint.json outputs against the apps actually built to
  identify fields that were always overridden (they should become defaults or be removed).
