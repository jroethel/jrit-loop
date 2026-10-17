---
type: regex
target:
  source: file
  path: repo/drive-plan.md
pattern: "^\\|[^|\\n]*\\|\\s*W?\\d+\\s*\\|[^|\\n]*\\|[^|\\n]*\\|\\s*`?ringer\\b"
flags: mi
match: not_contains
---
