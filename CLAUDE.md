# Context: Skills Workspace

## Who I Am
Matthew Decker — options trader, software developer, building a personal Claude Code
skill ecosystem. See global CLAUDE.md for full profile.

## Active Skills & Output Paths

| Skill | Output Path |
|-------|-------------|
| journal | skills/journal/outputs/{daily,weekly,sessions,metrics}/ |
| options-coach | skills/options-coach/outputs/{scenarios,notes}/ |
| docx | skills/docx/outputs/ |
| xlsx | skills/xlsx/outputs/ |
| macro-tracker | skills/macro-tracker/outputs/ |
| skill-sync | skills/skill-sync/outputs/ |
| frontend-design | skills/frontend-design/outputs/ |
| build-doc | skills/build-doc/outputs/{htmls,docx,pptx,xlsx}/ |
| interview | skills/interview/outputs/ |
| skill-builder | skills/skill-builder/outputs/ |
| vault | skills/vault/outputs/ |
| website model/app-interviewer | skills/website model/app-interviewer/outputs/ |
| website model/app-architect | skills/website model/app-architect/outputs/ |
| website model/crud-builder | skills/website model/crud-builder/outputs/ |
| website model/app-deployer | skills/website model/app-deployer/outputs/ |
| website model/auth-integrator | skills/website model/auth-integrator/outputs/ |
| website model/dashboard-builder | skills/website model/dashboard-builder/outputs/ |
| website model/form-builder | skills/website model/form-builder/outputs/ |
| website model/app-iterator | skills/website model/app-iterator/outputs/ |

## HTML Output Rule
Primary: `C:\htmls\[name].html`
Archive: `C:\Users\mdecker\.claude\skills\Builds\htmls\[name].html`
Both paths mandatory on every HTML build.

## Website Model Stack
All website-model skills live in: `skills/website model/`
Build order: app-interviewer ✓ → app-architect ✓ → crud-builder ✓ → app-deployer ✓ → auth-integrator ✓ → dashboard-builder ✓ → form-builder ✓ → app-iterator ✓

## Standing Rules
- HTML builds always interactive (tabs, counters, accordions, search — at minimum sticky nav + 1 interaction)
- Research sourcing: must include 2025/2026 sources
- New skills: /interview → /skill-builder → write to website model/ folder
- Responses: terse, no trailing summaries
