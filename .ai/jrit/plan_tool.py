#!/usr/bin/env python3
"""Chain kit plan tool: find the branch plan, gate its structure, run its
acceptance checks, and enforce its ownership lists.

Stdlib only, deterministic, run from the repo root. Exit 0 = clean.
The plan parser is plan_lint.py beside this file (a byte-identical copy of
jrit-loop's), so check rejects what the lint rejects.

An ownership span written path:lines (loop-plan's own task template writes
path:123-145) owns the path. run-checks reruns a failing check at its task's
own commit when a base is known; a pass there is reported MOVED, not FAIL, and
recorded in the git-dir file jrit-chain-moved (one "<id> <sha12>" per line).
run-checks --task <id> runs that one check, with no MOVED rerun and no record.
"""
import argparse
import fnmatch
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.dont_write_bytecode = True  # no __pycache__ in .ai/jrit/ or the template kit
import plan_lint
from plan_lint import analyze, human_ids, structure_problems, MARKER

SPAN_RE = re.compile(r"`([^`\n]+)`")
LINES_RE = re.compile(r":\d[\d,-]*$")
BASE_KEY = "jrit-chain-base"
MOVED_KEY = "jrit-chain-moved"
NO_BASE_MSG = "no base: pass --base or run preflight first"
NEVER_OWNED_MSG = "(the chain kit and docs/loop/ are never plan-owned)"


