---
name: crud-builder
description: >
  Generates a complete CRUD frontend package from blueprint.json. For every entity in the
  schema, produces four pages: list view (table with search, filter, pagination), create/edit
  form, detail view, and delete confirmation. Also writes shared files: supabase-client.js,
  routes.js, auth-guard.js, and styles.css. All Supabase keys read from .env — never
  hardcoded. After generation, suggests the next relevant build skill based on remaining
  blueprint features. Use when app-architect selects this from the build menu, or invoke
  manually with /crud-builder when blueprint.json exists. Trigger phrases: "generate CRUD
  pages", "build the pages", "generate the app pages", "/crud-builder".
user-invocable: true
argument-hint: "project name, or path to blueprint.json"
---

# CRUD Builder

Reads blueprint.json and generates a complete, working frontend for every entity in the
schema. Outputs HTML/JS page files plus shared infrastructure files (DB client, router,
auth guard, stylesheet) into the project folder. Never hardcodes credentials. Respects
auth rules defined in the blueprint on every generated route.

---

## Guardrails

- **Never hardcode Supabase keys.** The generated `supabase-client.js` must read
  `SUPABASE_URL` and `SUPABASE_ANON_KEY` from a `.env` file (or `window.__env` for
  static hosting). Always generate a `.env.example` alongside with placeholder values.
- **Never overwrite existing generated files without asking.** If pages already exist
  for an entity in the project folder, show what exists and ask: Overwrite / Skip / Cancel.
- **Never generate pages for entities not in blueprint.json schema.** Only build what the
  blueprint explicitly defines — don't invent extra pages or entities.
- **Never skip auth-guard on a route marked `auth: true` in blueprint.json.** Every
  protected page must import and invoke `auth-guard.js` at the top of its script block.
  No exceptions — an unguarded protected route is a security hole.
- **Never proceed if blueprint.json is missing.** Hard stop with a clear message directing
  the user to run `/app-architect` first.

---

## Gotchas

- **Incomplete blueprint schema → wrong form fields.** The most common failure: if
  `blueprint.schema[entity].fields` is partial, the generated create/edit form will be
  missing fields or use wrong input types. Always validate that every entity has at least
  2 fields (beyond `id` and `created_at`) before generating its pages. If an entity is
  underspecified, flag it:
  > "Entity [X] only has auto-generated fields (id, created_at). No user-editable fields
  > found — skipping form generation. Fix blueprint.json or run /app-architect to update."

- **Supabase client misconfiguration.** If the user hasn't set their `.env` values, all
  DB calls will silently fail with CORS or 401 errors. After writing `.env.example`, always
  remind the user:
  > "Copy `.env.example` to `.env` and fill in your Supabase project URL and anon key
  > before opening the app."

- **Auth-guard on wrong pages.** Only apply `auth-guard.js` to components whose
  `blueprint.components[].roles` is non-empty AND `blueprint.routes[].auth` is `true`
  for their data routes. Public pages (roles: [], auth: false) must NOT get the guard —
  it would lock out all users.

- **Route naming collision.** If two entities have similar names (e.g., `User` and `Users`),
  their generated page file names may collide. Use kebab-case entity names and always
  check for filename conflicts before writing:
  > "Filename conflict: [entity-a]-list.html already exists from a previous entity.
  > Rename to [entity-a-2]-list.html? (yes/no)"

- **Delete without cascade.** If blueprint.schema shows a parent entity (e.g., `clients`)
  with children (e.g., `projects` with `client_id` FK), the delete confirmation page must
  warn: "Deleting this [client] will also affect [N] related [projects]." Surface this at
  generation time so the user knows to handle it.

---

## Steps

### 0 — Pre-flight

1. Locate `blueprint.json` at:
   `C:\Users\mdecker\.claude\skills\website model\projects\[project-name]\blueprint.json`
   If not found, stop:
   > "No blueprint.json found. Run /app-architect first to design the app architecture."

2. Read and validate blueprint.json. Required fields:
   `app.name`, `stack`, `schema` (at least 1 entity), `routes`, `components`
   If any are missing, stop and report exactly which fields are absent.

3. Check if any entity pages already exist in `projects/[app-name]/pages/`.
   If files exist, show the list and ask: **Overwrite all / Skip existing / Cancel**.

4. Load memory: `preferred_frontend_stack` (for any style decisions).

---

### 1 — Resolve output paths

Set the project output root:
```
C:\Users\mdecker\.claude\skills\website model\projects\[app-name]\
├── pages\         ← entity HTML files
├── js\            ← shared JS files
├── css\           ← shared stylesheet
├── .env.example   ← credential template
└── index.html     ← app entry point / nav shell
```

Create all directories before writing any files.

---

### 2 — Generate shared infrastructure files

Write these once, before any entity pages:

**js/supabase-client.js**
```javascript
// Load from .env or window.__env for static hosting
const SUPABASE_URL = window.__env?.SUPABASE_URL || '';
const SUPABASE_ANON_KEY = window.__env?.SUPABASE_ANON_KEY || '';
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
export default supabase;
```

**js/auth-guard.js**
```javascript
// Import at top of any protected page
import supabase from './supabase-client.js';
const { data: { session } } = await supabase.auth.getSession();
if (!session) window.location.href = '/pages/login.html';
```

**js/routes.js** — simple hash-based router mapping all entity page routes:
```javascript
const routes = {
  '#/[entity]':        'pages/[entity]-list.html',
  '#/[entity]/new':    'pages/[entity]-form.html',
  '#/[entity]/:id':    'pages/[entity]-detail.html',
  ...
};
```
One entry per entity page, derived from `blueprint.components[]`.

