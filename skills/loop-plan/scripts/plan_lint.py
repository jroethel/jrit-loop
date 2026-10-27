"""plan_lint.py: the one parser and linter of the loop-plan plan format.

Stdlib only, deterministic. Run as python3 plan_lint.py <verb> <plan>, or
import its functions from a directory copy. Fenced code blocks never count as
plan structure; a fence whose info string carries path=<p> is a test block.

Verbs: check, lint, units --json, tests --out <dir>, run-table, human-tasks.
check and lint print "plan_lint <sha12 of this file>" first, so a plan
accepted by one copy and rejected by another shows which copy ran.
"""
import argparse
import hashlib
import json
import os
import re
import sys

TASK_RE = re.compile(r"^(#{2,3}) Task (\d+[a-z]?):\s*(.+)$")
HEADING_RE = re.compile(r"^(#{1,6})\s")
FENCE_RE = re.compile(r"^(`{3,}|~{3,})")
DEPENDS_RE = re.compile(r"^Depends on:\s*(.+)$")
ACCEPT_RE = re.compile(r"^\*\*Acceptance check:\*\*(.*)$")
BULLET_RE = re.compile(r"^\s*- ")
SPAN_RE = re.compile(r"`([^`\n]+)`")
RUNSHAPE_RE = re.compile(r"^##\s+Run shape\s*$")
TASK_CELL_RE = re.compile(r"^(?:Task\s+|T)(\d+[a-z]?)(?:\s|$)")
DEP_ID_RE = re.compile(r"Task\s+(\d+[a-z]?)")
UNFAILABLE_TAIL_RE = re.compile(r"(\|\||;)\s*(true|:|exit(\s+0)?)\s*$")
SEGMENT_RE = re.compile(r"&&|\|\||;|\||\n")
FILES_HEADER = "**Files (exclusive ownership):**"
EDGE_HEADER = "**Edge inputs:**"
LINES_RE = re.compile(r":\d[\d,-]*$")
SHAPE_RE = re.compile(r"^Shape:\s*(.*)$")
TYPE_RE = re.compile(r"^Type:\s*(.*)$")
MODEL_RE = re.compile(r"^Model:\s*(.*)$")
DECISIONS_RE = re.compile(r"^Decisions:\s*(.*)$")
REPO_RE = re.compile(r"^Repo:\s*([A-Za-z0-9._-]+)")
KIND_RE = re.compile(r"^\s*-\s*(Create|Modify|Test)\b")
MODE_RE = re.compile(r"\bmode=(\S+)")
CODE_SPAN_RE = re.compile(r"(`+)(?!`).*?(?<!`)\1(?!`)")
DECISION_LOG_RE = re.compile(r"^##\s+Decision log\s*$")
SHARED_RE = re.compile(r"^##\s+Shared tests\s*$")
SHARED_ENTRY_RE = re.compile(r"^###\s+Shared test:\s*`?([^`\s]+)`?\s*$")

MARKER = "[executed-check]"
TYPES = {"code-feature", "code-fix", "code-review", "test-hardening", "docs",
         "research", "probe", "data-pipeline", "format-conversion"}
PLACEHOLDERS = ("TBD", "TODO", "implement later", "fill in details",
                "Add appropriate error handling", "handle edge cases",
                "Similar to Task")
TEST_FENCE_RE = re.compile(r"^(`{3,}|~{3,})\S*\s+.*\bpath=(\S+)")
TEST_ROOTS = ("tests/", "test/", "spec/")
AUTO_WHY = "executed check, disjoint files"


def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def fence_map(lines):
    """inside[i] is True when lines[i] sits inside a fenced code block."""
    inside = [False] * len(lines)
    char, count = "", 0
    for i, line in enumerate(lines):
        if char:
            if re.fullmatch(re.escape(char) + "{%d,}[ \t]*" % count, line):
                char = ""
            else:
                inside[i] = True
        else:
            m = FENCE_RE.match(line)
            if m:
                char, count = m.group(1)[0], len(m.group(1))
    return inside


