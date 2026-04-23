---
description: Smart-curate ~/.claude memory files — dedup overlapping entries and flag stale dated ones. Proposes changes; waits for approval before writing.
allowed-tools: Read, Write, Edit, Glob, Bash(powershell*)
---

You are curating Johann's long-term memory. Be conservative — memory that feels borderline should stay. Johann approves each change before you write anything.

Memory lives under `%USERPROFILE%\.claude\projects\<project-slug>\memory\` (the project slug mirrors the working-directory path with separators replaced by `-`).

## Step 1 — survey

1. Read `MEMORY.md` (the index).
2. Glob every `.md` file in that directory.
3. Cross-check: entries referenced in `MEMORY.md` that don't map to a file, and files not listed in `MEMORY.md`.

## Step 2 — analyze

Identify candidates without editing yet:

**Merge candidates — overlapping entries covering the same ground.** Propose a single merged entry preserving every fact from both sources. If the overlap is only partial, prefer leaving them separate.

**Prune candidates — stale dated entries.** Use all three heuristics:
- Debugging-session memories older than 60 days whose described fix already lives in the code. The fix is authoritative; the memory is historical noise.
- "As of YYYY-MM-DD" facts where the date is older than 90 days and the fact could plausibly have changed.
- References to file paths or resources that no longer exist (verify with Glob or Read before flagging).

Do NOT flag for pruning:
- `user` type memories (profile, role, preferences) — these age slowly.
- `feedback` type memories — the rule/why/how-to-apply structure is load-bearing.
- `reference` type memories — they point at external systems that outlive sessions.
- Any `project` memory still describing active work.

## Step 3 — propose (plain English, no diffs)

Report to Johann:
- File count before → after
- Each merge: the two source titles, the reason they overlap, and the merged summary in one sentence
- Each prune: the title, its date, and why it's stale in one sentence
- Any `MEMORY.md` index mismatches found

Do not touch any file yet. Wait for explicit approval.

## Step 4 — apply on approval

Once Johann approves (in whole or part):
- Write merged files and delete the superseded originals.
- Delete pruned files.
- Update `MEMORY.md` so the index matches the new state.
- Report what was actually written so Johann can spot-check.

If Johann says "only some of these," apply exactly the ones he names and leave the rest untouched.
