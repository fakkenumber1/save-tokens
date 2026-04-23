---
description: Show Claude Code token totals across the rolling 5h window, 7d window, and today (per model, with re-read share).
allowed-tools: Bash(powershell*)
---

Run the following PowerShell script and show its output to the user verbatim. Do not add preamble, commentary, analysis, or paraphrasing. Output exactly what the script produces.

Command:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\plugins\save-tokens\scripts\usage.ps1"
```