def parse_tasks(lines, inside):
    """Every task heading outside fences, with its section extent."""
    tasks = []
    for i, line in enumerate(lines):
        if inside[i]:
            continue
        m = TASK_RE.match(line)
        if not m:
            continue
        level = len(m.group(1))
        end = len(lines)
        for j in range(i + 1, len(lines)):
            if inside[j]:
                continue
            h = HEADING_RE.match(lines[j])
            if TASK_RE.match(lines[j]) or (h and len(h.group(1)) <= level):
                end = j
                break
        tasks.append({"id": m.group(2), "start": i, "end": end})
    return tasks


def analyze(text):
    """Parse a plan into tasks carrying every field of the plan format."""
    lines = text.split("\n")
    inside = fence_map(lines)
    tasks = parse_tasks(lines, inside)
    for t in tasks:
        t["title"] = TASK_RE.match(lines[t["start"]]).group(3).strip()
        t["depends"] = None
        t["acceptance"] = None
        raw = {"shape": None, "type": None, "model": None, "decisions": None,
               "repo": None}
        acc_idx = None
        for j in range(t["start"] + 1, t["end"]):
            if inside[j]:
                continue
            m = DEPENDS_RE.match(lines[j])
            if m and t["depends"] is None:
                t["depends"] = m.group(1)
            m = ACCEPT_RE.match(lines[j])
            if m and t["acceptance"] is None:
                t["acceptance"] = m.group(1)
                acc_idx = j
            for key, rx in (("shape", SHAPE_RE), ("type", TYPE_RE),
                            ("model", MODEL_RE), ("decisions", DECISIONS_RE),
                            ("repo", REPO_RE)):
                m = rx.match(lines[j])
                if m and raw[key] is None:
                    raw[key] = m.group(1).strip()
        t["command"] = (extract_command(lines, inside, acc_idx,
                                        t["acceptance"], t["end"])
                        if acc_idx is not None else None)
        t["bullets"] = file_bullets(lines, inside, t)
        t["dep_ids"] = ([] if t["depends"] is None
                        or t["depends"].strip() == "none"
                        else DEP_ID_RE.findall(t["depends"]))
        t["shape_raw"] = raw["shape"]
        t["shape"], t["shape_why"] = None, None
        if raw["shape"] == "auto":
            t["shape"] = "auto"
        elif raw["shape"] is not None:
            m = re.match(r"^human(?:,\s*(.*))?$", raw["shape"])
            if m:
                t["shape"] = "human"
                t["shape_why"] = (m.group(1) or "").strip() or None
        t["type"] = raw["type"]
        t["model"] = raw["model"]
        t["decisions_raw"] = raw["decisions"]
        t["decisions"] = ([] if raw["decisions"] in (None, "none") else
                          [d.strip() for d in raw["decisions"].split(",")
                           if d.strip()])
        t["repo"] = raw["repo"]
        t["edge_raw"], t["edge_inputs"] = edge_inputs(lines, inside, t)
    return lines, inside, tasks


def extract_command(lines, inside, acc_idx, rest, end):
    """First backtick span other than the marker, else the next fence body."""
    if rest is not None:
        for span in SPAN_RE.findall(rest):
            if span != MARKER:
                return span
    for j in range(acc_idx + 1, end):
        if not inside[j] and FENCE_RE.match(lines[j]):
            body = []
            k = j + 1
            while k < end and inside[k]:
                body.append(lines[k])
                k += 1
            return "\n".join(body)
    return None


def file_bullets(lines, inside, task):
    """Bullet lines directly after the Files header, inside the section."""
    for j in range(task["start"] + 1, task["end"]):
        if inside[j]:
            continue
        if FILES_HEADER not in lines[j]:
            continue
        bullets = []
        for k in range(j + 1, task["end"]):
            line = lines[k]
            if BULLET_RE.match(line):
                bullets.append(line)
            elif not line.startswith((" ", "\t")):
                break
        return bullets
    return []


