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
- **Never skip confirmation** — always show the user what's about to happen before doing it.
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

Key paths to remember:
- **Skills runtime folder:** `C:\Users\mdecker\.claude\skills\`
- **GitHub backup folder:** `C:\Users\mdecker\ai-skills\skills\`
- **GitHub repo:** `https://github.com/mdeckerpuma/ai-skills`

---

## Steps

1. **Confirm the new skill file is ready**
   Ask the user:
   > "Do you have the new `.skill` file downloaded? It should be in your Downloads folder."
   Wait for confirmation before continuing.

2. **Rename the file**
   Tell the user:
   > "Right-click the `.skill` file → Rename → change the extension from `.skill` to `.zip`"
   Wait for confirmation.

3. **Extract and install into Claude Code**
   Tell the user:
   > "Double-click the `.zip` file to open it, then drag the folder inside into:
   > `C:\Users\mdecker\.claude\skills\`
   > If a folder with the same name already exists, replace it."
   Wait for confirmation.

4. **Copy to GitHub backup folder**
   Run this command in the VS Code terminal and show the user what's happening:
   ```powershell
   Copy-Item -Path "C:\Users\mdecker\.claude\skills\[skill-name]" -Destination "C:\Users\mdecker\ai-skills\skills\[skill-name]" -Recurse -Force
   ```
   Tell the user: "Copying your skill to the GitHub backup folder..."
   Confirm the copy succeeded before moving on.

5. **Navigate to the GitHub folder**
   ```powershell
   cd C:\Users\mdecker\ai-skills
   ```
   Tell the user: "Navigating to your GitHub folder..."

6. **Stage the changes**
   ```powershell
   git add .
   ```
   Tell the user: "Staging your changes..."

7. **Commit with a descriptive message**
   ```powershell
   git commit -m "Update [skill-name] skill"
   ```
   Tell the user: "Committing your changes..."

8. **Push to GitHub**
   ```powershell
   git push
   ```
   Tell the user: "Pushing to GitHub..."

9. **Confirm success**
   Once all steps complete, tell the user:
   > "✅ Done! Your skill is installed in Claude Code and backed up to GitHub.
   > You can verify at: https://github.com/mdeckerpuma/ai-skills"

---

## If Something Breaks

If any step fails, ask the user:
1. "What error message are you seeing?"
2. "Which step did it fail on?"
3. "Can you confirm your Windows username?" (to verify paths)
4. "Is VS Code connected to GitHub?" (if push fails)

Then diagnose and guide them through fixing it before retrying.

---

## Embedded Skills & Callouts

Standalone — does not chain into other skills.

---

## Versioning & Iteration

- If paths change (new computer, new username) → update the paths in the Steps section
- If GitHub authentication keeps failing → add a step to run `git config --global credential.helper store`
- If the user gets a new GitHub repo → update the repo URL in Memory Allocation
- After 5+ real runs → add eval cases to catch common failure points
