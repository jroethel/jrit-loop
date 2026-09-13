# Audit Playbook

> Source: the improve skill by shadcn, MIT, version 1.0.0, vendored 2026-08-08.

<!--
Vendoring provenance and license.
Vendored from the upstream improve skill, lightly adapted (plans-directory machinery recast to brief/backlog terms, em dashes to plain dashes).
The upstream ships no LICENSE file or source URL; its license is declared in its SKILL.md frontmatter: license: MIT, metadata author: shadcn, version: "1.0.0".
The MIT permission notice is reproduced below with the declared author as the copyright holder (year not stated upstream).

MIT License

Copyright (c) shadcn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-->


What to look for, per category. Each audit pass gets the relevant section plus the **Finding format** at the bottom; adapt depth to repo size.

A finding is only a finding with evidence. "Probably has N+1 queries somewhere" is not a finding; `orders/api.ts:142 issues one query per order item inside a loop` is.

---

## 1. Correctness / Bugs

The highest-trust category - real bugs found by reading, not speculation.

- Error handling: swallowed exceptions, empty catch blocks, missing error states on critical paths.
- Async hazards: unawaited promises, races on shared state, missing cancellation/cleanup (stale React closures, listeners never removed).
- Null/undefined flows: non-null assertions on nullable values, optional chaining hiding a must-exist value, unchecked array indexing.
- Boundary conditions: off-by-one, empty-collection handling, timezone/locale assumptions, integer overflow.
- State machines: impossible states representable in types, status enums with unhandled branches.
- Concurrency: check-then-act on shared resources, missing transactions around multi-write ops, idempotency of retried ops (webhooks, queues).
- Type escape hatches: `any` / `as` / `@ts-ignore` clusters - each is a place the compiler was overruled.
- Resource leaks: unclosed handles/connections/subscriptions; missing `finally`.

## 2. Security

Review only what code evidence directly supports; frame findings as defensive maintenance (code pattern, production impact, remediation) at the level of code/config changes and tests - no runnable misuse strings or step-by-step exploit detail.

**Handling rule:** never copy a secret value into a finding or the brief - the brief gets committed. Reference the `file:line` and credential type only ("Stripe live key at `config.ts:12`"), and the fix sketch always includes rotation, not just removal (a committed secret is burned even after deletion).

**By-design is not a finding:** standard platform conventions (honoring `https_proxy`/`NO_PROXY`, reading `~/.netrc`, a local dev tool shelling out to configured package managers) and tradeoffs recorded in an ADR are settled. Flag only when the *implementation* adds risk beyond the convention or the documented decision - and note that a **stale ADR is itself a finding**: if the code drifted from the decision doc, report the drift rather than using the doc to suppress it.

- Credential hygiene: hardcoded keys/tokens/passwords, credentials in committed `.env` files, credentials logged or persisted; name only type and location, then recommend removal, rotation, and a safer path.
- Data crossing into interpreters or privileged APIs: SQL/command injection, XSS sinks fed by user content, dynamic execution with runtime input, path traversal from request data. Describe the safer API or validation boundary.
- Access control: endpoints/actions lacking server-side identity checks, authz enforced only client-side, object access by ID without ownership/tenant checks (IDOR), missing CSRF on state-changing routes.
- Input contracts: API boundaries trusting request bodies without schema validation, uploads without type/size/storage constraints, broad object assignment from request data (mass assignment).
- Dependency posture: run the ecosystem audit (`npm audit`, `pip-audit`, `cargo audit`) read-only; report only critical/high advisories affecting reachable runtime or build/distribution paths.
- Production configuration: overly broad CORS with credentials, missing hardening headers (CSP) on sensitive surfaces, cookies missing `HttpOnly`/`Secure`/`SameSite`, debug/verbose behavior in production.
- Data minimization: PII or sensitive data in logs, stack traces returned to clients, internal error details in API responses.

## 3. Performance

Algorithmic and architectural wins, not micro-optimizations.

