---
description: Re-arm the model-suggester hook so it fires on your next prompt (useful when starting a new sub-task in the same session).
allowed-tools: Bash(powershell*)
---

Run the following PowerShell command to clear all save-tokens model-suggester flag files. After it completes, tell the user verbatim: "Model suggester re-armed. It will fire on your next prompt."

Command:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem $env:TEMP -Filter 'save-tokens-model-fired-*.flag' -ErrorAction SilentlyContinue | Remove-Item -Force"
```