def edge_inputs(lines, inside, task):
    """(text after the Edge inputs header or None, its bullet strings)."""
    for j in range(task["start"] + 1, task["end"]):
        if inside[j] or not lines[j].startswith(EDGE_HEADER):
            continue
        rest = lines[j][len(EDGE_HEADER):].strip()
        bullets = []
        k = j + 1
        while k < task["end"] and not lines[k].strip() and not bullets:
            k += 1
        for k in range(k, task["end"]):
            line = lines[k]
            if line.startswith("- "):
                bullets.append(line[2:].strip())
            elif bullets and line.startswith((" ", "\t")) and line.strip():
                bullets[-1] += " " + line.strip()
            else:
                break
        return rest, bullets
    return None, []


def unfailable(command):
    """P11: a command that cannot fail is no acceptance check."""
    c = command.strip()
    if not c or c in ("true", ":", "exit 0", "/bin/true"):
        return True
    if UNFAILABLE_TAIL_RE.search(c):
        return True
    words = set()
    for seg in SEGMENT_RE.split(c):
        seg = seg.strip()
        if not seg:
            return False
        words.add(seg.split()[0])
    return words <= {"echo", "printf", "true", ":"}


def structure_problems(tasks):
    problems = []
    if not tasks:
        return ["no tasks found"]
    known = {t["id"] for t in tasks}
    seen = set()
    for t in tasks:
        if t["id"] in seen:
            problems.append("duplicate Task {}".format(t["id"]))
        seen.add(t["id"])
        if t["depends"] is None:
            problems.append("Task {}: no Depends on line".format(t["id"]))
        elif t["depends"].strip() != "none":
            for dep in DEP_ID_RE.findall(t["depends"]):
                if dep not in known or dep == t["id"]:
                    problems.append(
                        "Task {}: depends on unknown Task {}".format(
                            t["id"], dep))
        if t["acceptance"] is None:
            problems.append("Task {}: no Acceptance check line".format(t["id"]))
        else:
            if not t["command"]:
                problems.append(
                    "Task {}: acceptance check has no command".format(t["id"]))
            if MARKER not in t["acceptance"]:
                problems.append(
                    "Task {}: acceptance check is not marked {}".format(
                        t["id"], MARKER))
            elif t["command"] and unfailable(t["command"]):
                problems.append(
                    "Task {}: acceptance check cannot fail: {}".format(
                        t["id"], t["command"]))
    return problems


def table_human_ids(lines, inside):
    """Task ids whose Run shape row is human-shaped."""
    ids = []
    start = None
    for i, line in enumerate(lines):
        if not inside[i] and RUNSHAPE_RE.match(line):
            start = i
            break
    if start is None:
        return ids
    header = None
    for j in range(start + 1, len(lines)):
        if not inside[j] and HEADING_RE.match(lines[j]):
            break
        if inside[j] or not lines[j].startswith("|"):
            continue
        cells = [c.strip() for c in lines[j].strip().strip("|").split("|")]
        if header is None:
            header = cells
            continue
        task_i = header.index("Task") if "Task" in header else -1
        shape_i = header.index("Shape") if "Shape" in header else -1
        if task_i < 0 or shape_i < 0 or task_i >= len(cells) or shape_i >= len(cells):
            continue
        m = TASK_CELL_RE.match(cells[task_i])
        if m and cells[shape_i] == "human":
            ids.append(m.group(1))
    return ids


def human_ids(lines, inside):
    """Human-shaped task ids: from Shape lines, else from the Run shape table."""
    text = "\n".join(lines)
    _, _, tasks = analyze(text)
    table = set(table_human_ids(lines, inside))
    return [t["id"] for t in tasks
            if (t["shape"] == "human" if t["shape_raw"] is not None
                else t["id"] in table)]


def id_key(tid):
    m = re.match(r"^(\d+)(.*)$", tid)
    return (int(m.group(1)), m.group(2))


def wave_of(tasks):
    """Task id to wave: 1 with no dependency, else one past its deepest."""
    deps = {t["id"]: t["dep_ids"] for t in tasks}
    waves = {}

    def wave(tid, path):
        if tid in waves:
            return waves[tid]
        path = path | {tid}
        w = 1 + max([wave(d, path) for d in deps.get(tid, [])
                     if d in deps and d not in path] or [0])
        waves[tid] = w
        return w

    for t in tasks:
        wave(t["id"], frozenset())
    return waves


