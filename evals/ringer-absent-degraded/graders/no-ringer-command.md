---
type: regex
target:
  source: file
  path: repo/drive-plan.md
pattern: "^\\s*(\\$\\s+)?[\"']?[^\\s\"']*ringer\\.py[\"']?\\s+(lint|run|models)\\b"
flags: mi
match: not_contains
---
