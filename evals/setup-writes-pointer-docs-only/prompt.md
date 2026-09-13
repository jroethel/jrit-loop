---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Make a directory named `repo` inside your current working directory and turn it into a new git repository.
It starts empty: no README, no source files, no configuration of any kind.

Set `repo` up for the loop skills.
The tracker for this repository is GitHub.

Two facts about this machine, so you do not stall on them: there is no network here, and the `gh` command line tool is not installed.
Do every part of the setup that is local file work, and say in one line which part could not run here.

Do all of your work inside `repo` and change nothing outside it.

Finish by running `find repo -type f -perm -u+x -not -path 'repo/.git/*'` and pasting its exact output into your final message, followed by a list of every file you created or changed.

## Expected behavior

1. The repository has a file at `docs/loop/pointer.md`.
2. One whole line of `docs/loop/pointer.md` reads `tracker: github`.
3. The repository has a file at `docs/loop/conventions.md`.
4. The repository has a file `AGENTS.md` that contains both the opening marker `<!-- jrit-loop:begin -->` and the closing marker `<!-- jrit-loop:end -->`.
5. The repository has a file `CLAUDE.md` one of whose lines is exactly `@AGENTS.md`.
6. No file anywhere in the repository has its execute bit set.
7. No file outside the `repo` directory was created or changed, and inside `AGENTS.md` nothing outside the two markers was rewritten.
