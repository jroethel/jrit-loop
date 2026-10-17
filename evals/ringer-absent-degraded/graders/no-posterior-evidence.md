---
type: regex
target:
  source: file
  path: repo/drive-plan.md
pattern: "^\\|[^|\\n]*\\|\\s*W?\\d+\\s*\\|.*\\|\\s*`?(ringer|posterior)[^|\\n]*\\|\\s*$"
flags: mi
match: not_contains
---
