---
name: dashboard-builder
description: >
  Reads blueprint.json and generates a charts and KPI dashboard page for a generated app.
  Analyzes the schema to automatically derive meaningful metrics (numeric fields → KPI sum
  cards, date fields → trend line charts, text fields → count-by-value bar charts). Produces
  dashboard.html (KPI cards + charts + summary tables) and charts-config.json (editable chart
  config). Chart library chosen by user on first run and saved to memory. Can be invoked
  manually or selected from the app-architect build menu. Trigger phrases: "build the
  dashboard", "add charts", "generate dashboard", "add analytics", "/dashboard-builder".
user-invocable: true
argument-hint: "project name, or path to blueprint.json"
---

# Dashboard Builder

Reads blueprint.json schema and generates a live data dashboard for the app. Automatically
derives meaningful KPIs and chart types from field types — no manual config needed. Outputs
`dashboard.html` (KPI cards + visualizations + summary tables) and `charts-config.json`
(editable chart definitions). Chart library chosen at first run and remembered. Never
invents metrics, never hardcodes data, never overwrites silently.

---

## Guardrails

- **Never invent metrics not derivable from blueprint.json schema.** Only generate KPI
  cards and charts for fields and entities explicitly defined in the blueprint. If a schema
  has no numeric fields, there are no sum KPIs — do not fabricate them.
- **Never hardcode Supabase query results into dashboard.html.** All metric values, chart
  data, and table rows must come from live Supabase queries executed at page load. No
  static sample data, placeholder numbers, or `const data = [100, 200, 300]` arrays.
- **Never overwrite an existing dashboard.html without asking.** If the file already exists
  in the project folder, show a one-line diff summary and ask: **Overwrite / Keep / Cancel**.
  Same for charts-config.json.
- **Never proceed if blueprint.json is missing or has no schema.** Without a schema there
  is nothing to analyze. Hard stop:
  > "No blueprint.json found. Run /app-architect first."
  If blueprint.json exists but `schema[]` is empty, stop:
  > "Blueprint schema is empty — no entities to build a dashboard for."
- **Never apply auth-guard to the dashboard unless blueprint specifies it.** Check
  `blueprint.components[]` for a dashboard-type component — use its `roles` and `auth`
  flags. Do not guess.

---

## Gotchas

- **Empty database makes all KPIs show zero.** The most common first-run experience: the
  user generates the dashboard before entering any data, and every card reads "0". This is
  correct behavior but looks broken. Always add a comment in the generated page and a
  reminder at the end of the run:
  > "Dashboard is live. KPI values will show 0 until you add data via the CRUD pages."

- **No chartable fields in schema.** If all entity fields are `text` type (e.g., name,
  description, notes), there are no numeric sums or date trends to chart. Flag this:
  > "Entity [X] has no numeric or date fields. Generating count-by-value charts only.
  > Add numeric fields to blueprint.json for richer KPIs."

- **charts-config.json edited incorrectly.** Users may edit the config and introduce
  typos that crash chart rendering. The generated dashboard.html should wrap chart
  initialization in a try/catch and display a clear inline error:
  `"Chart config error: [message]. Edit charts-config.json to fix."`

- **Chart library CDN unavailable.** If the chosen library fails to load from CDN, all
  charts silently disappear. Always add a CDN failure handler:
  ```javascript
  if (typeof Chart === 'undefined') {
    document.getElementById('charts').innerHTML =
      '<p class="error">Chart library failed to load. Check your internet connection.</p>';
  }
  ```

- **Multiple entities with similar field names.** If two entities both have a `status`
  field, count-by-value charts for each will look identical. Prefix chart titles with
  the entity name to distinguish: "Projects by Status" vs. "Clients by Status".

---

## Steps

### 0 — Pre-flight