**css/styles.css** — minimal shared stylesheet:
- CSS variables for colors (derived from blueprint stack — Supabase green accents or neutral)
- Base resets, table styles, form styles, button styles, modal styles
- Responsive grid for list views

**.env.example**
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

---

### 3 — Generate entity pages (one entity at a time)

For each entity in `blueprint.schema[]`, generate four files:

#### 3a — List view (`pages/[entity]-list.html`)

Features:
- Full-width table with one column per field (excluding `id` and `created_at` by default)
- Search input (filters client-side on all text fields)
- Sort by clicking column headers
- Pagination (25 rows per page default)
- "New [Entity]" button → navigates to form page
- Each row: click → detail view, edit icon → form page (prefilled), delete icon → delete confirm
- Supabase query: `supabase.from('[entity]').select('*').order('created_at', { ascending: false })`
- If `blueprint.routes` for this entity has `auth: true` → import and invoke `auth-guard.js`

#### 3b — Create/Edit form (`pages/[entity]-form.html`)

Features:
- Shared form for both create (no `?id` param) and edit (`?id=[uuid]` in URL)
- One input per field in `blueprint.schema[entity].fields` (excluding `id`, `created_at`)
- Input types mapped from field types:
  - `text` → `<input type="text">`
  - `numeric` → `<input type="number">`
  - `date` → `<input type="date">`
  - `timestamp` → `<input type="datetime-local">`
  - `boolean` → `<input type="checkbox">`
  - `text` fields named `email` → `<input type="email">`
  - `text` fields named `notes` or `description` → `<textarea>`
- On load with `?id`: fetch record from Supabase and prefill all fields
- Submit: `upsert` (Supabase handles create vs update based on id presence)
- Cancel button → back to list view
- Required field validation before submit
- Auth guard if route is protected

#### 3c — Detail view (`pages/[entity]-detail.html`)

Features:
- Read-only display of all fields in a definition-list (`<dl>`) layout
- "Edit" button → navigates to form page with `?id`
- "Delete" button → navigates to delete confirmation page
- "Back" button → list view
- Fetches single record: `supabase.from('[entity]').select('*').eq('id', id).single()`
- Formats field values by type (dates → locale string, booleans → Yes/No)

#### 3d — Delete confirmation (`pages/[entity]-delete.html`)

Features:
- Shows the record's primary display field (first non-id text field) in the confirm message:
  > "Are you sure you want to delete [field value]? This cannot be undone."
- If this entity has child records (FK relationships in blueprint): adds cascade warning:
  > "Warning: deleting this [entity] may affect related [child-entity] records."
- "Confirm Delete" button → `supabase.from('[entity]').delete().eq('id', id)` → redirect to list
- "Cancel" button → back to detail view
- Auth guard if route is protected

---

### 4 — Generate index.html (app entry point)

A simple navigation shell listing all entity list-view links. Acts as the app home page.
Includes the Supabase CDN script tag and imports `js/routes.js`.

If auth is required (`blueprint.stack.auth !== 'none'`): add Login / Logout buttons
wired to Supabase auth methods.

---

### 5 — Write all files and confirm

Write every generated file to disk. After all writes complete, print the file manifest:

```
CRUD PAGES GENERATED — [App Name]
────────────────────────────────────────────
pages\
  [entity]-list.html          (list + search + pagination)
  [entity]-form.html          (create + edit)
  [entity]-detail.html        (read-only detail)
  [entity]-delete.html        (delete confirmation)
  ... (one set per entity)
js\
  supabase-client.js
  routes.js
  auth-guard.js
css\
  styles.css
index.html
.env.example
────────────────────────────────────────────
REMINDER: Copy .env.example → .env and fill in your Supabase credentials.
```

---

### 6 — Suggest next skill

Check `blueprint.components[]` for any component types not yet covered by crud-builder:

| Remaining feature | Suggest |
|---|---|
| `type: "form"` multi-step wizard | `/form-builder` |
| `type: "dashboard"` charts/KPIs | `/dashboard-builder` |
| Nothing remaining | `/app-deployer` |

Always append a visual polish suggestion regardless of remaining features:
> "Optional: run /frontend-design on any generated page to apply a distinctive visual theme."

Display:
> "CRUD pages done. Based on your blueprint, the next step is:
> [skill suggestion] — [one-line reason]
> Run /[skill] to continue, or /app-deployer to deploy what you have now.
> Optional polish: /frontend-design — apply a cohesive visual theme to any generated page."

---

## Embedded Skills & Callouts

- **Called by**: `app-architect` (user selects from build menu)
- **Calls**: none — suggests next skill and waits for user
- **Reads**: `blueprint.json` (written by app-architect)
- **Consumed by**: `app-deployer` (deploys the generated files)

---

## Memory Allocation

Reads: `preferred_frontend_stack` (for style decisions only — does not change code logic).

Project output structure:
```
C:\Users\mdecker\.claude\skills\website model\projects\[app-name]\
├── pages\
│   ├── [entity]-list.html
│   ├── [entity]-form.html
│   ├── [entity]-detail.html
│   └── [entity]-delete.html
├── js\
│   ├── supabase-client.js
│   ├── routes.js
│   └── auth-guard.js
├── css\
│   └── styles.css
├── index.html
└── .env.example
```

---

## Versioning & Iteration

- If generated forms frequently need extra field types → add them to the type-mapping table
  in Step 3b.
- If the list view needs more features (export, bulk delete) → add them in Step 3a.
- If auth-guard is applied incorrectly in either direction → tighten the auth-check logic
  in Steps 3a/3b/3c using `blueprint.routes[].auth` as the source of truth.
- After 3+ real builds → compare generated code against what was actually deployed to find
  fields always manually edited (make those the new defaults).
