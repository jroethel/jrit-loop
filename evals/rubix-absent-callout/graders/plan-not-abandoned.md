---
type: regex
target:
  source: file
  path: repo/docs/plan.md
pattern: "(rubix|review skill)[^\\n]*(?<!\\bnot )\\b(deferred|blocked|abandoned|on hold)\\b"
flags: i
match: not_contains
---