1. Identify the project. Accept explicit project name argument, or default to the most
   recently modified folder in `website model\projects\`.

2. Read and validate `blueprint.json`. Required: `app.name`, `schema[]` (at least 1 entity
   with at least 1 non-auto field beyond `id` and `created_at`). If missing, stop.

3. Check if `dashboard.html` or `charts-config.json` already exist in the project root.
   If either exists, show a summary and ask: **Overwrite / Keep / Cancel**.

4. Check memory for `preferred_chart_library`. If not set, ask the user now:
   > "Which chart library should I use for this and future dashboards?"
   Present two options:
   - Chart.js (CDN) — lightweight, widely supported
   - ApexCharts (CDN) — richer defaults, built-in animations
   Save the answer to memory as `preferred_chart_library` before proceeding.

---

### 1 — Analyze blueprint schema

Walk `blueprint.schema[]`. For each entity and each field, classify:

| Field type | Metric derived |
|------------|---------------|
| `numeric` | Sum KPI card (`SUM([field])`) + optional average |
| `date` or `timestamp` | Trend line chart (records over time, grouped by week or month) |
| `text` (non-name fields) | Count-by-value bar chart (`GROUP BY [field]`) |
| `boolean` | True/False donut or pie chart |
| `id`, `created_at` | Skip — auto-generated, not user data |
| Text fields named `name`, `title`, `email` | Skip for charts — use in summary tables only |

Build a derived metrics list:
```
[entity] → [metric type] → [field] → [chart type]
e.g.: projects → sum → budget → KPI card
      projects → trend → created_at → line chart
      projects → count-by-value → status → bar chart
```

If no chartable fields are found for an entity, flag it (see Gotchas) but continue with
other entities — do not stop the run for a single unchartable entity.

---

### 2 — Build charts-config.json

Write `projects\[app-name]\charts-config.json`:

```json
{
  "library": "[chart.js|apexcharts]",
  "charts": [
    {
      "id": "[entity]-[field]-chart",
      "entity": "[entity]",
      "field": "[field]",
      "type": "[bar|line|pie|doughnut]",
      "title": "[Entity] by [Field]",
      "query": "SELECT [field], COUNT(*) FROM [entity] GROUP BY [field]",
      "color": "[hex color]"
    }
  ],
  "kpis": [
    {
      "id": "[entity]-[field]-kpi",
      "entity": "[entity]",
      "field": "[field]",
      "label": "Total [Field]",
      "aggregation": "SUM",
      "query": "SELECT SUM([field]) FROM [entity]",
      "format": "number"
    }
  ]
}
```

Assign distinct colors from a palette (avoid repeating colors across charts). Use the
blueprint's color scheme if available, otherwise use a neutral 8-color palette.

---

### 3 — Generate dashboard.html

Write `projects\[app-name]\dashboard.html` with three sections:

#### Section A — KPI Cards (top row)

One card per numeric field across all entities:
```html
<div class="kpi-card">
  <div class="kpi-label">Total [Field Label]</div>
  <div class="kpi-value" id="[entity]-[field]-kpi">—</div>
</div>
```

JS fetches each KPI via Supabase aggregate query on page load:
```javascript
const { data } = await supabase.rpc('sum_[entity]_[field]')
  || await supabase.from('[entity]').select('[field].sum()');
document.getElementById('[entity]-[field]-kpi').textContent = data ?? '—';
```

Show `—` (em dash) while loading and if query returns null — never show `0` until the
query actually returns `0` (prevents "broken" appearance on load).

#### Section B — Charts (middle section)

One chart per entry in `charts-config.json`. Use the selected chart library (Chart.js or
ApexCharts). Charts render into `<canvas>` (Chart.js) or `<div>` (ApexCharts) elements.

Load chart config from `charts-config.json` at runtime (fetch via relative URL), then
initialize each chart from the config. Wrap in try/catch for error handling (see Gotchas).

#### Section C — Summary Tables (bottom section)

One paginated table per entity (25 rows, most recently created first):
- Columns: all non-id, non-auto fields from blueprint schema
- "View all [entity]" link → navigates to `[entity]-list.html`
- Fetches: `supabase.from('[entity]').select('*').order('created_at', { ascending: false }).limit(25)`

Apply auth-guard if the corresponding blueprint component has `auth: true`.

#### Page shell

```html
<!DOCTYPE html>
<html>
<head>
  <title>[App Name] Dashboard</title>
  <link rel="stylesheet" href="css/styles.css">
  <script src="[chart-library-cdn]"></script>
