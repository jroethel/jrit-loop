#!/usr/bin/env python3
"""compile_drive.py: compile a committed plan into the chain's drive graph.

  python3 .ai/jrit/compile_drive.py <plan> --issue <n> --chain <chain run id>
      --template <jrit-chain.yaml> --routing <routing.conf> --out <file>

Writes a cezar version 2 workflow named jrit-drive.I<n>.<chain id8> (D9):
preflight, an entry ladder, the drive card before unit 1, per auto unit an
implement agent, its gate, a validator on the other model, a landed check, a
two-round repair loop and a cut-off loop (D24), a gate.human per human unit
(D18), then the landing copied verbatim from the template (D15).
Stdlib only: the YAML is written by string templates, every prompt as a |
block. The parser is plan_lint.py beside this file.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.dont_write_bytecode = True  # no __pycache__ in .ai/jrit/ or the template kit
from plan_lint import read_file, units

STAGE_TOOLS = ("[Read, Edit, Write, Grep, Glob, Bash, Skill, Agent, ToolSearch, "
               "TaskCreate, TaskUpdate, TaskList, TaskGet]")
BAN = ("Never emit CEZ:ASK, CEZ:DONE, or CEZ:MONITORING, and never write "
       "JRIT-ASK: no card is read after this step.")
UNATTENDED = ("No human watches this session: where the card rules leave a "
              "choice open, take the documented default, write it as NEEDS "
              "HUMAN CONFIRMATION in your handoff, and never raise a second "
              "card for it.")
MODELS = ("sonnet", "opus")


class CompileError(Exception):
    pass


def q(s):
    """A YAML double-quoted scalar (JSON strings are valid YAML)."""
    return json.dumps(s)


def block(lines, indent=6):
    pad = " " * indent
    return "\n".join(pad + l if l else "" for l in lines)


def read_routing(path):
    table = {}
    for raw in read_file(path).splitlines():
        line = raw.split("#", 1)[0].split()
        if not line:
            continue
        if len(line) != 2:
            raise CompileError("routing.conf: not '<type> <model>': " + raw)
        table[line[0]] = line[1]
    if "default" not in table:
        raise CompileError("routing.conf has no default line")
    return table


def between(text, begin, end):
    """The template lines from the begin marker line to the end marker line."""
    lines = text.split("\n")
    try:
        a = next(i for i, l in enumerate(lines) if l.strip() == begin)
        b = next(i for i in range(a + 1, len(lines)) if lines[i].strip() == end)
    except StopIteration:
        raise CompileError("template has no {} ... {} block".format(begin, end))
    return "\n".join(lines[a:b + 1])


def resume_prompt(text):
    """The chain's &resume-prompt block, without its indent."""
    lines = text.split("\n")
    for i, l in enumerate(lines):
        if l.rstrip().endswith("prompt: &resume-prompt |"):
            body = []
            for x in lines[i + 1:]:
                if x.strip() and not x.startswith(" " * 6):
                    break
                body.append(x[6:])
            while body and not body[-1].strip():
                body.pop()
            return body
    raise CompileError("template has no &resume-prompt block")


class Graph:
    def __init__(self):
        self.nodes, self.edges = [], []

    def flat(self, id_, name, type_, **extra):
        parts = ["id: " + id_, "name: " + q(name), "type: " + type_]
        parts += ["{}: {}".format(k, v) for k, v in extra.items()]
        self.nodes.append("  - { " + ", ".join(parts) + " }")

    def check(self, id_, name, command):
        self.flat(id_, name, "check", command=q(command))

    def ping(self, id_, name, kind, arg, to):
        self.check(id_, name, "bash .ai/jrit/ping.sh {} {}".format(kind, arg))
        self.edge(id_ + ".pass", to)
        self.edge(id_ + ".fail", to)

    def contains(self, id_, name, ref, value):
        self.flat(id_, name, "if", condition="{{ kind: output, ref: {}, op: contains, value: {} }}"
                  .format(ref, q(value)))

    def agent(self, id_, name, model, tools, prompt, session=None, verdicts=None):
        out = ["  - id: " + id_, "    name: " + q(name), "    type: agent",
               "    model: " + model, "    allowedTools: " + tools]
        if verdicts:
            out.append("    verdicts: " + verdicts)
        if session:
            out.append("    session: {{ continue: {} }}".format(session))
        out += ["    prompt: |", block(prompt)]
        self.nodes.append("\n".join(out))

    def edge(self, src, to):
        self.edges.append("  - {{ from: {}, to: {} }}".format(src, to))


