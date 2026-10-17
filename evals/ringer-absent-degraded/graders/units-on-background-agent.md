---
type: regex
target:
  source: file
  path: repo/drive-plan.md
pattern: "^\\|[^|\\n]*\\|\\s*W?\\d+\\s*\\|[^|\\n]*\\|[^|\\n]*\\|\\s*`?background[- ]agent(?![\\w-])[^|\\n]*\\|"
flags: mi
match: contains
---
