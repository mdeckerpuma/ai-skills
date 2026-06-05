---
name: macro-tracker
description: >
  Tracks daily macros, micronutrients, and calories from meal logs throughout the day.
  Use this skill when the user says "I ate", "I just had", "I drank", or provides food
  measurements like "150g apple" or "200g chicken breast". Also triggers when the user
  uploads a photo of food. After each log entry, show a running daily summary of all
  nutrients so far. Use this skill when someone logs anything they consumed today,
  including photos of meals when out.
user-invocable: true
argument-hint: "food item with quantity, or photo of meal"
---

# Macro Tracker

Logs every meal the user eats throughout the day and shows a running nutrient summary after each entry.

---

## Guardrails

- **Never delete past logs.** Append only. If a log file exists, add to it — never overwrite or clear it.
- **Never give medical advice.** You can report nutrient data and flag large deficits/surpluses, but never diagnose or prescribe.
- **Never guess a fitness goal** — if the user hasn't set one yet, ask once and store it.
- **Stay inside** `~/.claude/skills/macro-tracker/logs/` for all data files.

---

## Gotchas

- **Vague input** ("I had a snack", "some nuts") → make a reasonable estimate, clearly label it as an estimate, and note what assumption was made (e.g. "~30g mixed nuts assumed").
- **Photo of food** → visually estimate portion size and nutrients. Target within ±5% of actual. Label the entry as a visual estimate.
- **Unrecognized food or brand** → use the closest generic equivalent and note the substitution.
- **Missing micronutrient data** → log what's known, mark unknowns as "—" rather than 0.
- **Multiple items in one message** → log all of them as a single meal entry with individual line items.
- **No fitness goal set yet** → prompt the user once to provide goal + basic stats (weight, height, age, activity level). Store in `profile.json`. Don't ask again after that.

---

## Memory Allocation

Supporting files live alongside SKILL.md:

- `logs/YYYY-MM-DD.json` — one file per day, append-only meal log
- `profile.json` — user's fitness goal, stats, and calculated daily calorie target

Load today's log file at the start of each run to compute the running totals. Load `profile.json` to show progress against the daily target.

---

## Steps

1. **Load profile**
   Read `~/.claude/skills/macro-tracker/profile.json`.
   - If it doesn't exist, ask the user for: current weight, height, age, sex, activity level, and fitness goal (lose weight / maintain / build muscle / other).
   - Calculate their TDEE using the Mifflin-St Jeor formula and apply a goal modifier (deficit of ~300–500 kcal for loss, surplus of ~200–300 kcal for muscle gain, maintenance otherwise).
   - Save to `profile.json` and confirm with the user before continuing.

2. **Parse the meal input**
   - If the input is text with quantities (e.g. "150g apple, 200g chicken breast"), extract each food item and weight.
   - If the input is a photo, visually identify the foods and estimate portion sizes. Label all values as visual estimates (±5%).
   - If the input is vague (no measurements), make a reasonable estimate and clearly state the assumption made.

3. **Look up nutrients**
   For each food item, retrieve or estimate:
   - Calories (kcal)
   - Protein (g)
   - Carbohydrates (g) — including fiber and sugar
   - Fat (g) — including saturated fat
   - Key micronutrients: Sodium (mg), Potassium (mg), Calcium (mg), Iron (mg), Vitamin C (mg), Vitamin D (IU)
   Use standard nutritional databases as reference. If data is unavailable, mark as "—".

4. **Append to today's log**
   Open `~/.claude/skills/macro-tracker/logs/YYYY-MM-DD.json` (create if it doesn't exist).
   Append a new entry:
   ```json
   {
     "time": "HH:MM",
     "meal": "Meal name or description",
     "items": [
       { "food": "chicken breast", "quantity_g": 200, "estimated": false, "calories": 330, "protein": 62, "carbs": 0, "fat": 7, ... }
     ]
   }
   ```
   Never overwrite existing entries.

5. **Compute running daily totals**
   Sum all entries in today's log file for every nutrient tracked.

6. **Display running summary in chat**
   Show a clean, easy-to-read update after every log entry:

   ```
   ✅ Logged: 200g chicken breast, 150g apple

   📊 Today so far  (Goal: 2,400 kcal)
   ────────────────────────────────────
   Calories    1,240 / 2,400 kcal  ██████░░░░░░  52%
   Protein       85 / 160g
   Carbs        110 / 260g
   Fat           30 / 70g

   🔬 Micronutrients
   Sodium      940mg   Potassium  1,200mg
   Calcium     320mg   Iron          6mg
   Vitamin C    45mg   Vitamin D    200IU

   🍽️ Meals logged today: 3
   ```

   If any macro is >90% of target before dinner, add a friendly heads-up.
   If any macro is critically low by end of day (if user says "that's all for today"), note the gap.

---

## Embedded Skills & Callouts

Standalone — does not chain into other skills. Future version could call a `weekly-summary` skill to roll up logs across days.

---

## Versioning & Iteration

- If the skill fires when it shouldn't → tighten the description (remove broad phrases)
- If it misses meal logs → add more trigger phrases to the description
- If nutrient estimates feel off → add a `corrections.json` file with user-specific overrides for common foods
- After 2+ weeks of use → review `logs/` and add real meal examples to `evals/evals.json`

---

## Sub-files

```
macro-tracker/
├── SKILL.md
├── profile.json          ← created on first run
└── logs/
    └── YYYY-MM-DD.json   ← one per day, append-only
```
