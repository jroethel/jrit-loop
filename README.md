# jrit-loop

jrit-loop is a Claude Code plugin of ten prose skills for driving multi-step work through your repo's own issue tracker.
A raw idea goes in one end, and brainstorming, planning, execution, review, and tracking come out the other as ordinary files and tracker issues you already know how to read.

## Install

<!-- jrit-loop-version: 0.1.0 -->

From a Claude Code marketplace:

```
/plugin marketplace add jroethel/jrit-loop
/plugin install jrit-loop@jrit-loop
```

Or with the `skills` CLI:

```
npx skills@1.5.26 add jroethel/jrit-loop
```

## The ten skills

| Skill           | What it does                                                                                              |
| --------------- | --------------------------------------------------------------------------------------------------------- |
| loop-brainstorm | Shape a raw idea or feature request into a vetted brief before any plan exists.                           |
| loop-plan       | Turn an approved brief or spec into an executor-agnostic implementation plan broken into tasks.           |
| loop-drive      | Orchestrate a plan's execution step by step, routing each task to a capable worker session.               |
| loop-review     | Run a two-axis review, spec and standards, of the work since a fixed point you name.                      |
| loop-improve    | Audit the repo and its tracker lanes, then converge the worthwhile findings into one brief.               |
| loop-track      | Keep the repo's own issue tracker as the execution ledger for loop-driven work.                           |
| loop-auto       | Set or check the chain autonomy knob and apply the four gate classes for autonomous runs.                 |
| loop-setup      | Initialize a repo with the config and tracker layout the loop skills expect.                              |
| wayfinder       | Reorient in an unfamiliar repo by building a map of where durable context lives.                          |
| handoff         | Package current session state into a resume point another session can pick up cold.                       |

## Requirements

GitHub repos need the `gh` CLI installed and authenticated, and GitLab repos need the `glab` CLI installed and authenticated.
GitLab mode additionally requires `jq` on your PATH.

## Contributing: the portability doctrine

The skills are prose first: prose and the tracker are the source of truth, and anything an agent must do is written so a capable agent can do it without a special runtime.
Every file a skill references resolves inside that skill's own directory.
`${CLAUDE_PLUGIN_ROOT}` appears in no skill body; skills never lean on a plugin-root variable that another engine may not set.
Frontmatter context fields are optimization hints, and any behaviour they trigger is also stated in prose so nothing is lost when they are ignored.
Structure checks stay engine-neutral bash, runnable anywhere without a specific harness installed.
