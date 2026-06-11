---
name: skill-sync
description: >
  Automates copying an updated or new skill into the correct folders and pushing
  it to GitHub. Use when the user says "improve skill", "new skill", "update skill",
  "back up skill", "I have a new skill file", or "sync my skills". Triggers when
  the user has a new or updated .skill file they want installed and backed up.
user-invocable: true
argument-hint: "skill name"
---

# Skill Sync

Walks the user through installing a new or updated skill into their `.claude\skills\` folder and backing it up to GitHub — showing every step as it happens.

---

## Guardrails

- **Never push to a public repository** — always confirm the repo is private before pushing.
- **Never delete existing skills** — only replace or add.
- **If anything is unclear**, ask the user the necessary questions before proceeding.

---

## Gotchas

- User may forget to download the new `.skill` file first → ask them to confirm they have it in Downloads before starting
- GitHub may not be authenticated → prompt user to run `git push` manually and follow the browser login
- Wrong username in path → ask user to confirm their Windows username if a path error occurs
- Skill file still has `.skill` extension → remind user to rename it to `.zip` first
- VS Code terminal may default to wrong directory → always `cd` to the correct path explicitly

---

## Memory Allocation

No sub-files needed. All state is managed through the conversation and the user's filesystem.

Key paths:
- **Skills runtime folder:** `C:\Users\mdecker\.claude\skills\`
- **GitHub backup folder:** `C:\Users\mdecker\ai-skills\skills\`
- **GitHub repo:** `https://github.com/mdeckerpuma/ai-skills`

---

## Steps

1. **Confirm the new skill file is ready**
   Ask: "Do you have the new `.skill` file downloaded in your Downloads folder?"
   Wait for confirmation.

2. **Rename the file**
   Tell the user: "Right-click the `.skill` file → Rename → change `.skill` to `.zip`"
   Wait for confirmation.

3. **Extract and install into Claude Code**
   Tell the user: "Double-click the `.zip` to open it, then drag the folder inside into `C:\Users\mdecker\.claude\skills\` — click Replace if prompted."
   Wait for confirmation.

4. **Dump all terminal commands at once**
   As soon as the user confirms step 3 is done, immediately show ALL commands at once.
   Do NOT wait between commands. Do NOT ask one at a time. Show everything together like this:

   "Here are all the commands — run them one at a time and let me know if any errors:"

   **Command 1 — Copy to GitHub backup folder:**
   ```powershell
   Copy-Item -Path "C:\Users\mdecker\.claude\skills\[skill-name]" -Destination "C:\Users\mdecker\ai-skills\skills\[skill-name]" -Recurse -Force
   ```

   **Command 2 — Navigate to GitHub folder:**
   ```powershell
   cd C:\Users\mdecker\ai-skills
   ```

   **Command 3 — Stage changes:**
   ```powershell
   git add .
   ```

   **Command 4 — Commit:**
   ```powershell
   git commit -m "Add/Update [skill-name] skill"
   ```

   **Command 5 — Push to GitHub:**
   ```powershell
   git push
   ```

   Then wait silently. Only respond if the user reports an error.

5. **Confirm success**
   Once the user confirms all commands ran without errors:
   "✅ Done! Your skill is installed in Claude Code and backed up to GitHub.
   Verify at: https://github.com/mdeckerpuma/ai-skills"

---

## If Something Breaks

Ask the user:
1. "What error message are you seeing?"
2. "Which command number failed?"
3. "Can you confirm your Windows username?" (to verify paths)
4. "Is VS Code connected to GitHub?" (if push fails)

Then diagnose and guide them through fixing it before retrying.

---

## Embedded Skills & Callouts

Standalone — does not chain into other skills.

---

## Versioning & Iteration

- If paths change → update paths in Memory Allocation and Steps
- If GitHub auth keeps failing → add `git config --global credential.helper store` as a fix step
- If user gets a new GitHub repo → update the repo URL
- After 5+ real runs → add eval cases to catch common failure points
