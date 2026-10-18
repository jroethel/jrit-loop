---
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Make a directory named `repo` inside your current working directory, turn it into a new git repository, and work only inside it.

Then run this command, exactly as written, so the repository is set up for the loop skills.

```bash
mkdir -p repo/docs/loop && printf 'pointer-version: 1\ntracker: local\nlocal-issues-file: docs/issues.md\n' > repo/docs/loop/pointer.md && printf '# Issues\n\nNone open.\n' > repo/docs/issues.md
```

Brainstorm this idea with me and write the brief to `repo/docs/brief.md`.

> **Idea: a reading log.** I want a plain-text log of the articles I read, one line per article with the date, the title, and the link, so I can find something I read last month.

I am not available for questions during this run, so here are my answers up front; treat every one as settled and do not wait for me:

- The outcome is finding an article I read within ten seconds by searching one file.
- Done means a `log.txt` file in the repository with one line per article, and a search for any word in a title finds it.
- It is just for me, on one machine, for now.
- Pick the approach you recommend; I approve the brief as you write it, and I do not want a commit.

## Expected behavior

1. A brief is written to `docs/brief.md` inside the repository.
2. The brief has a North star and invariants section stating the maximal end state and at least one invariant that names the parked future it protects.
3. The brief has a Parking lot section holding the futures the sweep found, and Done looks like stays limited to the plain-text log.
