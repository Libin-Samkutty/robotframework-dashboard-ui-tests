# System Architecture

This document shows how the pieces in this repo actually connect at runtime
and in CI - the Selenium Grid, the Docker network, the pabot parallel run,
and the Allure reporting pipeline. For the code-level Page Object Model
layering (`shared/` → `data/` → `resources/` → `tests/`), see
[docs/POM_ARCHITECTURE.md](POM_ARCHITECTURE.md).

## Runtime: Docker Compose network

```mermaid
flowchart LR
    subgraph net["Docker network (docker-compose.yml)"]
        Hub["selenium-hub\n:4442/4443/4444"]
        Chrome["node-chrome\nshm_size 2gb, 3 sessions"]
        Firefox["node-firefox\nshm_size 2gb, 3 sessions"]
        Runner["robot-tests container\n(no browser installed)"]
    end

    Runner -- "REMOTE_URL=http://selenium-hub:4444/wd/hub" --> Hub
    Hub -- registers --> Chrome
    Hub -- registers --> Firefox
    Chrome -- "WebDriver session" --> SUT["practice.expandtesting.com\n(real public site)"]
    Firefox -- "WebDriver session" --> SUT
    Runner -- "RequestsLibrary (no Grid hop)" --> SUT
    Runner -- "--listener allure_robotframework" --> Results["reports/allure-results/"]
    Results --> CLI["allure generate"]
    CLI --> Report["reports/allure-report/"]
```

`robot-tests` is a pure Grid client - it has no browser of its own, only a
headless JRE and the Allure CLI (see `Dockerfile`). API tests bypass the Grid
entirely: `RequestsLibrary` talks to `practice.expandtesting.com` directly,
so `api/` tests never consume a Grid session slot.

## CI/CD: `ci.yml` (push / PR)

```mermaid
flowchart TD
    Trigger["push to main/feature/**\nor PR to main"] --> Lint["lint\nrobocop + .env.example\ncredential-key scan"]
    Lint --> Smoke["smoke-gate\ndocker compose up: hub + chrome"]
    Smoke --> Order1["generate_pabot_ordering.py\n(longest-first, from cached history)"]
    Order1 --> Run1["pabot --testlevelsplit --pabotlib\n--processes 3 --include @smoke"]
    Run1 --> Artifact1["upload allure-results-smoke"]
    Artifact1 --> Gate{"event == pull_request?"}
    Gate -- no --> Stop1(("done"))
    Gate -- yes --> Full["full-regression\ndocker compose up: hub + chrome + firefox"]
    Full --> Order2["generate_pabot_ordering.py"]
    Order2 --> Run2["pabot --testlevelsplit --pabotlib\n--processes 3 (all tests)"]
    Run2 --> Report["allure generate\n(Allure CLI)"]
    Report --> Comment["PR comment: PASSED / FAILED"]
```

Both Grid-dependent jobs share the same shape: create `.env` → pull images →
bring up the Grid → wait for hub readiness → run pabot → tear down (`if:
always()`), with a `Dump Grid container status/logs on failure` step so a red
run comes with hub/node logs attached instead of just a timeout message. See
[ENGINEERING_DECISIONS.md](ENGINEERING_DECISIONS.md) for why several of these
steps exist.

## Nightly: `nightly.yml` (scheduled / manual dispatch)

```mermaid
flowchart TD
    Cron["02:00 UTC schedule\n(or manual dispatch)"] --> GridUp["docker compose up:\nhub + chrome + firefox"]
    GridUp --> Chrome["robot web\n(BROWSER=chrome)"]
    GridUp --> Api["robot api\n(no Grid slot needed)"]
    GridUp --> Firefox["robot web\n(BROWSER=firefox)"]
    Chrome & Api & Firefox --> Combine["allure generate\n(combined report)"]
    Combine --> Pages["deploy to gh-pages branch\n(GitHub Pages)"]
    Chrome & Api & Firefox -. on failure .-> Issue["open a GitHub issue\n(ci-failure, nightly labels)"]
```

Nightly runs both browsers against the same `web/` suite for a genuine
cross-browser regression pass, then publishes one combined Allure report so a
failure anywhere in the run is visible from a single link rather than three
separate artifacts.

## Test execution: pabot parallelism

```mermaid
flowchart LR
    Suite["web + api test cases\n(22 total)"] --> Split["pabot --testlevelsplit\n(one pabot item per test case,\nnot per suite file)"]
    Split --> W1["worker 1"]
    Split --> W2["worker 2"]
    Split --> W3["worker 3"]
    W1 & W2 & W3 --> Lib["PabotLib\nRun Only Once:\nEnsure Shared API Test User"]
    Lib --> Merge["merged output.xml\n+ allure-results"]
```

`--testlevelsplit` is used instead of per-suite splitting because this repo
only has 4 suite files - per-suite splitting would cap parallelism at 4
workers regardless of how many test cases exist, where per-test splitting
scales with test count instead. `PabotLib`'s `Run Only Once` keeps the shared
API test user registered exactly once across however many worker processes
run, even though each is its own isolated `robot` subprocess with no shared
suite-level state. See
[ENGINEERING_DECISIONS.md](ENGINEERING_DECISIONS.md#adr-001-testlevelsplit-over-per-suite-splitting)
for the full reasoning.
