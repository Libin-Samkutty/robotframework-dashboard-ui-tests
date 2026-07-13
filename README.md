# Robot Framework Automation - practice.expandtesting.com

[![CI](https://github.com/Libin-Samkutty/robotframework-dashboard-ui-tests-demo/actions/workflows/ci.yml/badge.svg)](https://github.com/Libin-Samkutty/robotframework-dashboard-ui-tests-demo/actions/workflows/ci.yml)
[![Nightly Regression](https://github.com/Libin-Samkutty/robotframework-dashboard-ui-tests-demo/actions/workflows/nightly.yml/badge.svg)](https://github.com/Libin-Samkutty/robotframework-dashboard-ui-tests-demo/actions/workflows/nightly.yml)

Robot Framework test automation targeting the real public site
[practice.expandtesting.com](https://practice.expandtesting.com) - web UI
login/secure-area regression and Notes REST API smoke/negative coverage.
Runs against a Selenium Grid via Docker Compose, reports through both
Robot's native HTML output and Allure, and is paired with a sibling
Playwright repo that targets the same site (see
[docs/MIGRATION.md](docs/MIGRATION.md) for the story behind the pairing).

## Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Project Structure](#project-structure)
6. [Architecture](#architecture)
7. [Running Tests](#running-tests)
8. [Docker Setup](#docker-setup)
9. [CI/CD](#cicd)
10. [Reporting](#reporting)
11. [Coverage](#coverage)
12. [Adding New Tests](#adding-new-tests)
13. [Troubleshooting](#troubleshooting)
14. [Engineering Decisions](#engineering-decisions)

---

## Project Overview

Two test domains, both against the same real system under test:

- **Web** - login page and the post-login `/secure` area, via SeleniumLibrary
- **API** - the Notes REST API (`/notes/api`) - health check, auth, CRUD, and
  negative-path coverage, via RequestsLibrary

Page Object Model with an action/result split per page, a `shared/` layer for
cross-module keywords and test data, Selenium Grid via Docker Compose, Allure
+ native Robot reporting, and a GitHub Actions pipeline gated by Robocop lint
and a smoke-tier tag.

---

## Tech Stack

| Component | Technology |
|---|---|
| Test Framework | Robot Framework 7.1 |
| Web Automation | SeleniumLibrary, via Selenium Grid |
| API Testing | RequestsLibrary |
| Data-Driven Testing | DataDriver (CSV) |
| Test Data Generation | FakerLibrary |
| Linting | Robocop |
| Reporting | Robot's native HTML report/log + Allure |
| Containerization | Docker & Docker Compose (Selenium Grid) |
| CI/CD | GitHub Actions |

---

## Prerequisites

- Python 3.10+
- For local (non-Docker) web test runs: a local Chrome or Firefox install -
  Selenium 4.6+'s bundled Selenium Manager auto-resolves a matching driver,
  no manual driver install needed
- Docker + Docker Compose - to run against a Selenium Grid instead

---

## Quick Start

```bash
python -m venv .venv
source .venv/bin/activate      # .venv\Scripts\activate on Windows

pip install -r requirements.txt
cp .env.example .env
```

`.env.example` already points at the real target site with its publicly
documented practice credentials - nothing sensitive to fill in:

```bash
BASE_URL=https://practice.expandtesting.com
NOTES_API_URL=https://practice.expandtesting.com/notes/api
DEFAULT_USERNAME=practice
DEFAULT_PASSWORD=SuperSecretPassword!
```

```bash
# API tests - fastest feedback
robot api/tests/

# Web tests - local browser
robot --variable BROWSER:Chrome web/tests/

# Everything, smoke tier only
robot --include @smoke web api
```

See [docs/QUICK_START.md](docs/QUICK_START.md) for the full walkthrough.

---

## Project Structure

```
robotframework-dashboard-ui-tests-demo/
├── web/
│   ├── data/
│   │   ├── common_properties.robot
│   │   ├── locators/
│   │   │   ├── login_page_locators.robot
│   │   │   └── dashboard_page_locators.robot     # models the /secure page
│   │   └── testdata/
│   │       ├── login_credentials.csv
│   │       ├── stage/stage_testdata.robot
│   │       └── prod/prod_testdata.robot
│   ├── resources/
│   │   ├── common_resources.robot
│   │   ├── pages/
│   │   │   ├── login_resource/{login_action,login_result}.robot
│   │   │   └── dashboard_resource/{dashboard_action,dashboard_result}.robot
│   │   └── utilities/utility_keywords.robot
│   └── tests/
│       ├── login_suite/{login_page_test,login_data_driven_test}.robot
│       └── dashboard_suite/dashboard_page_test.robot
│
├── api/
│   ├── data/
│   │   ├── common_properties.robot
│   │   └── testdata/common_error_messages.robot
│   ├── resources/
│   │   ├── common_resources.robot                # Notes API session/auth/CRUD
│   │   └── utilities/utility_keywords.robot
│   └── tests/
│       ├── smoke/Verify_Smoke_Scenarios.robot
│       └── negative/Verify_Error_Responses.robot
│
├── shared/                                        # cross-module keywords/data
│   ├── keywords/{common_keywords,assertion_keywords}.robot
│   └── test_data/shared_testdata.robot
│
├── .github/workflows/
│   ├── ci.yml                                     # lint -> smoke-gate -> full-regression
│   └── nightly.yml                                # Grid regression + GitHub Pages
│
├── docs/
│   ├── QUICK_START.md
│   ├── POM_ARCHITECTURE.md
│   ├── ADDING_TESTS.md
│   └── MIGRATION.md
│
├── argfile.robot
├── requirements.txt
├── robocop.toml
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
└── .env.example
```

There is no `chatbot/` module - see
[docs/MIGRATION.md](docs/MIGRATION.md#note-chatbot-module-retirement) for why.

---

## Architecture

Full detail in [docs/POM_ARCHITECTURE.md](docs/POM_ARCHITECTURE.md) (code
layering) and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) (Mermaid diagrams
of the Docker network, CI/CD pipeline, and pabot parallel execution). In
short: `shared/` holds cross-module keywords and test data (environment
resolution, timeouts, generic assertions) so `web/` and `api/` don't each
redefine them; each module then follows `data/` (locators + testdata) →
`resources/` (action/result keywords) → `tests/` (test cases).

Web tests reach the site through a Selenium Grid (`SeleniumLibrary` → Grid
hub → Chrome/Firefox node → practice.expandtesting.com); API tests talk to
the Notes API directly via `RequestsLibrary` - no Grid involved for `api/`.

---

## Running Tests

```bash
# By tag tier
robot --include @smoke web api
robot --include @critical web api
robot --include @regression web api

# By module
robot web/tests/
robot api/tests/

# Against a Selenium Grid
robot --variable REMOTE_URL:http://localhost:4444/wd/hub --variable BROWSER:chrome web

# Parallel (pabot) - splits at test level, one process per test
pabot --testlevelsplit --pabotlib --processes 4 web api

# Lint
robocop check web api shared
```

Every test case carries at least one of `@smoke`, `@critical`, or
`@regression`.

### Parallel execution with pabot

`--testlevelsplit` runs every test case as its own pabot "item" instead of
splitting per suite file - with only 4 suite files today, per-suite splitting
caps parallelism at 4 workers; per-test splitting scales with the test count
instead.

Each item runs as its own `robot` subprocess (this is how pabot itself
works - not a repo-specific choice), so Suite Setup/Teardown re-run per test
rather than once per suite. Two places in this repo are built to survive
that:

- **`api/tests/smoke/`** used to share one registered Notes API user and one
  note id across the whole suite via `Suite Variable`. Under
  `--testlevelsplit` those variables don't survive between tests (each test
  is its own isolated suite), so the update/delete test now creates its own
  note, and the shared test user is registered through PabotLib instead -
  see below.
- **`--pabotlib`** enables PabotLib's cross-process coordination. `Ensure
  Shared API Test User` (`api/resources/common_resources.robot`) uses
  `Run Only Once` so exactly one registration call happens for the *entire*
  parallel run, no matter how many processes are used; every test still logs
  in for itself (cheap - no new account), and `Run Teardown Only Once`
  deletes that one shared account after every process has finished with it.

Run `pabot --testlevelsplit --pabotlib --processes 4 api` twice and diff the
registration/deletion keyword counts in `log.html` to see this directly: 10
tests across 4 processes, but exactly one `Register Shared API Test User`
and one `Delete Shared API Test User` call.

`scripts/generate_pabot_ordering.py` reads a previous run's `output.xml` (if
one exists - CI restores it from a cache, see `ci.yml`) and writes a pabot
`--ordering` file listing tests slowest-first, so the historically slowest
tests get scheduled onto a free worker immediately instead of queuing up
behind faster ones near the end of the run:

```bash
python scripts/generate_pabot_ordering.py reports/output.xml reports/pabot_order.txt
pabot --testlevelsplit --pabotlib --processes 4 --ordering reports/pabot_order.txt web api
```

With no history file yet (first run, or a cold CI cache), the script writes
an empty ordering file and pabot just runs everything in its default order -
nothing is skipped, ordering only kicks in once history exists.

---

## Docker Setup

`docker-compose.yml` brings up a Selenium Grid (`selenium-hub` + `chrome` +
`firefox` nodes) plus a `robot-tests` service that talks to it over the
Docker network via `REMOTE_URL`:

```bash
# Full stack - runs the default smoke suite
docker compose up --build

# Bring up just the Grid, then run tests from the host against it
docker compose up -d selenium-hub chrome firefox
robot --variable REMOTE_URL:http://localhost:4444/wd/hub --variable BROWSER:chrome web

# Run a specific suite inside the container
docker compose run --rm robot-tests robot --include @smoke web api

docker compose down -v
```

Chrome/Firefox nodes are given `shm_size: 2gb` - Docker's default 64MB
`/dev/shm` is a common cause of browser crashes under Selenium Grid.

The `robot-tests` image has no browser installed - it's a pure Grid client.
It does include a headless JRE and the Allure CLI so `allure generate` can
run inside the container too.

---

## CI/CD

**`ci.yml`** - runs on every push and PR:
- `lint` - `robocop check web api shared` + a check that `.env.example`
  contains no real-looking (non-placeholder) values
- `smoke-gate` (needs `lint`) - brings up a minimal Grid (hub + chrome),
  builds the `robot-tests` image from the `Dockerfile`, and runs
  `pabot --include @smoke` *inside that container* via
  `docker compose run --rm --no-deps robot-tests ...`, uploads raw Allure
  results
- `full-regression` (needs `smoke-gate`, PR only) - full Grid (chrome +
  firefox), runs everything inside the same `Dockerfile`-built container,
  generates the Allure report inside it too (`allure` is baked into the
  image), uploads the rendered report, comments the result on the PR

Both jobs run pabot and the Allure CLI inside the `Dockerfile` image rather
than installing Python/Robot/Allure directly on the runner - the runner's
only job is to orchestrate `docker compose` and shuttle cache/artifact files
in and out of the bind-mounted `reports/` and `.pabot-history/` directories.

**`nightly.yml`** - its `schedule` trigger is currently commented out (manual
`workflow_dispatch` only): full Grid run on Chrome then Firefox (both via
pabot, inside the same `Dockerfile` image as `ci.yml`), combined Allure
report published to GitHub Pages via the `gh-pages` branch, opens a GitHub
issue on failure. The `regression-grid` and `notify-on-failure` jobs declare
explicit `permissions:` (`contents: write` / `issues: write` respectively) -
without them the default read-only `GITHUB_TOKEN` causes the Pages deploy and
failure-issue steps to fail with a 403.

> **One-time manual step**: after `nightly.yml`'s first successful run
> creates the `gh-pages` branch, go to **Settings → Pages → Build and
> deployment → Source** and select the `gh-pages` branch. This can't be done
> from the workflow itself.

No secrets are configured or required: the web login credentials are
practice.expandtesting.com's own publicly documented demo credentials, and
the Notes API auth token is obtained dynamically at runtime via
registration + login rather than stored statically.

**`Jenkinsfile`** - an illustrative lint → smoke → Allure-report pipeline,
included to show the suite isn't tied to GitHub Actions; not wired to a live
Jenkins instance for this repo.

---

## Reporting

```bash
# Robot's native reports (always generated)
open reports/report.html
open reports/log.html

# Allure (richer, step-by-step, matches the sibling Playwright repo's reporting)
allure generate reports/allure-results --clean -o reports/allure-report
allure open reports/allure-report
```

`argfile.robot` wires the Allure listener in by default
(`--listener allure_robotframework:reports/allure-results`) and keeps
Robot's own `--report`/log.html as a debug aid alongside it.

---

## Coverage

| Module | Suite | Tests | Tags | Status |
|---|---|---|---|---|
| `web/login_suite` | login page | 4 + 4 (CSV) | `@smoke`, `@critical`, `@regression` | ✅ PASS |
| `web/dashboard_suite` | `/secure` area | 4 | `@smoke`, `@critical`, `@regression` | ✅ PASS |
| `api/smoke` | Notes API health/auth/CRUD | 5 | `@smoke`, `@critical` | ✅ PASS |
| `api/negative` | Notes API 401/404/400 | 5 | `@regression`, `@critical` | ✅ PASS |

22 test cases total, all passing as of the latest `full-regression` run (see
the CI badge above for current status). See
[docs/MIGRATION.md](docs/MIGRATION.md) for how this compares to the sibling
Playwright repo's coverage.

---

## Adding New Tests

See [docs/ADDING_TESTS.md](docs/ADDING_TESTS.md).

---

## Troubleshooting

**Element click intercepted by an ad iframe** - practice.expandtesting.com
renders live ad iframes that can overlap elements. Use
`Wait For Element And Click` (JS click) from
`web/resources/utilities/utility_keywords.robot`, not a raw `Click Element`.

**Selenium Grid node won't register / browser crashes in Docker** - check
`shm_size: 2gb` is set on the Chrome/Firefox services.

**DataDriver "Unassigned required argument" error** - the CSV's first column
header must be the literal string `*** Test Cases ***`, and comma-delimited
files need `dialect=excel` in the `Library DataDriver` import (its own
default dialect is semicolon-delimited).

**Tests timeout** - adjust `${default_timeout}` in
`shared/test_data/shared_testdata.robot`.

---

## Engineering Decisions

[docs/ENGINEERING_DECISIONS.md](docs/ENGINEERING_DECISIONS.md) records the
non-obvious calls behind this repo's CI/CD and test-execution setup as
decision records - problem, options, decision, tradeoff, evidence - rather
than leaving them implicit in config: why `--testlevelsplit` over per-suite
pabot splitting, why the Grid-readiness check needed a whitespace-tolerant
regex, why `.env.example` validation scans by key rather than by value, and
why this repo keeps Robot Framework rather than porting everything to the
sibling Playwright repo.

---

## License

MIT License - see LICENSE file for details.

## References

- [Robot Framework Documentation](https://robotframework.org/)
- [SeleniumLibrary Documentation](https://robotframework.org/SeleniumLibrary/)
- [RequestsLibrary Documentation](https://github.com/MarketSquare/robotframework-requests)
- [Robocop Documentation](https://robotframework-robocop.readthedocs.io/)
- [Allure Report](https://allurereport.org/)