- N+1 patterns: query/fetch per item inside loops or per list-row render; missing batching/dataloader.
- Wrong complexity: nested scans over the same collection, repeated `find`/`filter` in hot loops where a keyed Map belongs.
- Caching gaps: identical expensive computations/fetches repeated per request/render, missing memoization at clear boundaries, no HTTP/data-layer caching on stable data.
- Payload size: over-fetching (select *, full objects where IDs suffice), missing pagination on unbounded lists, large JSON shipped to clients.
- Frontend: heavyweight deps for trivial use, missing code-splitting on rare routes, unoptimized images/fonts, client-side fetching for render-time data, render waterfalls (defer to framework conventions).
- Backend: synchronous work that belongs in a queue, missing indexes implied by query patterns (flag for verification, don't claim without schema evidence), connection-per-request where pooling exists.
- Build/CI: missing caching, redundant pipeline steps, test suites that could parallelize.

## 4. Test Coverage

The goal is not a percentage - it's *which untested code is dangerous*.

- Map critical paths (money, auth, data mutation, the feature the repo exists for); check which have zero or trivial coverage.
- High-churn modules (git log) with no tests = top refactor risk; flag as "characterization tests first" candidates.
- Existing test quality: assertions that assert nothing, heavy mocking that tests the mocks, unread snapshots, flaky patterns (real timers/network, order dependence).
- Missing layers: unit-only with no integration coverage on API boundaries, or slow E2E for what a unit test would catch.
- Verification infrastructure: is there a one-command way to know the codebase works? If not, that's finding #1 and a prerequisite for any risky change.

## 5. Tech Debt & Architecture

- Duplication: the same logic re-implemented in 3+ places; divergent copies that drifted.
- Layering violations: UI importing data-layer internals, circular dependencies, "utils" junk drawers with high fan-in.
- Dead code: unexported-and-unused modules, fully-rolled-out flags still branching, unexplained commented-out blocks, unimported manifest deps.
- God objects/modules: files an order of magnitude larger than the repo median that everything touches; double-digit-parameter functions or deep nesting.
- Inconsistent patterns: three ways of doing fetching/error-handling/styling in one repo - pick the winner and brief the consolidation.
- Abstraction mismatches: premature abstractions with a single implementation, or missing abstractions where one change always touches N files in lockstep.

## 6. Dependencies & Migrations

- Major-version lag on core framework/runtime where staying behind has real cost (EOL, security-fix cutoffs, ecosystem incompatibility).
- Deprecated APIs with announced removal timelines.
- Abandoned dependencies (no release in years, archived) on critical paths.
- Duplicate dependencies solving the same problem (two date libs, two HTTP clients).
- Lockfile/manifest drift, version-pinning inconsistencies across a monorepo.
- Per migration candidate, estimate blast radius (files touched) - it drives effort and whether to recommend it at all.

## 7. DX & Tooling

- Missing or broken: typecheck script, lint config, formatter, pre-commit hooks, editorconfig.
- Slow feedback loops: dev-server/test startup in minutes, no watch mode, CI without caching.
- Onboarding friction: wrong/incomplete README setup, undocumented required env vars, no `.env.example`.
- Missing `CLAUDE.md`/`AGENTS.md` where agents work downstream - recommend one as a briefable finding.
- Error messages/logging: unstructured service logs, missing request IDs/correlation, debugging that requires code changes.

## 8. Docs

Lowest default priority - only flag where absence has a concrete cost:

- Public API surface (published packages) without reference docs.
- Architectural decisions nobody can reconstruct (why X over Y) for actively-contested areas.
- Stale docs that are actively wrong (worse than missing) - setup instructions, examples that no longer compile.

## 9. Direction - features & where to take this next

Forward-looking: not what's broken, but what this codebase wants to become.
**Grounding rule:** every suggestion must cite evidence from the repo itself - a suggestion that could apply to any project in the category ("add dark mode", "add AI") is noise, not a finding. Grounded signal sources:

- **Unfinished intent**: TODO/FIXME clusters on one theme, flags never rolled out, stubbed/half-built modules, commented-out feature code, abandoned mid-feature work in git history.
- **Stated-but-undelivered**: README/docs/roadmap promises with no code, no-op CLI flags/config, issue templates for features that don't exist. A PRD or `PRODUCT.md` naming users/use-cases/direction the code hasn't caught up to is the strongest grounding signal - prefer it over inferred intent, and never propose what a decision doc already rejected (note the contradiction instead).
- **Surface asymmetries**: one-directional pairs (export without import, create without bulk-create, webhooks out but not in), entities with CRUD minus one, a public API internal code hand-rolled around.
- **The adjacent possible**: capabilities the architecture makes disproportionately cheap - a plugin system one interface away, a public API one route file from the service layer, an integration the data model already supports.
- **Friction worth productizing**: things users evidently do by hand around the project (visible in docs, examples, issues) that it could absorb.

Direction findings use the standard format with two adaptations: **Impact** is product/user value (who wants this and why now), and **Confidence** reflects how grounded the evidence is - not certainty it's the right call. Strategy belongs to the maintainer; effort estimates here are coarser (say so). A selected direction finding briefs as a design/spike outcome (prototype, define the API, list open questions), not a build-everything brief.

---

## Effort levels

Audit depth follows the **effort level** (default `standard`; the `/loop-improve` invocation sets it with a `quick` or `deep` keyword, or scopes it with a focus argument like `security`):

| | `quick` | `standard` (default) | `deep` |
|---|---|---|---|
| Coverage | Recon hotspots only - highest-churn, highest-criticality code | Hotspot-weighted, key packages | Whole repo, every package |
| Breadth | "medium" | "very thorough" for correctness + security, "medium" rest | "very thorough" everywhere |
| Categories | correctness, security, tests | all nine | all nine |
| Findings | top ~6, HIGH-confidence only | full table | full table incl. LOW-confidence investigation items |

Whatever the level, say in the brief what was *not* audited. On a large monorepo even `deep` scopes to packages, not the root.

---

## Finding format

Every finding, from every category, comes back in this shape:

```markdown
### [CATEGORY-NN] Short imperative title

- **Evidence**: `path/file.ts:123` - one-sentence description of what's there. (Repeat per location; 2-5 strongest, note "and ~N similar sites" if widespread.)
- **Impact**: What goes wrong / what's being paid. Concrete: "every order-list render issues 1+N queries", not "suboptimal".
- **Effort**: S (hours) / M (a day-ish) / L (multi-day) - for the *fix*, including tests.
- **Risk**: What the fix could break; LOW/MED/HIGH plus one line why.
- **Confidence**: HIGH (read the code, certain) / MED (strong signal, needs verification) / LOW (smell, needs investigation). A LOW-confidence finding selected for briefing is briefed as investigation scope, not build scope.
- **Fix sketch**: 1-3 sentences. Just enough to judge effort honestly.
```

## Prioritization rubric

Order findings by **leverage = impact / effort, discounted by confidence and fix-risk**. Tiebreakers:

1. Anything that unblocks other findings (verification baseline, characterization tests) floats up.
2. Security findings with HIGH confidence float above equivalent-leverage non-security findings.
3. Prefer findings whose fix has a clean verification story - executor models succeed at those.
4. "Not worth doing" is a valid verdict; record it with one line of reasoning so the user knows it was considered.