def run_order(tasks):
    waves = wave_of(tasks)
    return sorted(tasks, key=lambda t: (waves[t["id"]], id_key(t["id"])))


def blocks(lines, inside):
    """Every path= fence outside other fences: (line, path, mode, body)."""
    found = []
    opener = None
    for i, line in enumerate(lines):
        if inside[i] or not FENCE_RE.match(line):
            continue
        if opener is None:
            opener = i
            continue
        m = TEST_FENCE_RE.match(lines[opener])
        if m:
            mode = MODE_RE.search(lines[opener])
            found.append((opener, m.group(2), mode.group(1) if mode else None,
                          "\n".join(lines[opener + 1:i])))
        opener = None
    return found


def test_blocks(text):
    lines = text.split("\n")
    return [(p, body) for _, p, _, body in blocks(lines, fence_map(lines))]


def bad_path(p):
    """Why a test block path may not be written, or None."""
    if os.path.isabs(p) or ".." in p.split("/"):
        return "escapes the repo"
    if not p.startswith(TEST_ROOTS):
        return "is outside tests/, test/, spec/"
    return None


def spans(bullet):
    """The paths a Files bullet names (a path:lines span owns the path)."""
    out = []
    for span in SPAN_RE.findall(bullet):
        if " " in span or span[:1] in ("/", "~", "$"):
            continue
        out.append(LINES_RE.sub("", span))
    return out


def files_of(task):
    files = {"create": [], "modify": [], "test": []}
    for b in task["bullets"]:
        m = KIND_RE.match(b)
        if m:
            files[m.group(1).lower()].extend(spans(b))
    return files


def section(lines, inside, heading_re):
    """(start, end) of the first level-2 section matching heading_re."""
    for i, line in enumerate(lines):
        if not inside[i] and heading_re.match(line):
            for j in range(i + 1, len(lines)):
                h = HEADING_RE.match(lines[j])
                if not inside[j] and h and len(h.group(1)) <= 2:
                    return i, j
            return i, len(lines)
    return None


def table_lines(lines, inside, span):
    if span is None:
        return None
    return [lines[j] for j in range(span[0] + 1, span[1])
            if not inside[j] and lines[j].startswith("|")]


def task_at(tasks, i):
    for t in tasks:
        if t["start"] <= i < t["end"]:
            return t
    return None