</head>
<body>
  <nav><!-- shared nav with links to entity list pages --></nav>
  <main>
    <h1>[App Name] Dashboard</h1>
    <section class="kpi-row"><!-- KPI cards --></section>
    <section class="charts-grid"><!-- charts --></section>
    <section class="summary-tables"><!-- summary tables --></section>
  </main>
  <script type="module">
    import supabase from './js/supabase-client.js';
    // auth guard if required
    // KPI fetch functions
    // chart init from charts-config.json
    // table fetch functions
  </script>
</body>
</html>
```

---

### 4 — Add dashboard link to index.html

Update `projects\[app-name]\index.html` to add a "Dashboard" navigation link if not
already present. Update `js\routes.js` to add:
```javascript
'#/dashboard': 'dashboard.html',
```

---

### 5 — Write memory and confirm

Write to memory:
- `preferred_chart_library` — set/confirm the chosen library
- `dashboard_[app-name-kebab]` — dashboard status record:
  ```
  App: [App Name]
  Library: [chart.js|apexcharts]
  KPIs: [N] cards
  Charts: [N] visualizations
  Tables: [N] summary tables
  Built: [timestamp]
  ```

Print final confirmation:

```
DASHBOARD GENERATED — [App Name]
────────────────────────────────────────────
dashboard.html
  KPI cards:   [N] ([list of entity/field pairs])
  Charts:      [N] ([list of chart types])
  Tables:      [N] ([list of entities])

charts-config.json
  [N] chart definitions (editable)

Library:  [Chart.js | ApexCharts]
────────────────────────────────────────────
NOTE: All KPIs will show "—" until data is loaded.
      Enter records via the CRUD pages first.

NEXT: /app-deployer to deploy, or /auth-integrator to add login protection to the dashboard.
```

---

## Embedded Skills & Callouts

- **Called by**: user manually (`/dashboard-builder`), or selected from `app-architect`
  build menu when blueprint has `type: "dashboard"` components
- **Calls**: none — outputs files and waits for user
- **Reads**: `blueprint.json` (schema, components, routes), `css/styles.css` (for color palette)
- **Writes**: `dashboard.html`, `charts-config.json`, updates `index.html` nav + `routes.js`
- **Memory reads**: `preferred_chart_library`
- **Memory writes**: `preferred_chart_library`, `dashboard_[app-name]` (status record)

---

## Memory Allocation

Reads:
- `preferred_chart_library` — Chart.js or ApexCharts (ask and set on first run if absent)

Writes after completion:
- `preferred_chart_library` — saved for all future dashboard builds
- `dashboard_[app-name-kebab]` — dashboard status record (KPI count, chart count, library)

Project files written:
```
C:\Users\mdecker\.claude\skills\website model\projects\[app-name]\
├── dashboard.html          ← KPI cards + charts + summary tables
├── charts-config.json      ← editable chart definitions
├── index.html              ← updated with Dashboard nav link
└── js\
    └── routes.js           ← updated with #/dashboard route
```

---

## Versioning & Iteration

- If a project needs date-range filtering on charts → add a date picker to dashboard.html
  that re-runs queries with `gte`/`lte` filters.
- If the user wants to customize chart colors → add a `theme` key to charts-config.json
  and read it during chart init.
- If ApexCharts is consistently preferred → make it the default (skip the runtime question
  after 3+ builds using it).
- After 3+ real dashboard builds → compare generated metrics against what users actually
  care about. If a specific metric type (e.g., "records created this week") is always
  manually added → build it in as a standard KPI card for any entity with a `created_at`
  field.
