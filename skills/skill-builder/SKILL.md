---
name: skill-builder
description: Builds a new Claude Code skill from scratch by interviewing the user and writing a complete SKILL.md. Use this whenever someone wants to create a skill, automate a task, turn a workflow into a command, build a /slash command, or asks "how do I make a skill." Also trigger when someone says "build me a skill", "make a skill for X", "I want to automate Y", or "create a skill that does Z." Interview first — never write the skill without asking questions.
---

# Skill Builder

You build Claude Code skills. Your job is to interview the user, then produce a complete, well-structured SKILL.md that covers all ten anatomy parts below. You write the file — not paste it in chat.

---

## Step 1 — Interview

Ask these questions **one at a time**. Do not move to the next until the user answers. Do not write the skill until all five are answered.

1. **What task do you want to automate?** Describe it in plain language — what do you do by hand today that you want Claude to do for you?
2. **When should this skill trigger?** What would you actually type or say to invoke it? Give me 2–3 real phrases.
3. **What does the output look like?** A file? A report in chat? An edit to existing code? Where does it go?
4. **What should it never do?** Any hard limits — files it shouldn't touch, actions it shouldn't take, scope it must stay inside.
5. **What could break it?** Empty inputs, bad data, edge cases, things that would make the skill produce garbage.

**Adapt your language** to how technical the answers are. If someone says "I just want it to write emails for me," speak in plain English throughout. If they're clearly a developer, you can be more technical.

After all five are answered, say: "Got it — writing your skill now." Then proceed to Step 2.

---

## Step 2 — Write the SKILL.md

Produce a complete SKILL.md covering all ten anatomy parts. Write it to:

```
C:\Users\mdecker\.claude\skills\[name]\SKILL.md
```

Create the directory if it doesn't exist. Confirm the path to the user when done.

### The Ten Anatomy Parts

Every skill you write must address all ten. Here's what each one is and why it matters:

---

**1. Name** (frontmatter)

Kebab-case. Two words max. This is the invoke handle — how the user calls it and how other skills reference it. Pick it carefully: renaming later means hunting every callout that references it.

---

**2. Description** (frontmatter — the most important field)

Claude reads this to decide *when* to fire the skill. Not the body — the description. This is the trigger.

- Too vague → never runs
- Too greedy → fires on the wrong things
- Pack it with real trigger phrases the user actually said in the interview
- Include an explicit "use this when…" sentence
- When the skill misbehaves, tune this first — almost never the body

---

**3. Gotchas** (body section)

Real failures from live runs — wrong paths, broken writes, edge cases — written down so the next run avoids the trap. Use the user's answers from question 5 of the interview. Leave a placeholder comment if the skill is brand new.

---

**4. Guardrails** (body section)

Hard limits — the won't-do list. Use the user's answers from question 4. More constraints = more autonomy: when the worst case is bounded, the skill can run unattended.

---

**5. Embedded skills & callouts** (body section, if applicable)

A skill can invoke other skills by name. State is shared through files, not imports. If this skill chains into others, document which ones and what it hands off. If it's standalone, say so.

---

**6. Memory allocation** (body section, if applicable)

Templates, configs, and reference docs live beside SKILL.md and load only when the skill runs — keeping the main context lean. State passes by writing to disk, not stuffing the conversation. If this skill needs sub-files, note them here and create them.

---

**7. Frontmatter controls** (frontmatter, as needed)

Optional switches that change how Claude handles the skill:

- `disable-model-invocation: true` — run only when explicitly called; never auto-triggered by description match
- `user-invocable: true` — shows in the `/` command menu
- `argument-hint: "description"` — tells callers what override arguments to pass

Only include these if the skill needs them. Don't add them by default.

---

**8. Body / steps** (body — the actual recipe)

Numbered steps Claude follows in order once the skill fires. This is where the real "how" lives.

Rules for good steps:
- **Specific beats vague.** Bad: "Understand the context." Good: "Read the file at X and note the values in column C."
- **Verifiable.** Give Claude a way to check each step before moving on: "Confirm the output file exists before continuing."
- **Sequenced.** Order matters. Each step should produce something the next step can use.

---

**9. Sub-files, scripts & evals** (folder structure, if needed)

If the skill needs supporting files, create them alongside SKILL.md:

```
skill-name/
├── SKILL.md
├── template.md       ← output template loaded on run
├── config.json       ← tunable parameters
└── evals/
    └── evals.json    ← test cases (add after first real run)
```

For simple skills, SKILL.md alone is fine.

---

**10. Versioning & iteration** (end of body)

Tell the user how to improve the skill over time:

- When triggering misfires → edit the **description** first, not the body
- When output quality drifts → add a gotcha or tighten a step
- After 5+ real runs → add eval cases to `evals/evals.json` to verify edits don't break it

---

## Step 3 — Confirm and offer next steps

After writing the file:

1. Confirm the path: "Skill written to `C:\Users\mdecker\.claude\skills\[name]\SKILL.md`."
2. Show the user the exact phrase they can type to trigger it for the first time.
3. Offer: "Want me to run a quick test to make sure it triggers correctly?"

---

## Rules

- **Interview first. Always.** Never write the skill before all five questions are answered.
- **Write the file.** Don't paste the SKILL.md contents in chat — write it to disk and confirm the path.
- **All ten parts.** Even if some sections are short (e.g., "no sub-files needed"), address them.
- **Use the interview answers.** The description must include the user's actual trigger phrases. Guardrails come from their "never do" answer. Gotchas come from their "what could break it" answer.
- **One question at a time.** Don't front-load all five questions at once — it overwhelms non-technical users.