def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def git_out(args):
    r = subprocess.run(["git"] + args, capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write(r.stderr)
        sys.exit(1)
    return r.stdout


def merge_base(ref):
    r = subprocess.run(["git", "merge-base", "HEAD", ref],
                       capture_output=True, text=True)
    if r.returncode != 0:
        sys.stderr.write(r.stderr)
        sys.exit(1)
    return r.stdout.strip()


def recorded_base():
    """The ref preflight wrote into the git dir, or None."""
    path = git_out(["rev-parse", "--git-path", BASE_KEY]).strip()
    if not os.path.isabs(path):
        path = os.path.join(os.getcwd(), path)
    if not os.path.isfile(path):
        return None
    return read_file(path).strip() or None


def create_only(task):
    bullets = task["bullets"]
    return bool(bullets) and all(
        re.match(r"^\s*-\s*Create\b", b) for b in bullets)


def run_at_base(command, mb):
    """Run a command in a throwaway worktree at mb; None on timeout."""
    worktree_seq = run_at_base.seq = getattr(run_at_base, "seq", 0) + 1
    path = os.path.join(os.environ.get("TMPDIR", "/tmp"),
                        "jrit-plan-tool-{}-{}".format(os.getpid(), worktree_seq))
    git_out(["worktree", "add", "--detach", path, mb])
    try:
        try:
            p = subprocess.run(["bash", "-c", command], cwd=path,
                               capture_output=True, text=True, timeout=300)
            return p.returncode
        except subprocess.TimeoutExpired:
            return None
    finally:
        subprocess.run(["git", "worktree", "remove", "--force", path],
                       capture_output=True, text=True)


def pointer_home(key, default):
    path = os.path.join("docs", "loop", "pointer.md")
    if os.path.isfile(path):
        for line in read_file(path).splitlines():
            m = re.match(r"^{}:\s*(\S+)".format(re.escape(key)), line)
            if m:
                return m.group(1)
    return default


def owned_path(span, top):
    """The repo-relative path an ownership span owns, or None."""
    if " " in span:
        return None
    if span.startswith(top + "/"):
        span = span[len(top) + 1:]
    elif span[:1] in ("/", "~", "$"):
        return None
    return LINES_RE.sub("", span)


def own_commit(task, mb):
    """Newest first-parent commit after mb touching a path the task owns."""
    top = git_out(["rev-parse", "--show-toplevel"]).strip()
    paths = [owned_path(span, top) for bullet in task["bullets"]
             for span in SPAN_RE.findall(bullet)]
    paths = [p for p in paths if p]
    if not paths:
        return None
    out = git_out(["log", "--first-parent", "--format=%H", "-1",
                   "{}..HEAD".format(mb), "--"] + paths)
    return out.strip() or None


def allowed(path, entry):
    if entry.endswith("/"):
        return path == entry[:-1] or path.startswith(entry)
    if any(c in entry for c in "*?["):
        return fnmatch.fnmatch(path, entry)
    return path == entry


def cmd_find_plan(args):
    base = args.base or recorded_base()
    if not base:
        print(NO_BASE_MSG)
        return 1
    mb = merge_base(base)
    out = git_out(["log", "--format=", "--name-only", "--diff-filter=A",
                   "{}..HEAD".format(mb), "--", "docs/plans/*-plan.md"])
    for line in out.splitlines():
        line = line.strip()
        if (line.startswith("docs/plans/") and line.endswith("-plan.md")
                and not line.endswith("_loop.md")):
            print(line)
            return 0
    print("no plan added on this branch since {} (merge base {})".format(
        base, mb[:12]))
    return 1


def cmd_check(args):
    text = read_file(args.plan)
    lines, inside, tasks = analyze(text)
    problems = ["plan gate: {}".format(p) for p in structure_problems(tasks)]
    problems += ["plan gate: lint: {}".format(p)
                 for p in plan_lint.lint_problems(text)]
    base = args.base or recorded_base()
    if not base:
        print("note: no base, merge-base checks skipped")
    if not problems and base:
        mb = merge_base(base)
        for t in tasks:
            if not create_only(t) or not t["command"]:
                continue
            if run_at_base(t["command"], mb) == 0:
                problems.append(
                    "plan gate: Task {}: acceptance check passes before "
                    "the task's files exist (at {}): {}".format(
                        t["id"], mb[:12], t["command"]))
    for p in problems:
        print(p)
    if problems:
        return 1
    print("ok: {} tasks".format(len(tasks)))
    return 0


def run_check(command):
    """(exit code, or None on a timeout; the check's combined output)."""
    try:
        p = subprocess.run(["bash", "-c", command or ""],
                           capture_output=True, text=True, timeout=1800)
    except subprocess.TimeoutExpired:
        return None, ""
    code = p.returncode if p.returncode >= 0 else 128 - p.returncode
    return code, p.stdout + p.stderr


def report(tid, code, output):
    if code == 0:
        print("PASS task {}".format(tid))
    elif code is None:
        print("FAIL task {}: timed out after 1800 s".format(tid))
    else:
        print("FAIL task {}: exit {}".format(tid, code))
    for line in output.splitlines()[-40:]:
        print("  {}".format(line))


def cmd_run_checks(args):
    lines, inside, tasks = analyze(read_file(args.plan))
    if args.task is not None:
        t = next((t for t in tasks if t["id"] == args.task), None)
        if t is None:
            print("no Task {}".format(args.task))
            return 2
        code, output = run_check(t["command"])
        report(t["id"], code, output)
        return 0 if code == 0 else 1
    humans = set(human_ids(lines, inside))
    base = args.base or recorded_base()
    mb = merge_base(base) if base else None
    moved = []
    ran = failed = 0
    for t in tasks:
        if t["id"] in humans:
            print("SKIP task {}: human".format(t["id"]))
            continue
        ran += 1
        code, output = run_check(t["command"])
        if code not in (0, None):
            sha = own_commit(t, mb) if mb else None
            if sha and run_at_base(t["command"] or "", sha) == 0:
                moved.append("{} {}".format(t["id"], sha[:12]))
                print("MOVED task {}: fails on the finished tree, passes "
                      "at its own commit {}".format(t["id"], sha[:12]))
                continue
        if code != 0:
            failed += 1
        report(t["id"], code, output)
    path = git_out(["rev-parse", "--git-path", MOVED_KEY]).strip()
    with open(path, "w", encoding="utf-8") as f:
        f.write("".join(m + "\n" for m in moved))
    if failed:
        print("drive gate: {} of {} acceptance checks failed".format(failed, ran))
        return 1
    return 0


def cmd_human_tasks(args):
    lines, inside, _ = analyze(read_file(args.plan))
    for tid in human_ids(lines, inside):
        print(tid)
    return 0


def cmd_ownership(args):
    base = args.base or recorded_base()
    if not base:
        print(NO_BASE_MSG)
        return 1
    mb = merge_base(base)
    changed = [l.strip() for l in
               git_out(["diff", "--name-only", "{}...HEAD".format(mb)]).splitlines()
               if l.strip()]
    text = read_file(args.plan)
    _, _, tasks = analyze(text)
    lines = text.split("\n")
    written = {p for _, p, _, _ in
               plan_lint.blocks(lines, plan_lint.fence_map(lines))}
    top = git_out(["rev-parse", "--show-toplevel"]).strip()
    entries = ["docs/plans/",
               pointer_home("reviews-home", "docs/reviews/"),
               pointer_home("handoffs-home", "docs/handoffs/")]
    for t in tasks:
        for bullet in t["bullets"]:
            for span in SPAN_RE.findall(bullet):
                entry = owned_path(span, top)
                if entry:
                    entries.append(entry)
    outside = 0
    for path in changed:
        if path.startswith(".ai/") or path.startswith("docs/loop/"):
            print("outside ownership: {} {}".format(path, NEVER_OWNED_MSG))
            outside += 1
        elif path not in written and not any(allowed(path, e) for e in entries):
            print("outside ownership: {}".format(path))
            outside += 1
    if outside:
        return 1
    print("ok: {} changed files inside ownership".format(len(changed)))
    return 0


def main(argv):
    ap = argparse.ArgumentParser(
        description="Find, check, run, and enforce a jrit chain plan.")
    sub = ap.add_subparsers(dest="command", required=True)

    p = sub.add_parser("find-plan", help="newest plan added on this branch")
    p.add_argument("--base")
    p.set_defaults(func=cmd_find_plan)

    p = sub.add_parser("check", help="gate the plan's structure")
    p.add_argument("plan")
    p.add_argument("--base")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("run-checks", help="run every acceptance check")
    p.add_argument("plan")
    p.add_argument("--base")
    p.add_argument("--task", help="run this task's check only, no MOVED rerun")
    p.set_defaults(func=cmd_run_checks)

    p = sub.add_parser("human-tasks", help="ids of human-shaped tasks")
    p.add_argument("plan")
    p.set_defaults(func=cmd_human_tasks)

    p = sub.add_parser("ownership", help="diff the branch against the lists")
    p.add_argument("plan")
    p.add_argument("--base")
    p.set_defaults(func=cmd_ownership)

    args = ap.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
