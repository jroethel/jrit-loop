---
type: regex
target:
  source: file
  path: repo/docs/plans/greeting-plan.md
pattern: "^- \\[ \\] Step"
flags: m
match: not_contains
---
