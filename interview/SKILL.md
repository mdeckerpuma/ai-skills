---
name: interview
description: >
  Dynamic skill interview harness. Fires before any new skill is created. Uses AskUserQuestion
  rounds (4 questions at a time, multiple choice) that adapt based on prior answers, tracks
  confidence toward 99%, then hands a complete spec to skill-builder to write the SKILL.md.
  Use this skill whenever someone wants to create a new skill, automate a task, or says
  "interview me", "ask me about this skill", "build me a skill", or "I have a skill idea."
  Always interview BEFORE writing. Never skip to writing without completing the interview.
user-invocable: true
argument-hint: "brief description of skill idea"
---

# Interview

A structured, adaptive interview harness that replaces the static 5-question skill-builder
flow. Runs multiple rounds of AskUserQuestion (4 questions per round, multiple choice) that
change based on what was just learned. Tracks confidence. Stops only when 99% confident the
full SKILL.md can be written correctly without guessing.

The interview has four phases:
1. **Orient** — understand the skill type and domain
2. **Dig** — skill-type-specific deep questions (adapts per type)
3. **Bound** — guardrails, edge cases, failure modes
4. **Land** — output format, file paths, confidence check + where to write the spec

---

## Guardrails

- **Never write the SKILL.md before the interview is complete.** No matter how clear the
  idea sounds, always run at least Phase 1 and Phase 2 before writing.
- **Never ask fewer than 8 total questions.** Confidence below 80% means more questions.
- **Never repeat a question already answered.** Adapt each round based on prior answers.
- **Never present fewer than 2 options per question.** Multiple choice only — no open-ended
  text prompts mid-interview (the final "anything else?" is the only free-text exception).
- **Never skip Phase 4.** Always confirm the output path before writing.
- **Stop at 99% confidence.** Do not over-interview. If confidence is 99%+ after Phase 2,
  jump to Phase 4 immediately.

---

## Gotchas

- **User gives a vague idea** — start broad in Phase 1, narrow down through Phase 2.
  The multiple-choice options are what surface specifics the user hasn't thought of yet.
- **Skill overlaps an existing skill** — after Phase 1, check if a similar skill exists
  in `C:\Users\mdecker\.claude\skills\`. If so, surface it: "You already have X which does
  Y — is this an upgrade or something distinct?"
- **User selects "Other"** — treat it as a free-text answer and incorporate it into the
  next round's options.
- **Confidence stalls below 80% after Phase 3** — run one bonus round targeted at the
  specific gap. State what's unclear and ask targeted questions about only that gap.
- **Skill idea is actually two skills** — flag it: "This sounds like two separate skills:
  X and Y. Build them separately or combine into one?"
- **User wants to skip questions** — allow it but note the gap: "Skipping [topic] — I'll
  make a reasonable assumption and flag it in the SKILL.md as a TODO."

---

## Confidence Tracking

Maintain a running confidence estimate internally. Never show the percentage to the user
mid-interview — only reference it in the final Phase 4 check.

| After Phase | Expected Confidence |
|-------------|-------------------|
| Phase 1 done | ~50% |
| Phase 2 done | ~75% |
| Phase 3 done | ~90% |
| Phase 4 done | 99% |

If confidence after Phase 3 is below 85%, run a bonus round before Phase 4. State:
"One more round — I want to be sure about [specific gap]." Then ask 2–4 targeted questions.

---

## Phase 1 — Orient (4 questions)

**Goal:** Understand what type of skill this is so Phase 2 questions can be tailored.

Use AskUserQuestion with these 4 questions. Adapt the option labels to match the skill
idea the user described (don't use generic placeholders).

```
Q1 — Skill type
"What category best describes what this skill does?"
Options (pick the 4 most relevant for the idea):
- File / document processing  (creates, reads, or transforms files)
- Communication / messaging   (sends, formats, or logs messages)
- Learning / coaching         (quizzes, teaches, tracks progress)
- System / config management  (manages settings, paths, configs, memory)
- Data analysis               (processes numbers, logs, or structured data)
- Workflow automation         (orchestrates multi-step tasks)

Q2 — Trigger type
"How will you invoke this skill?"
- Manually with a slash command (/skill-name)
- Automatically when something happens (end of session, after another skill, etc.)
- Both manual and automatic
- Embedded inside another skill (called, not invoked directly)

Q3 — Primary output
"What does a successful run produce?"
- A file saved to disk (markdown, JSON, Excel, Word, etc.)
- An update to an existing file (append, edit in place)
- Information displayed in chat only (no file written)
- A change to config or settings

