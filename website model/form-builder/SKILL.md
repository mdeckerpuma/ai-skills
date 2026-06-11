---
name: form-builder
description: >
  Generates multi-step form wizards and intake forms from blueprint.json. Automatically
  derives step groupings from blueprint field patterns (contact info, details, review).
  Produces a self-contained wizard HTML page with progress indicator, field-level and
  step-level conditional logic defined in form-config.json, client-side validation on every
  required field, and Supabase submission that triggers a confirmation email and redirects
  to a thank-you page. Available from the app-architect build menu or invoked manually.
  Trigger phrases: "build a form wizard", "add intake form", "generate multi-step form",
  "build a wizard", "/form-builder".
user-invocable: true
argument-hint: "project name or entity name, or path to blueprint.json"
---

# Form Builder

Reads blueprint.json and generates a complete multi-step form wizard for one or more
entities. Automatically groups fields into logical steps, supports both field-level
(show/hide) and step-level (skip) conditional logic via an editable form-config.json, and
validates all required fields before submission. On submit: saves to Supabase, triggers a
confirmation email, and redirects to a confirmation page. Never submits without validation.
Never silently overwrites. Never generates a form without a confirmation page.

---

## Guardrails

- **Never generate a form that submits without client-side validation.** Every required
  field (derived from blueprint schema) must be validated before the final step's submit
  button is enabled. If validation state is unclear for a field, default to required.
- **Never overwrite an existing form file without asking.** If `[entity]-wizard.html` or
  `form-config.json` already exist, show a one-line diff summary and ask:
  **Overwrite / Keep / Cancel** per file.
- **Never skip the confirmation page.** Every generated wizard must have a corresponding
  `[entity]-confirm.html` page. A form that submits to a dead end (no feedback to the user)
  is never acceptable.
- **Never proceed if blueprint.json is missing or has no schema.** Hard stop:
  > "No blueprint.json found. Run /app-architect first."
- **Never generate conditional rules that reference fields not in blueprint.json.** If
  form-config.json references a field name that doesn't exist in the schema, stop and
  report the conflict before writing any files.

---

## Gotchas

- **Supabase email confirmation not configured.** The most common silent failure: the form
  saves data correctly but the user never receives a confirmation email because Supabase
  email templates aren't set up. Always output a post-generation checklist:
  > "IMPORTANT: Confirmation emails require Supabase email templates to be configured.
  > Go to: Supabase Dashboard → Authentication → Email Templates → Confirm signup (or
  > create a custom template). Until configured, form submissions will save but send no email."

- **Auto-grouping puts too many fields in one step.** If an entity has 10+ fields and the
  grouping algorithm can't find natural breakpoints, one step becomes a wall of inputs.
  Apply a hard cap: **no more than 6 fields per step**. If auto-grouping would exceed 6,
  split into additional steps and name the overflow step "Additional Details".

- **Form state lost on browser back navigation.** If the user presses the browser back
  button instead of the wizard's Back button, form state (values entered in earlier steps)
  may be cleared. The wizard must persist step state in `sessionStorage` on every field
  change — not just on Next/Back button clicks.

- **Conditional step-skip breaks progress bar numbering.** If step 3 of 5 is skipped, the
  progress bar must not show "Step 3 of 5 → Step 5 of 5". Always recalculate visible step
  count dynamically and display "Step [visible index] of [visible total]" — never raw indices.

- **Required field on a conditionally hidden field.** If a field is required in blueprint
  but conditionally hidden in form-config.json, it must be exempt from validation when
  hidden. The validation layer must check whether a field is currently visible before
  enforcing its required status.

---

## Steps

### 0 — Pre-flight

1. Identify the project and target entity. Accept an entity name argument, or list available
   entities from blueprint.json and ask the user to pick one (or "all").

2. Read and validate `blueprint.json`. Required: `app.name`, `schema[]`, at least one entity
   with 2+ user-editable fields (beyond `id` and `created_at`).

3. Check if `[entity]-wizard.html`, `form-config.json`, or `[entity]-confirm.html` already
   exist in the project pages folder. If any exist, show a diff summary and ask:
   **Overwrite / Keep / Cancel** per file.

4. Load memory: `preferred_frontend_stack` (for style decisions only).

