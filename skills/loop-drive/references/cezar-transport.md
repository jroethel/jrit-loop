# Cezar probe and the in-task stop

This file holds loop-drive's cezar probe and the rule for a session that is itself running inside a cezar task.
Nothing here applies unless the probe below is Present; everywhere else loop-drive behaves exactly as it does without this reference.

## Probe

Run `[ -n "${CEZ_TASK_ID:-}" ] && curl -sf "${CEZ_API_URL:-http://127.0.0.1:9}/api/v1/health" >/dev/null`; exit 0 is Present.
Present means this session is itself a cezar task with a reachable cockpit, and the next section says what this skill does inside it.
Any other exit is Absent, and routing is unchanged.

## Inside a cezar task

Present means the chain owns the drive stage: it compiles the committed plan into a drive graph with the kit's compile step and starts it; this skill dispatches nothing here.
Print one line, "running inside a cezar task; the chain's compile step owns the drive stage; stopping", and stop.