Q4 — Scope awareness
"How much does this skill need to know about your other skills and memory?"
- Standalone — works with no knowledge of the rest of the system
- Reads memory — needs to load context from .claude memory before running
- Writes memory — saves new context to .claude memory after running
- Full integration — reads AND writes memory, chains with other skills
```

---

## Phase 2 — Dig (4 questions, adapted per skill type)

**Goal:** Get the specifics that determine what the SKILL.md body looks like. Adapt all
four questions based on Phase 1 answers. Use the user's own words in the option labels.

### If skill type = File / document processing:
```
Q1 — Input source: where does the raw material come from?
Q2 — Output format and naming convention?
Q3 — What folder should the output land in? (offer the skill's own outputs/ folder + options)
Q4 — What happens if the input file is missing or malformed?
```

### If skill type = Learning / coaching:
```
Q1 — What domain / subject matter? (be specific — draw from user's existing skills)
Q2 — How is progress tracked? (per-session file, cumulative score, memory entry)
Q3 — What does a session look like? (quiz → feedback → summary? or freeform?)
Q4 — What should carry over between sessions? (scores, notes, weak spots)
```

### If skill type = System / config management:
```
Q1 — Which part of the system does it touch? (.claude config, skills, memory, VSCode, all)
Q2 — Is it read-only, write-only, or bidirectional?
Q3 — What's the failure risk if something goes wrong? (low / medium / high — get details)
Q4 — Should changes be reversible? (backup before write, dry-run mode, etc.)
```

### If skill type = Workflow automation:
```
Q1 — What triggers the start of the workflow?
Q2 — What are the 2–4 main steps in order?
Q3 — Where does it hand off or chain to another skill?
Q4 — What constitutes "done" — how will you know it worked?
```

### If skill type = Communication / messaging or Data analysis:
```
Q1 — What is the source of the data / message?
Q2 — Who or what receives the output?
Q3 — What format is required (length, tone, structure)?
Q4 — What should it never say / include?
```

### For any type — if "Full integration" was selected in Phase 1 Q4, add:
```
Which existing skills does this need to chain with or call?
(List the installed skills and allow multi-select)
```

---

## Phase 3 — Bound (4 questions)

**Goal:** Define the won't-do list and failure modes that go into Guardrails and Gotchas.

These 4 questions are the same across all skill types but options adapt from Phase 2:

```
Q1 — Hard limits
"What should this skill NEVER do?"
Options built from Phase 2 context — e.g.:
- Never overwrite existing files
- Never run on weekends
- Never touch files outside its own outputs/ folder
- Never delete anything
- [Other — always include]

Q2 — Most likely failure mode
"What's the most likely way this skill produces bad output?"
Options built from skill type — e.g.:
- Input file is empty or missing
- User gives an ambiguous answer mid-run
- A dependency skill hasn't run yet
- Path doesn't exist yet on first run
- [Other]

Q3 — Frequency and tolerance
"How often will this run and how forgiving does it need to be?"
- Daily — must be bulletproof, no user intervention
- A few times a week — can ask a clarifying question if confused
- Rarely / on demand — can be more manual, user will guide edge cases
- Varies — depends on context

Q4 — Recovery behavior
"If something goes wrong mid-run, what should it do?"
- Stop and report the error clearly, take no further action
- Try to recover automatically and note what it did
- Ask the user how to proceed before continuing
- Write a partial result and flag it as incomplete
```

---

## Phase 4 — Land (2 questions + final check)

**Goal:** Confirm the output path and close the interview.

```
Q1 — Where should the SKILL.md be written?
Options:
- C:\Users\mdecker\.claude\skills\[derived-name]\SKILL.md  (live, immediately installable)
- C:\Users\mdecker\.claude\skills\[derived-name]\SPEC.md   (review draft first)
- Both — SPEC.md to review, promote to SKILL.md once approved
- Let me type a custom path

Q2 — Should vault sync run after the skill is written?
- Yes — run /vault to index the new skill and update CLAUDE.md
- No — I'll sync manually later
```

Then ask one final open text question:
> "Anything the interview didn't cover that the skill needs to know? (Type 'no' to skip.)"

If the user adds something meaningful, incorporate it. If 'no', proceed.

---

## Final Confidence Check

Before handing off to skill-builder, internally verify:

- [ ] Skill name is clear (kebab-case, 2 words max)
- [ ] Trigger phrases are specific enough for the description field
- [ ] Output path is confirmed
- [ ] At least 2 guardrails identified
- [ ] At least 1 gotcha identified
- [ ] Failure mode and recovery behavior defined

If any box is unchecked, ask one targeted question to fill that gap. Do not hand off with
unknowns — they become bad SKILL.md sections.

---

## Handoff to skill-builder

Once the interview is complete, say:

> "Interview complete — I have everything I need. Writing your skill now."

Then proceed exactly as skill-builder Step 2 describes: write the SKILL.md to the confirmed
path covering all ten anatomy parts, using the interview answers as the source material.

**Key mapping from interview to SKILL.md sections:**

| Interview Phase | → | SKILL.md Section |
|-----------------|---|-----------------|
| Phase 1 Q1 (type) | → | Frontmatter description |
| Phase 1 Q2 (trigger) | → | Frontmatter description trigger phrases |
| Phase 1 Q3 (output) | → | Memory Allocation + Body steps |
| Phase 2 (deep questions) | → | Body / Steps (the actual recipe) |
| Phase 3 Q1 (hard limits) | → | Guardrails |
| Phase 3 Q2 (failure modes) | → | Gotchas |
| Phase 3 Q4 (recovery) | → | Body / Steps (error handling step) |
| Phase 4 Q1 (path) | → | Write location |

---

## Embedded Skills & Callouts

- **skill-builder** — this skill IS the interview phase of skill-builder. After Phase 4,
  follow skill-builder's Step 2 and Step 3 to write and confirm the file.
- **vault** — call `/vault` after writing the SKILL.md if the user selected it in Phase 4 Q2.

---

## Memory Allocation

No sub-files needed. Interview state lives in the conversation. The output is the SKILL.md
written to disk at the confirmed path.

---

## Versioning & Iteration

- If questions feel off for a specific skill type, add or edit the Phase 2 branch for that type.
- If the interview regularly misses something important, add it to Phase 3 as a new standard question.
- After 5+ skill builds using this interview, review whether the handoff mapping produces
  consistently strong Guardrails and Gotchas sections — those are the most commonly weak.