---

### 1 — Derive step groupings

For the target entity, walk `blueprint.schema[entity].fields` (excluding `id`, `created_at`)
and group fields into steps using this heuristic:

| Field name pattern | Step group |
|-------------------|------------|
| `name`, `email`, `phone`, `first_name`, `last_name` | "Contact Info" |
| `address`, `city`, `state`, `zip`, `country` | "Address" |
| `company`, `organization`, `role`, `title` | "Organization" |
| `amount`, `budget`, `price`, `quantity` | "Financial Details" |
| `notes`, `description`, `message`, `comments` | "Additional Details" |
| `status`, `type`, `category`, `priority` | "Classification" |
| Remaining fields | "Details" (catch-all) |

Apply the 6-fields-per-step cap (see Gotchas). Add a final "Review & Submit" step that
shows a read-only summary of all entered values before submission.

Display the derived step plan to the user before writing any files:
```
Proposed steps for [Entity]:
  Step 1: Contact Info (name, email, phone)
  Step 2: Details (company, role, notes)
  Step 3: Review & Submit

Proceed with this step layout? (yes / adjust manually)
```
If the user says yes, continue. If they want to adjust, ask them to describe the change
and incorporate it before proceeding.

---

### 2 — Build form-config.json

Write `projects\[app-name]\pages\[entity]-form-config.json`:

```json
{
  "entity": "[entity]",
  "steps": [
    {
      "id": "step-1",
      "title": "Contact Info",
      "fields": ["name", "email", "phone"],
      "conditions": []
    },
    {
      "id": "step-2",
      "title": "Details",
      "fields": ["company", "role", "notes"],
      "conditions": [
        {
          "type": "step-skip",
          "when": { "field": "[trigger-field]", "equals": "[value]" }
        }
      ]
    }
  ],
  "fieldConditions": [
    {
      "field": "[conditional-field]",
      "showWhen": { "field": "[trigger-field]", "equals": "[value]" }
    }
  ],
  "submission": {
    "table": "[entity]",
    "upsert": true,
    "onSuccess": "redirect",
    "confirmationPage": "pages/[entity]-confirm.html",
    "emailTrigger": "supabase-email-template"
  }
}
```

Populate `fieldConditions` only where blueprint fields have names that imply conditionality
(e.g., `spouse_name` implies show-only-if `marital_status = married`). Leave `conditions`
array empty for steps with no natural skip logic — user can add manually.

---

### 3 — Generate [entity]-wizard.html

Write `projects\[app-name]\pages\[entity]-wizard.html`:

**Structure:**
- Progress bar at top: "Step [visible index] of [visible total]: [Step Title]"
  (dynamically recalculated when steps are skipped)
- One step container per step (only the active step is visible — others `display: none`)
- Each step's fields rendered from `form-config.json` step definition:
  - Input types mapped from blueprint field types (same mapping as crud-builder Step 3b)
  - Required fields marked with `*` and validated before Next is enabled
  - Field-level `showWhen` conditions evaluated on every input change event
- Back / Next buttons (Next disabled until step validation passes)
- Final step: "Review & Submit" — read-only summary of all values + Submit button

**State persistence:**
```javascript
// Save all form values to sessionStorage on every input change
document.addEventListener('input', (e) => {
  const state = JSON.parse(sessionStorage.getItem('formState') || '{}');
  state[e.target.name] = e.target.value;
  sessionStorage.setItem('formState', JSON.stringify(state));
});

// Restore on page load (handles browser back navigation)
window.addEventListener('load', () => {
  const state = JSON.parse(sessionStorage.getItem('formState') || '{}');
  Object.entries(state).forEach(([name, value]) => {
    const el = document.querySelector(`[name="${name}"]`);
    if (el) el.value = value;
  });
});
```

**Conditional logic engine:**
```javascript
function evaluateConditions() {
  formConfig.fieldConditions.forEach(({ field, showWhen }) => {
    const triggerEl = document.querySelector(`[name="${showWhen.field}"]`);
    const targetEl = document.querySelector(`[name="${field}"]`)?.closest('.field-group');
    if (triggerEl && targetEl) {
      const show = triggerEl.value === showWhen.equals;
      targetEl.style.display = show ? '' : 'none';
      if (!show) targetEl.querySelector('input,textarea,select').value = '';
    }
  });
}
```

