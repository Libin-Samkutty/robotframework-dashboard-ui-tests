# Engineering Decisions

Decision-record style notes for choices made in this repo that aren't
self-explanatory from the code alone - the problem, what was tried, what was
picked, and what tradeoff was accepted. Each entry below is backed by an
artifact in this repo (a config file, a commit) rather than an abstract
claim; where useful, the commit is named directly.

---

## ADR-001: `--testlevelsplit` over per-suite splitting

**Problem:** pabot can shard work per suite file or per test case. With only
4 suite files in this repo (`login_suite`, `dashboard_suite`, `api/smoke`,
`api/negative`), per-suite splitting caps parallelism at 4 workers no matter
how many test cases exist inside them.

**Decision:** Use `--testlevelsplit`, so every test case becomes its own
pabot work item. Parallelism now scales with test count (22 cases) instead
of file count (4 files).

**Tradeoff accepted:** Each test-level item runs as its own `robot`
subprocess - this is how pabot itself works, not a repo-specific choice - so
Suite Setup/Teardown re-runs per test instead of once per suite. Two things
in this repo are built to survive that (see ADR-002).

**Evidence:** `.github/workflows/ci.yml` (`pabot --testlevelsplit --pabotlib
--processes 3`), `README.md` § Parallel execution with pabot.

---

## ADR-002: PabotLib `Run Only Once` for cross-process shared state

**Problem:** ADR-001's `--testlevelsplit` means `api/tests/smoke/` can no
longer share one registered Notes API user and note id across the whole
suite via `Suite Variable` - each test is now its own isolated suite, and
that state doesn't survive between them.

**Decision:** Register the shared API test user through PabotLib's
`Run Only Once` instead, so exactly one registration call happens for the
entire parallel run regardless of worker count, with `Run Teardown Only
Once` deleting that account after every process has finished with it. Every
test still logs in for itself (cheap - no new account per test).

**Tradeoff accepted:** Requires `--pabotlib` to be passed on every pabot
invocation - forgetting it silently loses the cross-process coordination
rather than failing loudly.

**Evidence:** `api/resources/common_resources.robot :: Ensure Shared API
Test User`. Verifiable directly: run `pabot --testlevelsplit --pabotlib
--processes 4 api` and diff registration/deletion keyword counts in
`log.html` - 10 tests across 4 processes, exactly one register/delete call
pair.

---

## ADR-003: `docker compose` needs a real `.env` file even for services it never starts

**Problem:** CI's `smoke-gate` job only starts `selenium-hub` and `chrome`,
never `robot-tests` - but `docker compose down` still failed, because Compose
validates `env_file` for every service declared in `docker-compose.yml`, not
just the ones actually brought up.

**Decision:** Add a `cp .env.example .env` step before any `docker compose`
command in CI. `.env.example` is placeholder-only (see ADR-005), so this
introduces no secret-handling risk.

**Evidence:** commit `583ccc0` ("resolved missing copy env command + grid hub
timeout issue"), `.github/workflows/ci.yml` § `Create .env for docker
compose`.

---

## ADR-004: Grid-readiness check needed a whitespace-tolerant match

**Problem:** The Grid-readiness poll (`curl .../wd/hub/status | grep -q
"\"ready\":true"`) intermittently failed even when the hub had genuinely
already come up, because the hub's JSON status response doesn't always
serialize `"ready":true` with zero whitespace after the colon - a literal
substring match was too brittle for a JSON body whose formatting isn't
contractually fixed.

**Decision:** Switch to `grep -Eq "\"ready\":[[:space:]]*true"`, tolerating
zero-or-more whitespace between the key and value.

**Evidence:** commit `8ed4155` ("fixed grep pattern with no space"),
backported to `nightly.yml` (which shares the same readiness-check pattern
but wasn't touched by the original fix) once the gap was noticed while
writing this document.

---

## ADR-005: Scan `.env.example` for credential-shaped keys only, not every value

**Problem:** The `lint` job's `.env.example` check was meant to catch a real
secret accidentally committed as a literal value. Its first version scanned
*every* key's value against a placeholder list, which meant ordinary config
- `BROWSER=Chrome`, `ENV=STAGING`, a numeric timeout - could fail the check
simply for not resembling a placeholder string, despite never being secret
in the first place. That's a false positive blocking CI for no real risk.

**Decision:** Only check values whose *key* looks credential-shaped
(`password`, `secret`, `token`, `apikey`, `credential`, etc.). Non-credential
config keys are skipped entirely, regardless of their value.

**Tradeoff accepted:** A credential accidentally placed under a
non-credential-sounding key name would not be caught. Narrowing by key
reduces false positives at the cost of relying on keys being named
sensibly - judged a reasonable tradeoff for a repo with no real secrets to
begin with (see `docs/POM_ARCHITECTURE.md` § Secrets Management).

**Evidence:** commit `318d3ae` ("updated false positive issue fix in the ci
file"), `.github/workflows/ci.yml` § `Check .env.example has no real
credential values`.

---

## ADR-006: Dump Grid container logs on failure instead of a bare timeout message

**Problem:** When the Grid-readiness wait timed out, the only CI signal was
"timeout: command timed out" - no visibility into *why* the hub never
reported ready (crashed node, network issue, slow image pull).

**Decision:** Add a `Dump Grid container status/logs on failure` step
(`docker compose ps -a`, hub logs, node logs, a raw `curl -sv` of the status
endpoint) gated on `if: failure()`, so a red run comes with diagnostic
context attached instead of requiring a re-run with manual debugging added
after the fact.

**Evidence:** commit `b20cf83` ("added failure diagnostic logs"),
`.github/workflows/ci.yml` § `Dump Grid container status/logs on failure`.

---

## ADR-007: Both Allure and Robot's native report/log, not Allure alone

**Problem:** Allure gives richer, step-by-step reporting and parity with the
sibling Playwright repo's reporting - but it's an external listener
dependency, and a listener failure or misconfiguration shouldn't leave a CI
run with no readable output at all.

**Decision:** Keep Robot's own `--report`/`log.html` generation running
alongside the Allure listener (`argfile.robot`), rather than disabling native
reporting in favor of Allure exclusively.

**Evidence:** `argfile.robot` (`--listener allure_robotframework:...` next to
`--outputdir`/`--loglevel`), `README.md` § Reporting.

---

## ADR-008: Retain Robot Framework for this scope rather than porting to Playwright

**Problem:** This repo's sibling (`libin-samkutty-playwright-web-api-automation-demo`)
targets the same site with Playwright. It would be easy to treat that as "the
newer tool, so migrate everything."

**Decision:** Keep the 22 existing Robot Framework cases as-is. They're
stable, have no flake history, and the API suite in particular
(`RequestsLibrary` + DataDriver's CSV support) is a genuinely good fit for
HTTP smoke/negative testing that Playwright wouldn't meaningfully improve on
at this scope. All new feature work goes to the Playwright repo instead.

**Why this isn't just tool-agnosticism:** the reasoning mirrors a broader
pattern worth naming honestly - a framework becomes worth migrating away
from once its *limitations turn structural* (e.g. a parallelization ceiling
where adding workers stops helping, authoring overhead that scales worse
than the test count, weak debugging affordances against an increasingly
async UI) rather than merely "a newer tool exists." Where that hasn't
happened - a small, stable suite with a workload the existing tool already
fits well - continuing to rewrite it in the newer tool is migration for its
own sake, not for a measurable problem it solves.

**Evidence:** [docs/MIGRATION.md](MIGRATION.md) (full rationale, current
state comparison table).
