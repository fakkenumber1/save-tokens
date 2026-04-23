---
description: Show the rate-limit-saving cheatsheet for Claude Code on Pro/Max.
---

Print the cheatsheet below verbatim. No commentary before or after. No paraphrasing. No summary. Output exactly as written.

---

# Stretch your Claude Code rate limit

Pro/Max gives you a flat fee — but caps how much Claude you can run inside each rolling 5-hour and 7-day window. These rules stretch that window so you hit "limit reached" later. They're ranked by impact.

**1. Pick the smallest model that does the job.**
Haiku costs roughly 5–15% of Opus per token, Sonnet roughly 20–25%. The plugin's model-suggester prompts you on the first message of each session — accept its suggestion when reasonable. You can also switch by hand: `/model haiku` for tiny jobs (rename, format, list), `/model sonnet` for normal coding work, `/model opus` only for hard debugging or architecture. Run `/model-rethink` to re-trigger the suggester mid-session when you start a new sub-task.

**2. Delegate big searches to subagents.**
When Claude searches across many files, every `Grep` and `Read` result lands in the conversation history and gets re-read every future turn. Telling Claude to "use the Explore subagent" — or letting the plain-terse style auto-delegate — keeps those tool results out of the main context. Single biggest lever after model picking.

**3. Run /compact when the context bar turns red.**
The status bar's CTX bar goes red around 200K tokens. Past that, every turn re-reads more history than it adds, and rate-limit consumption climbs sharply. Run `/compact` to summarize the conversation and drop the raw history. The plugin's compact-suggester will nudge Claude to mention it once you cross the threshold.

**4. Batch questions into one prompt.**
Three separate prompts = three full re-reads of the conversation history. One prompt with three asks = one re-read. Cheaper, and the answers are usually better because Claude sees the full picture at once.

**5. Edit your last message instead of sending corrections.**
Press Escape twice in Claude Code to backtrack and rewrite. Each correction reply you send adds to the history that gets re-read every future turn. Editing prevents that accumulation entirely.

**6. Work off-peak.**
US Pacific weekday mornings are peak hours and chew through the rate limit faster for the same query. Your evenings and weekends in Australia usually fall outside that window. Check Anthropic's pricing page for the current peak schedule — it shifts. The status bar shows a `peak` / `off-peak` tag.

**7. Track your rolling windows.**
Run `/usage` to see current 5-hour window, 7-day window, and today's totals — plus re-read share per model. The status bar shows live cost and rate-limit bars (5H, 7D) when you're on Pro/Max.

---

**Terse mode:** `/output-style plain-terse` for short replies (and to enable the auto-delegate-to-subagent rule). `/output-style careful` for longer/explanatory.
