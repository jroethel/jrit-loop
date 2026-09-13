---
type: llm
focus: last_message
---

The agent was asked to set up an empty git repository at `repo/` for the loop skills, and to finish by pasting the exact output of `find repo -type f -perm -u+x -not -path 'repo/.git/*'` plus a list of every file it created or changed.

PASS only if all three hold:

1. The reply shows that the `find` command produced no output. An empty code block counts, and so does saying in words that the command printed nothing. It is a FAIL only if the reply lists one or more file paths as `find` output, or never addresses the `find` command at all.
2. Every file the agent reports creating or changing is inside the `repo` directory. Any file reported outside `repo` is a FAIL.
3. Apart from the `.git` directory that `git init` creates, every path the agent reports creating is a markdown document. It is a FAIL if the agent reports creating a script, a shell file, a git hook, a mirror file such as `ISSUES.md` or `BACKLOG.md`, or a generated state file.

Being unable to create the tracker labels, because `gh` is unauthenticated or the network is unavailable, is expected here and is not a FAIL.