def compile_plan(plan, issue, chain, template, routing):
    route = read_routing(routing)
    tpl = read_file(template)
    tasks = units(read_file(plan))
    if not tasks:
        raise CompileError("{} has no tasks".format(plan))
    for t in tasks:
        if t["shape"] not in ("auto", "human"):
            raise CompileError("Task {} has no Shape auto or human".format(t["id"]))
        if t["model"] and t["model"] not in route.values():
            raise CompileError("Task {} pins model {}, not a routing name".format(
                t["id"], t["model"]))
    ref = "refs/jrit/I{}".format(issue)
    resume = resume_prompt(tpl)
    g = Graph()

    def first(k):
        if k > len(tasks):
            return "drive-gate"
        return ("u{}-implement" if tasks[k - 1]["shape"] == "auto" else "ping-u{}-human").format(k)

    g.flat("start", "Start", "start")
    g.check("preflight", "Preflight", "bash .ai/jrit/stage-preflight.sh")
    g.edge("start", "preflight")
    g.edge("preflight.pass", "at-1")
    for k in range(1, len(tasks) + 1):
        g.contains("at-%d" % k, "Entry: unit %d?" % k, "preflight.output", "Route: unit=%d;" % k)
        g.edge("at-%d.true" % k, "tests-commit" if k == 1 else first(k))
        g.edge("at-%d.false" % k, "at-%d" % (k + 1) if k < len(tasks) else "route-review")
    g.contains("route-review", "Route: review?", "preflight.output", "Route: review")
    g.edge("route-review.true", "drive-gate")
    g.edge("route-review.false", "ping-stopped-bad-route")
    g.ping("ping-stopped-bad-route", "Ping: stopped on a bad route", "end", "stopped-bad-route", "stopped-bad-route")
    g.flat("stopped-bad-route", "Stopped: bad route", "end", status="failed")

    g.check("tests-commit", "Tests commit", "bash .ai/jrit/stage-tests.sh")
    g.check("drive-card-text", "Drive card text", "bash .ai/jrit/stage-drive.sh card")
    g.contains("drive-has-question", "Drive: no question?", "drive-card-text.output", "No question from")
    g.flat("drive-card", "Drive card", "gate.human", message=q("{{nodes.drive-card-text.output}}"))
    g.edge("tests-commit.pass", "drive-card-text")
    g.edge("drive-card-text.pass", "drive-has-question")
    g.edge("drive-has-question.true", first(1))
    g.edge("drive-has-question.false", "ping-drive-card")
    g.ping("ping-drive-card", "Ping: drive card", "card", "drive-card-text", "drive-card")
    g.edge("drive-card.approve", first(1))
    g.edge("drive-card.reject", "ping-drive-rejected")
    g.ping("ping-drive-rejected", "Ping: drive rejected", "end", "drive-rejected", "drive-rejected")
    g.flat("drive-rejected", "Drive rejected", "end", status="failed")

    for k, t in enumerate(tasks, 1):
        tid, nxt, u = t["id"], first(k + 1), "u%d-" % k
        if t["shape"] == "human":
            g.ping("ping-%shuman" % u, "Unit %d ping: human task" % k, "card", u + "human-text", u + "human-text")
            g.check(u + "human-text", "Unit %d human task text" % k, "bash .ai/jrit/stage-drive.sh human " + tid)
            g.flat(u + "human", "Unit %d human: %s" % (k, t["title"]), "gate.human", message=q(
                "Task {} is human-shaped: {}. Do it on this branch, then approve; reject ends the run."
                .format(tid, t["shape_why"])))
            g.edge(u + "human-text.pass", u + "human")
            g.edge(u + "human-text.fail", "ping-unit-failed")
            g.edge(u + "human.approve", nxt)
            g.edge(u + "human.reject", "ping-unit-failed")
            continue
        model = t["model"] or route.get(t["type"], route["default"])
        other = "sonnet" if model == "opus" else "opus"
        ids = ", ".join(t["decisions"]) or "none"
        g.agent(u + "implement", "Unit %d implement: %s" % (k, t["title"]), model, STAGE_TOOLS, [
            "Implement Task {} of {} on this branch.".format(tid, plan),
            "Read the plan's header, Global constraints, the Decision log rows {}, and the section \"### Task {}\".".format(ids, tid),
            "The tests for this plan are committed at the ref {0}/tests (git rev-parse {0}/tests); never edit a committed test or the plan.".format(ref),
            "Run the task's steps, make its acceptance check pass, commit with the task's commit line, leave the tree clean, and end your turn.",
            UNATTENDED, BAN])
        g.check(u + "gate", "Unit %d gate" % k, "bash .ai/jrit/unit-gate.sh " + tid)
        g.agent(u + "validate", "Unit %d validate" % k, other, "[Read, Grep, Glob, Bash]", [
            "You are read-only: edit nothing, commit nothing.",
            "Review unit {0}: git diff $(git rev-parse -q --verify {1}/unit-head || git rev-parse {1}/tests)..HEAD against the section \"### Task {0}\" of {2}, its Edge inputs, and the Decision log rows {3}; rerun its acceptance check.".format(tid, ref, plan, ids),
            "If ANY criterion fails the verdict is fail.",
            "End with CEZ:VERDICT pass or CEZ:VERDICT fail and the reasons.",
            "Never emit CEZ:ASK, CEZ:DONE, or CEZ:MONITORING."], verdicts="[pass, fail]")
        g.check(u + "landed", "Unit %d landed" % k, "bash .ai/jrit/unit-gate.sh landed " + tid)
        g.flat(u + "fix-rounds", "Unit %d repair rounds" % k, "loop", max=2)
        g.agent(u + "repair", "Unit %d repair" % k, model, STAGE_TOOLS, [
            "Unit {} did not pass. The unit gate said:".format(tid),
            "{{nodes.%sgate.output}}" % u,
            "The validator said (empty when it has not run since the gate failed):",
            "{{nodes.%svalidate.summary}}" % u,
            "Fix the work on this branch without editing any committed test or the plan, commit, leave the tree clean, and end your turn.",
            UNATTENDED, BAN], session=u + "implement")
        g.check(u + "cut-check", "Unit %d cut-off check" % k, "bash .ai/jrit/stage-cut-reason.sh")
        g.flat(u + "cut-rounds", "Unit %d cut-off rounds" % k, "loop", max=2)
        g.contains(u + "cut-validate", "Unit %d cut-off was the validator?" % k, u + "cut-check.output", u + "validate")
        g.agent(u + "resume", "Unit %d resume" % k, model, STAGE_TOOLS, resume, session=u + "implement")
        for a, b in (("implement.done", "gate"), ("gate.pass", "validate"), ("gate.fail", "fix-rounds"),
                     ("validate.pass", "landed"), ("validate.fail", "fix-rounds"), ("fix-rounds.repeat", "repair"),
                     ("repair.done", "gate"), ("implement.failed", "cut-check"), ("repair.failed", "cut-check"),
                     ("validate.failed", "cut-check"), ("cut-check.pass", "cut-rounds"), ("cut-rounds.repeat", "cut-validate"),
                     ("cut-validate.true", "validate"), ("cut-validate.false", "resume"), ("resume.done", "gate"),
                     ("resume.failed", "cut-check")):
            g.edge(u + a, u + b)
        g.edge(u + "landed.pass", nxt)
        for p in ("landed.fail", "cut-check.fail", "fix-rounds.exhausted", "cut-rounds.exhausted"):
            g.edge(u + p, "ping-unit-failed")
    g.ping("ping-unit-failed", "Ping: unit failed", "end", "unit-failed", "unit-failed")
    g.flat("unit-failed", "Unit failed", "end", status="failed")

    name = "jrit-drive.I{}.{}".format(issue, chain[:8])
    return "\n".join([
        "# Generated by compile_drive.py from {}; never edit or commit it (D9).".format(plan),
        "version: 2",
        "name: " + name,
        "description: " + q("The drive of {} for #{}, compiled for chain run {}.".format(plan, issue, chain)),
        "nodes:",
        "\n".join(g.nodes),
        "",
        between(tpl, "# landing:begin", "# landing:end"),
        "edges:",
        "\n".join(g.edges),
        "",
        between(tpl, "# landing-edges:begin", "# landing-edges:end"),
        ""])


def main(argv):
    ap = argparse.ArgumentParser(description="Compile a plan into the drive graph.")
    ap.add_argument("plan")
    ap.add_argument("--issue", required=True)
    ap.add_argument("--chain", required=True)
    ap.add_argument("--template", required=True)
    ap.add_argument("--routing", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)
    try:
        text = compile_plan(a.plan, a.issue, a.chain, a.template, a.routing)
    except (CompileError, OSError) as e:
        print("compile: {}".format(e), file=sys.stderr)
        return 1
    with open(a.out, "w", encoding="utf-8") as f:
        f.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