**Submission:**
```javascript
const { error } = await supabase.from('[entity]').upsert(formData);
if (error) { showError(error.message); return; }
await supabase.auth.resetPasswordForEmail(formData.email); // triggers email if configured
sessionStorage.removeItem('formState');
window.location.href = 'pages/[entity]-confirm.html';
```

Apply auth-guard if the blueprint component for this entity has `auth: true`.

---

### 4 — Generate [entity]-confirm.html

Write `projects\[app-name]\pages\[entity]-confirm.html`:

- "Thank you" heading with the entity name
- Summary of submitted values (read from `sessionStorage` before clearing, or show generic)
- "Submit another [entity]" link → back to wizard
- "View your [entity]" link → `[entity]-list.html` (if auth-protected, guard accordingly)
- "Go home" link → `index.html`

---

### 5 — Update index.html and routes.js

Add wizard and confirm routes to `js\routes.js`:
```javascript
'#/[entity]/wizard':   'pages/[entity]-wizard.html',
'#/[entity]/confirm':  'pages/[entity]-confirm.html',
```

Add "New [Entity] (Wizard)" link to `index.html` nav alongside the existing CRUD list link.

---

### 6 — Write memory and confirm

Write to memory:
- `form_[app-name-kebab]_[entity]` — full form record:
  ```
  App: [App Name]
  Entity: [entity]
  Steps: [N] ([step titles])
  Fields per step: [breakdown]
  Conditionals: [field-level: N, step-level: N]
  Confirmation page: [entity]-confirm.html
  Email trigger: configured / not confirmed
  ```

Print final confirmation:

```
FORM WIZARD GENERATED — [App Name] / [Entity]
────────────────────────────────────────────
pages\[entity]-wizard.html     ([N] steps, progress bar, validation)
pages\[entity]-wizard-config.json   (editable step + conditional config)
pages\[entity]-confirm.html    (thank-you + summary)

Steps:
  [step list]

Conditionals: [N] field-level, [N] step-level
────────────────────────────────────────────
⚠ EMAIL: Supabase email templates must be configured before confirmation
  emails will send. See Supabase Dashboard → Auth → Email Templates.

NEXT: /app-deployer to deploy, or /dashboard-builder to add reporting.
```

---

## Embedded Skills & Callouts

- **Called by**: user manually (`/form-builder`), or selected from `app-architect` build menu
  when blueprint has `type: "form"` components
- **Calls**: none — outputs files and waits for user
- **Reads**: `blueprint.json` (schema, components, routes), `css/styles.css`
- **Writes**: `[entity]-wizard.html`, `[entity]-wizard-config.json`, `[entity]-confirm.html`,
  updates `routes.js` and `index.html`
- **Memory reads**: `preferred_frontend_stack`
- **Memory writes**: `form_[app-name]_[entity]` — full form record

---

## Memory Allocation

Reads:
- `preferred_frontend_stack` — for style decisions only

Writes after completion:
- `form_[app-name-kebab]_[entity]` — full form record (steps, fields, conditional rules)

Project files written:
```
C:\Users\mdecker\.claude\skills\website model\projects\[app-name]\
├── pages\
│   ├── [entity]-wizard.html        ← multi-step wizard with validation + conditionals
│   ├── [entity]-wizard-config.json ← editable step and conditional definitions
│   └── [entity]-confirm.html       ← thank-you / submission confirmation page
└── js\
    └── routes.js                   ← updated with wizard + confirm routes
```

---

## Versioning & Iteration

- If email confirmation is frequently skipped → make `emailTrigger` optional in
  form-config.json and add a flag that suppresses the email checklist warning when set
  to `none`.
- If the 6-field cap is too aggressive for certain schemas → make it configurable in
  form-config.json as `maxFieldsPerStep`.
- If step-skip logic is never used → simplify to field-level conditionals only and remove
  the step conditions array from form-config.json.
- After 3+ real form builds → compare generated step groupings against what users actually
  kept. If a specific grouping pattern (e.g., financial fields always get their own step)
  is always preserved → add it to the auto-grouping heuristic table.