def lint_problems(text):
    """Every lint rule, as "<rule>: <detail>" strings."""
    lines, inside, tasks = analyze(text)
    probs = []

    def add(rule, t, detail):
        probs.append("{}: {}{}".format(
            rule, "Task {}: ".format(t["id"]) if t else "", detail))

    log = table_lines(lines, inside, section(lines, inside, DECISION_LOG_RE))
    log_ids = {c.strip().strip("|").split("|")[0].strip()
               for c in (log or [])[1:]}
    for t in tasks:
        if t["shape_raw"] is None:
            add("shape", t, "no Shape line")
        elif t["shape"] is None or (t["shape"] == "human"
                                    and not t["shape_why"]):
            add("shape", t, "Shape must be auto or human, <why>: {}".format(
                t["shape_raw"]))
        if t["type"] is None:
            add("type", t, "no Type line")
        elif t["type"] not in TYPES:
            add("type", t, "Type {} is not one of {}".format(
                t["type"], ", ".join(sorted(TYPES))))
        if t["model"] is not None and len(t["model"].split()) != 1:
            add("model", t, "Model must be one token: {}".format(t["model"]))
        if t["decisions_raw"] is None:
            add("decisions", t, "no Decisions line")
        else:
            for d in t["decisions"]:
                if d not in log_ids:
                    add("decisions", t,
                        "{} is not a row of the Decision log".format(d))
        if t["edge_raw"] is None:
            add("edge-inputs", t, "no Edge inputs line")
        elif t["edge_raw"]:
            if not re.fullmatch(r"none \(.+\)", t["edge_raw"]):
                add("edge-inputs", t,
                    "Edge inputs must be bullets or none (<reason>): {}".format(
                        t["edge_raw"]))
        elif not t["edge_inputs"]:
            add("edge-inputs", t, "Edge inputs has no bullet")

    for i, line in enumerate(lines):
        if inside[i]:
            continue
        bare = CODE_SPAN_RE.sub("", line)
        for p in PLACEHOLDERS:
            if p in bare:
                add("placeholder", task_at(tasks, i),
                    "line {}: {}".format(i + 1, p))

    deps = {t["id"]: [d for d in t["dep_ids"]] for t in tasks}
    reported = set()

    def cycle_from(tid, stack):
        for d in deps.get(tid, []):
            if d in stack:
                return stack[stack.index(d):] + [d]
            if d in deps:
                found = cycle_from(d, stack + [d])
                if found:
                    return found
        return None

    for t in tasks:
        c = cycle_from(t["id"], [t["id"]])
        if c and frozenset(c) not in reported:
            reported.add(frozenset(c))
            add("cycle", t, "Depends on cycle " + " -> ".join(
                "Task " + x for x in c))

    reach = {}

    def ancestors(tid, seen):
        if tid in reach:
            return reach[tid]
        out = set()
        for d in deps.get(tid, []):
            if d in deps and d not in seen:
                out |= {d} | ancestors(d, seen | {d})
        reach[tid] = out
        return out

    owned = {}
    for t in tasks:
        ns = t["repo"] + ":" if t["repo"] else ""
        owned[t["id"]] = {ns + p for b in t["bullets"] for p in spans(b)}
    for a in range(len(tasks)):
        for b in range(a + 1, len(tasks)):
            x, y = tasks[a]["id"], tasks[b]["id"]
            if x == y or x in ancestors(y, {y}) or y in ancestors(x, {x}):
                continue
            for p in sorted(owned[x] & owned[y]):
                probs.append("overlap: Task {} and Task {} both own {}".format(
                    x, y, p))

    found = blocks(lines, inside)
    count = {}
    for _, p, _, _ in found:
        count[p] = count.get(p, 0) + 1
    test_paths = set()
    for t in tasks:
        for p in files_of(t)["test"]:
            test_paths.add(p)
            if count.get(p, 0) != 1:
                add("test-block", t, "{} has {} path= blocks".format(
                    p, count.get(p, 0)))
    shared = section(lines, inside, SHARED_RE)
    if shared:
        for j in range(shared[0] + 1, shared[1]):
            m = None if inside[j] else SHARED_ENTRY_RE.match(lines[j])
            if m and count.get(m.group(1), 0) != 1:
                add("test-block", None, "shared test {} has {} path= blocks"
                    .format(m.group(1), count.get(m.group(1), 0)))
    for i, p, mode, _ in found:
        t = task_at(tasks, i)
        in_shared = shared is not None and shared[0] < i < shared[1]
        if p not in test_paths and not in_shared:
            add("test-block", t, "line {}: path={} is no Test: path and is "
                "not under ## Shared tests".format(i + 1, p))
        why = bad_path(p)
        if why:
            add("test-block", t, "line {}: path={} {}".format(i + 1, p, why))
        if mode is not None and mode not in ("append", "replace"):
            add("test-block", t, "line {}: mode={} is not append or replace"
                .format(i + 1, mode))

    table = table_lines(lines, inside, section(lines, inside, RUNSHAPE_RE))
    if table is not None:
        want = run_table(text).split("\n")
        if table != want:
            n = next((k for k in range(max(len(table), len(want)))
                      if k >= len(table) or k >= len(want)
                      or table[k] != want[k]), 0)
            add("run-shape", None, "table line {} differs from run-table; "
                "paste the run-table output".format(n + 1))
    return probs


def units(text):
    """The tasks in run order (wave, then id) as plain dicts."""
    _, _, tasks = analyze(text)
    waves = wave_of(tasks)
    return [{"id": t["id"], "title": t["title"], "depends": t["dep_ids"],
             "wave": waves[t["id"]], "shape": t["shape"],
             "shape_why": t["shape_why"], "type": t["type"],
             "model": t["model"], "decisions": t["decisions"],
             "files": files_of(t), "check": t["command"],
             "edge_inputs": t["edge_inputs"]}
            for t in run_order(tasks)]


