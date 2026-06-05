---
name: journal
description: >
  Journals the user's daily progress and saves it to a running journal file. Use this skill when the user says "journal", "session end", "log my day", "end of day", "journal entry", or anything that sounds like they want to record what they did today. Also use this skill at the START of any conversation on a weekday if the previous weekday has no journal entry — remind the user they missed it before doing anything else. Never trigger on weekends (Saturday/Sunday). When the user says "journal summary" or "show my journal", display the journal contents in chat.
---

# Journal

Records the user's daily progress to a single running journal file. One entry per day, appended over time. Doubles as a missed-entry reminder at the start of weekday conversations.

---

## Guardrails

- **Never overwrite the journal file** — only append new entries.
- **Never create duplicate entries for the same date** — if today already has an entry, ask the user if they want to add to it or skip.
- **Never journal on weekends** — if invoked on Saturday or Sunday, let the user know and do nothing.
- **Never delete past entries** — the file is append-only.
- **No hard limits on content** — if the user didn't do much, that's a valid entry. Log it as-is.

---

## Gotchas

- **User forgets to journal** — at the start of the first conversation on any weekday, check if the previous weekday has an entry. If not, remind the user before proceeding with anything else. Skip this check on Mondays for the prior Friday only if Friday has no entry.
- **File doesn't exist yet** — create it automatically on first run. Do not error out.
- **User invokes with nothing to say** — that's fine. Ask one prompt: "What did you work on today?" If they still say little, log it as written — short entries are valid.
- **User invokes on a weekend** — acknowledge it, do nothing, move on.
- **User asks for a summary** — read the file and display it in chat. Do not modify the file.

---

## Embedded Skills & Callouts

Standalone — does not chain into other skills.

---

## Memory Allocation

Journal is saved to: `C:\Users\mdecker\ai-skills\journal\journal.md`

Create the file and directory on first run if they don't exist. No other sub-files needed.

---

## Body / Steps

### On skill trigger ("journal", "session end", etc.)

1. **Check the day.** If today is Saturday or Sunday, tell the user: "No journal on weekends — enjoy your time off." Stop here.

2. **Check for duplicate.** Read `journal.md` and check if today's date already has an entry. If yes, ask: "You already have an entry for today — want to add to it or skip?" Wait for their answer before continuing.

3. **Prompt if needed.** If the user invoked the skill without describing their day, ask: "What did you work on today?" Wait for their response. Accept whatever they give — short is fine.

4. **Write the entry.** The user will likely give you phrases, keywords, or bullet points — not full sentences. Convert what they give you into a clean, natural summary written in first person. Do not add facts or embellish — only expand what they actually said into readable prose. Keep their voice. Append to `journal.md` in this format:

```
---
## [Weekday, Month DD, YYYY]

[Polished summary in first person, expanded from the user's phrases. Natural and concise — not a bullet list.]

---
```

5. **Confirm.** Say: "Logged. Journal updated." Nothing more unless the user asks.

---

### On summary request ("journal summary", "show my journal")

1. Read `journal.md`.
2. Display the full contents in chat as formatted markdown.
3. Do not modify the file.

---

### At the start of a weekday conversation (missed entry check)

1. Check today's date. If it's Saturday or Sunday, skip entirely.
2. Determine the previous weekday (skip Saturday/Sunday when counting back).
3. Read `journal.md` and check if the previous weekday has an entry.
4. If **no entry found**, before responding to the user's message say: "Hey — no journal entry for [previous weekday date]. Did you want to log anything for that day, or skip it?"
5. Wait for their response, then continue with whatever they originally asked.
6. If **entry exists**, do nothing — proceed normally.

---

## Versioning & Iteration

- If the skill triggers when it shouldn't → tighten the `description` field first
- If the missed-entry reminder feels annoying → add a "skip reminder for today" note to the journal file and check for it
- After 30+ entries → consider adding a "monthly summary" command that summarizes the month's entries
- If the file path changes → update Memory Allocation and the path in Body steps
