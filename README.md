# Save Tokens (Claude Code plugin)

Stretches your Claude Code Pro/Max 5-hour rate-limit window — and lowers per-session cost as a side effect — by adding threshold-prompt hooks, a live status line, a tighter output style, and a few slash commands. All suggestions, no silent auto-acts.

> **Platform:** Windows only. Every script is PowerShell. macOS/Linux users would need to port the `.ps1` files.

## What it actually does (ranked by rate-limit impact)

| Piece | Active location | What it does |
|---|---|---|
| Status line | `~/.claude/settings.json` → `scripts/statusline.ps1` | Two ribbons of live state: context fill, 5h/7d rate-limit bars, session cost, model, branch, peak/off-peak tag. Strongest single piece in the bundle. |
| Compact-suggester hook | `~/.claude/hooks/compact-suggester.ps1` | When session crosses 200K tokens, prompts Claude to suggest `/compact` in its next reply. |
| Model-suggester hook | `~/.claude/hooks/model-suggester.ps1` | On the first prompt of each session, classifies the request and suggests a model switch (Haiku / Sonnet / Opus) when the current model mismatches the task. Re-arm with `/model-rethink`. |
| Plain-terse output style | `~/.claude/output-styles/plain-terse.md` | Cuts preamble and trailing summaries; bakes in a "delegate broad searches to the Explore subagent" rule. Activate with `/output-style plain-terse`. |
| `/usage` | `~/.claude/commands/usage.md` | Token totals across the rolling 5h window, 7d window, and today, with re-read % per model. |
| `/token-rules` | `~/.claude/commands/token-rules.md` | Seven-rule cheatsheet, ranked by rate-limit impact. |
| `/curate-memory` | `~/.claude/commands/curate-memory.md` | Manual memory-file dedup; proposes changes before writing. |
| `/model-rethink` | `~/.claude/commands/model-rethink.md` | Clears the model-suggester flag so it re-fires on your next prompt. |

## Status line layout

**Line 1 (always):** model name · `[TERSE]` badge (only when plain-terse active) · context-window bar · context tokens · session cost · git branch · project.

The context bar is color-coded by fill: **green under 20%**, **yellow 20–40%**, **red 40%+**. Red means it's time to run `/compact` — re-read cost per turn climbs sharply past 200K of the 1M window. The compact-suggester hook will also nudge Claude to mention it once you cross the threshold.

**Line 2 (when data available):** 5-hour rate-limit bar · 7-day rate-limit bar · `[PEAK]` or `[OFF-PEAK]` tag.

- Rate-limit bars only appear for Pro/Max subscribers (after the first API response each session).
- Bars are green under 60%, yellow 60–85%, red 85%+.
- `[PEAK]` shows in red during US Pacific weekday 5am–11am — your morning/afternoon in Australia is usually `[OFF-PEAK]`.

## Install

Clone the repo into your Claude plugins folder, then run the installer:

```powershell
git clone https://github.com/fakkenumber1/save-tokens.git "$env:USERPROFILE\.claude\plugins\save-tokens"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\plugins\save-tokens\scripts\install.ps1"
```

The installer copies plugin source files to the global Claude Code locations (`~/.claude/output-styles`, `~/.claude/commands`, `~/.claude/hooks`). It uses mtime checks and skips files that are already up-to-date — safe to re-run any time you edit a plugin source file.

After install, edit `~/.claude/settings.json` once to wire the new hooks under `hooks.UserPromptSubmit`. Status line is set under `statusLine.command`; it's already there if you've installed before.

**Hook entries to add to `hooks.UserPromptSubmit`:**

```
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\hooks\compact-suggester.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.claude\hooks\model-suggester.ps1"
```

**Then restart Claude Code.** Output styles and hooks load at session start; edits do not hot-reload mid-session.

## Edit-and-redeploy flow

The plugin source lives in this directory. Claude Code reads from the deployed copies under `~/.claude/{output-styles,commands,hooks}/`.

To change something:
1. Edit the file inside `plugins/save-tokens/`.
2. Run `install.ps1` again — it overwrites the deployed copy.
3. Restart Claude Code if you touched an output style or hook.

**Do not edit the deployed copies directly.** The next install run will silently overwrite hand-edits.

## What it does NOT do (by design)

- No automatic model switching — the suggester asks; you confirm with `/model X`.
- No automatic `/compact` — the suggester nudges Claude to mention it; you run it.
- No auto-force of plain-terse on session start — you can switch styles when you want longer replies.
- No web dashboard, no background process, no Python dependency.
- No automatic memory curation — `/curate-memory` is manual and proposes before writing.

## Files in this bundle

- `.claude-plugin/plugin.json` — bundle identity
- `output-styles/plain-terse.md` — terse style with subagent-delegation rule
- `commands/token-rules.md` — `/token-rules` cheatsheet
- `commands/usage.md` — `/usage` wrapper
- `commands/curate-memory.md` — `/curate-memory` workflow
- `commands/model-rethink.md` — `/model-rethink` flag-clearer
- `hooks/compact-suggester.ps1` — UserPromptSubmit hook (200K threshold prompt)
- `hooks/model-suggester.ps1` — UserPromptSubmit hook (first-prompt model recommendation)
- `scripts/statusline.ps1` — status line renderer
- `scripts/pricing.ps1` — per-million pricing table (update when Anthropic changes rates)
- `scripts/usage.ps1` — JSONL parser for `/usage` (5h/7d/today rolling windows)
- `scripts/install.ps1` — idempotent deploy script
- `scripts/uninstall.ps1` — symmetric remove script
- `scripts/install-commit-mono-nf.ps1` — optional Nerd Font installer for the status-line glyph

## Uninstall

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\plugins\save-tokens\scripts\uninstall.ps1"
```

Then remove the `compact-suggester` and `model-suggester` entries from `~/.claude/settings.json` `hooks.UserPromptSubmit`. Optionally revert `statusLine.command` to your previous script and delete this directory.