def run_table(text):
    """The aligned Run shape table, one row per task in run order."""
    _, _, tasks = analyze(text)
    waves = wave_of(tasks)
    rows = [["Wave", "Task", "Shape", "Type", "Model", "Why"]]
    for t in run_order(tasks):
        human = t["shape"] == "human"
        rows.append([str(waves[t["id"]]), "Task {} {}".format(t["id"], t["title"]),
                     t["shape"] or "-", t["type"] or "-", t["model"] or "-",
                     (t["shape_why"] or "-") if human else AUTO_WHY])
    widths = [max(len(r[c]) for r in rows) for c in range(len(rows[0]))]

    def fmt(cells):
        return "| " + " | ".join(c.ljust(w) for c, w in zip(cells, widths)) + " |"

    out = [fmt(rows[0]), fmt(["-" * w for w in widths])]
    return "\n".join(out + [fmt(r) for r in rows[1:]])


def self_line():
    with open(os.path.abspath(__file__), "rb") as f:
        return "plan_lint " + hashlib.sha256(f.read()).hexdigest()[:12]


def cmd_check(args):
    print(self_line())
    _, _, tasks = analyze(read_file(args.plan))
    problems = structure_problems(tasks)
    for p in problems:
        print("plan gate: {}".format(p))
    if problems:
        return 1
    print("ok: {} tasks".format(len(tasks)))
    return 0


def cmd_lint(args):
    print(self_line())
    text = read_file(args.plan)
    lines, inside, tasks = analyze(text)
    problems = ["plan gate: {}".format(p) for p in structure_problems(tasks)]
    problems += ["lint: {}".format(p) for p in lint_problems(text)]
    for p in problems:
        print(p)
    if problems:
        return 1
    print("ok: {} tasks, {} waves, {} test blocks".format(
        len(tasks), max(wave_of(tasks).values()),
        len(blocks(lines, inside))))
    return 0


def cmd_units(args):
    print(json.dumps(units(read_file(args.plan)), indent=2))
    return 0


def cmd_tests(args):
    lines = read_file(args.plan).split("\n")
    found = blocks(lines, fence_map(lines))
    refusals, created = [], set()
    for _, p, mode, _ in found:
        why = bad_path(p)
        if why:
            refusals.append("FAIL path {} ({})".format(p, why))
        elif mode not in (None, "append", "replace"):
            refusals.append("FAIL path {} (mode={} is not append or replace)"
                            .format(p, mode))
        elif mode is None and (p in created
                               or os.path.lexists(os.path.join(args.out, p))):
            refusals.append("FAIL path {} exists; tag the block mode=append "
                            "or mode=replace".format(p))
        created.add(p)
    if refusals:
        for r in refusals:
            print(r)
        return 1
    for _, p, mode, body in found:
        target = os.path.join(args.out, p)
        os.makedirs(os.path.dirname(target) or ".", exist_ok=True)
        with open(target, "a" if mode == "append" else "w",
                  encoding="utf-8") as f:
            f.write(body + "\n")
        print("{} {}".format({"append": "appended", "replace": "replaced"}
                             .get(mode, "wrote"), p))
    return 0


def cmd_run_table(args):
    print(run_table(read_file(args.plan)))
    return 0


def cmd_human_tasks(args):
    lines = read_file(args.plan).split("\n")
    for tid in human_ids(lines, fence_map(lines)):
        print(tid)
    return 0


def main(argv):
    ap = argparse.ArgumentParser(
        description="Parse, check, and lint a loop-plan plan.")
    sub = ap.add_subparsers(dest="command", required=True)
    for name, func, help_ in (
            ("check", cmd_check, "gate the plan's structure"),
            ("lint", cmd_lint, "check, then every lint rule"),
            ("units", cmd_units, "the tasks in run order as JSON"),
            ("tests", cmd_tests, "write every path= block under --out"),
            ("run-table", cmd_run_table, "print the Run shape table"),
            ("human-tasks", cmd_human_tasks, "ids of human-shaped tasks")):
        p = sub.add_parser(name, help=help_)
        p.add_argument("plan")
        if name == "units":
            p.add_argument("--json", action="store_true", required=True)
        if name == "tests":
            p.add_argument("--out", required=True)
        p.set_defaults(func=func)
    args = ap.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
