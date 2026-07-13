# Spec 01 — robot-framework-automation

## Purpose in the Portfolio

This repo represents the **legacy enterprise automation layer** of the
HealthSaaS platform. It demonstrates that you can maintain and extend
a mature Robot Framework codebase — including structured POM, data-driven
tests, API automation, and a chatbot widget layer — while preparing it
for a parallel migration to Playwright.

The existence of this repo alongside the Playwright repo is what makes
the migration story credible. Without both ends, the story cannot be told.

---

## Portfolio Narrative (for README)

> "Robot Framework was the primary test automation framework for the
> HealthSaaS platform. It owned UI regression for the web dashboard,
> smoke testing for the REST API layer, and basic validation of the
> chatbot widget embedded in the dashboard. As the product matured and
> Playwright was adopted for new browser automation, Robot continued
> running legacy suites during the transition period. This repo
> represents the state of the Robot platform at migration handoff —
> maintained, documented, and CI-green."

---

## Source Repo

`robotframework-dashboard-ui-tests-demo`

Already contains:
- Web UI tests: login suite (data-driven), dashboard suite
- API tests: smoke + negative (error responses)
- Chatbot tests: chatbot widget smoke suite
- POM architecture: action/result split per page
- Docker + docker-compose
- GitHub Actions CI pipeline
- `.env.example`

---

## System Under Test

Primary: `practice.expandtesting.com`

| Suite | Target | Tests |
|-------|--------|-------|
| web/login | /login page | Valid login, invalid credentials, locked user, data-driven CSV |
| web/dashboard | /secure page | Authenticated page load, session validation |
| api/smoke | practice.expandtesting.com/notes/api | Health check, auth, CRUD smoke |
| api/negative | Same | 401, 404, validation errors |
| chatbot | Chatbot widget on dashboard | Onboarding flow, keyword recognition |

Use the same target as the Playwright repo. This is intentional —
a reviewer seeing both repos target the same app immediately understands
the migration narrative.

---

## Final Directory Structure

```
robot-framework-automation/
│
├── web/
│   ├── data/
│   │   ├── common_properties.robot
│   │   ├── locators/
│   │   │   ├── login_page_locators.robot
│   │   │   └── dashboard_page_locators.robot
│   │   └── testdata/
│   │       ├── login_credentials.csv
│   │       ├── stage/
│   │       │   └── stage_testdata.robot
│   │       └── prod/
│   │           └── prod_testdata.robot
│   ├── resources/
│   │   ├── common_resources.robot
│   │   ├── pages/
│   │   │   ├── login_resource/
│   │   │   │   ├── login_action.robot
│   │   │   │   └── login_result.robot
│   │   │   └── dashboard_resource/
│   │   │       ├── dashboard_action.robot
│   │   │       └── dashboard_result.robot
│   │   └── utilities/
│   │       └── utility_keywords.robot
│   └── tests/
│       ├── login_suite/
│       │   ├── login_page_test.robot
│       │   └── login_data_driven_test.robot
│       └── dashboard_suite/
│           └── dashboard_page_test.robot
│
├── api/
│   ├── data/
│   │   ├── common_properties.robot
│   │   └── testdata/
│   │       └── common_error_messages.robot
│   ├── resources/
│   │   ├── common_resources.robot
│   │   └── utilities/
│   │       └── utility_keywords.robot
│   └── tests/
│       ├── smoke/
│       │   └── Verify_Smoke_Scenarios.robot
│       └── negative/
│           └── Verify_Error_Responses.robot
│
├── chatbot/
│   ├── data/
│   │   ├── common_properties.robot
│   │   ├── locators/
│   │   │   └── chatbot_page_locators.robot
│   │   └── testdata/
│   │       └── stage_testdata.robot
│   ├── resources/
│   │   ├── common_resources.robot
│   │   └── smoke_suite_resource.robot
│   └── tests/
│       └── smoke/
│           └── Verify_Smoke_Suite.robot
│
├── shared/
│   ├── keywords/
│   │   ├── common_keywords.robot
│   │   └── assertion_keywords.robot
│   └── test_data/
│       └── shared_testdata.robot
│
├── reports/                        <- Allure output (gitignored)
│
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml          <- Selenium Grid + Robot + Allure
│
├── .github/
│   └── workflows/
│       ├── ci.yml                  <- Smoke on push, full on PR
│       └── nightly.yml             <- Full regression with Selenium Grid
│
├── docs/
│   ├── QUICK_START.md
│   ├── POM_ARCHITECTURE.md
│   ├── MIGRATION.md                <- NEW: why Playwright was adopted
│   └── ADDING_TESTS.md
│
├── argfile.robot
├── requirements.txt
├── pytest.ini                      <- if using pytest-robot runner
├── .env.example
├── Jenkinsfile                     <- Optional: parallel CI story
├── _REFERENCE_gitingest.txt        <- Original Gitingest dump
└── README.md
```

---

## Key Patterns to Demonstrate

### 1. Page Object Model — Action/Result Split

Each page has two resource files: actions (what you do) and results
(what you assert). This is the Robot Framework equivalent of POM.

```robot
# pages/login_resource/login_action.robot
*** Keywords ***
Enter Username
    [Arguments]    ${username}
    Input Text    ${LOGIN_USERNAME_FIELD}    ${username}

Enter Password
    [Arguments]    ${password}
    Input Text    ${LOGIN_PASSWORD_FIELD}    ${password}

Click Login Button
    Click Element    ${LOGIN_SUBMIT_BUTTON}
```

```robot
# pages/login_resource/login_result.robot
*** Keywords ***
Verify Login Success
    Wait Until Element Is Visible    ${DASHBOARD_HEADER}
    Element Should Be Visible        ${DASHBOARD_HEADER}

Verify Login Error
    [Arguments]    ${expected_message}
    Element Should Contain    ${LOGIN_ERROR_MSG}    ${expected_message}
```

### 2. Data-Driven Testing via CSV

```robot
# tests/login_suite/login_data_driven_test.robot
*** Test Cases ***
Login Data Driven Tests
    [Template]    Login With Credentials
    [Tags]    @smoke    @critical
    ${VALID_USER}       ${VALID_PASS}       success
    ${INVALID_USER}     ${VALID_PASS}       Your username is invalid
    ${VALID_USER}       ${INVALID_PASS}     Your password is invalid
```

### 3. Allure Reporting Integration

Add to requirements.txt:
```
allure-robotframework==2.13.5
```

Add to test run command:
```bash
robot --listener allure_robotframework \
      --outputdir reports/ \
      tests/
```

Generate Allure report:
```bash
allure generate reports/allure-results --clean -o reports/allure-report
allure open reports/allure-report
```

### 4. Selenium Grid via Docker Compose

```yaml
# docker/docker-compose.yml
version: "3.8"
services:
  selenium-hub:
    image: selenium/hub:4.18.1
    ports:
      - "4444:4444"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4444/wd/hub/status"]
      interval: 10s
      timeout: 5s
      retries: 5

  chrome:
    image: selenium/node-chrome:4.18.1
    depends_on:
      selenium-hub:
        condition: service_healthy
    environment:
      SE_EVENT_BUS_HOST: selenium-hub
      SE_EVENT_BUS_PUBLISH_PORT: 4442
      SE_EVENT_BUS_SUBSCRIBE_PORT: 4443
      SE_NODE_MAX_SESSIONS: 3

  firefox:
    image: selenium/node-firefox:4.18.1
    depends_on:
      selenium-hub:
        condition: service_healthy
    environment:
      SE_EVENT_BUS_HOST: selenium-hub
      SE_EVENT_BUS_PUBLISH_PORT: 4442
      SE_EVENT_BUS_SUBSCRIBE_PORT: 4443

  robot-tests:
    build:
      context: ..
      dockerfile: docker/Dockerfile
    depends_on:
      selenium-hub:
        condition: service_healthy
    environment:
      SELENIUM_URL: http://selenium-hub:4444/wd/hub
      BASE_URL: https://practice.expandtesting.com
    volumes:
      - ../reports:/app/reports
    command: >
      robot
      --variable REMOTE_URL:http://selenium-hub:4444/wd/hub
      --variable BROWSER:chrome
      --listener allure_robotframework
      --outputdir /app/reports
      tests/
```

### 5. MIGRATION.md — The Narrative Document

This is the most important document in the repo for portfolio purposes.
Content outline:

```markdown
# Migration from Robot Framework to Playwright

## Context
[When and why migration was initiated]

## What Robot Framework Owns
[Suites retained in Robot — API tests, legacy UI suites, chatbot widget]

## What Playwright Replaced
[New browser automation — parallel execution, network interception,
tracing, modern JS tooling, cross-browser on single API]

## Why Not Replace Everything
[Cost/benefit: stable Robot suites have no ROI to rewrite,
API tests in Robot are fast and maintainable,
gradual migration reduces risk]

## Migration Phases
[Phase 1: New features go to Playwright]
[Phase 2: High-churn UI suites migrated]
[Phase 3: Legacy suites evaluated for migration vs. retirement]

## Current State
[Robot owns: X suites covering Y test cases]
[Playwright owns: X suites covering Y test cases]
```

---

## CI/CD Pipeline

### GitHub Actions — ci.yml

```
Trigger: push to main, push to feature/*, pull_request to main

Jobs:
  lint
    → rflint (Robot Framework linter)
    → check .env.example has no real values

  smoke-gate  [needs: lint]
    → docker-compose up selenium-hub chrome
    → run web/tests/login_suite/ --include @smoke
    → upload Allure results artefact
    → docker-compose down

  full-regression  [needs: smoke-gate, on PR only]
    → docker-compose up (full Grid)
    → run all suites (web + api + chatbot)
    → generate Allure report
    → upload report artefact
    → docker-compose down
```

### GitHub Actions — nightly.yml

```
Trigger: schedule 02:00 UTC

Jobs:
  regression-grid
    → docker-compose up (Chrome + Firefox)
    → parallel execution: web suite on Chrome, api suite on Firefox
    → generate Allure report
    → deploy to GitHub Pages
    → notify on failure (GitHub issue or Slack webhook — optional)
```

### Jenkinsfile (Optional — adds CI diversity story)

```groovy
pipeline {
  agent { docker { image 'python:3.11-slim' } }
  stages {
    stage('Install') { steps { sh 'pip install -r requirements.txt' } }
    stage('Smoke') {
      steps {
        sh 'robot --include smoke --outputdir reports/ tests/'
      }
    }
    stage('Report') {
      steps {
        sh 'allure generate reports/allure-results -o reports/allure-report'
      }
      post { always { archiveArtifacts 'reports/allure-report/**' } }
    }
  }
}
```

---

## Reporting Stack

| Tool | Purpose | Output |
|------|---------|--------|
| allure-robotframework | Test result listener | allure-results/ |
| Allure CLI | Report generation | allure-report/ |
| GitHub Actions artefact | CI report storage | 7-day retention |
| GitHub Pages | Persistent report hosting | Auto-deployed on nightly |
| Robot built-in log.html | Debug aid | Kept alongside Allure |

---

## What Already Exists (from source repo)

- Full web test suite (login + dashboard) ✅
- Full API test suite (smoke + negative) ✅
- Chatbot test suite ✅
- POM action/result architecture ✅
- Docker + docker-compose (basic) ✅
- GitHub Actions CI ✅
- .env.example ✅
- Documentation (QUICK_START, POM_ARCHITECTURE, ADDING_TESTS) ✅

---

## What Needs to Be Built

In priority order:

1. Add `allure-robotframework` to requirements.txt and wire into all
   test run commands
2. Rebuild docker-compose.yml with Selenium Grid (hub + chrome + firefox
   + robot-tests service)
3. Update Dockerfile for the robot-tests service to include Allure CLI
4. Rewrite CI pipeline (ci.yml) with lint → smoke → full-regression gates
5. Add nightly.yml with GitHub Pages deployment
6. Write MIGRATION.md (the narrative document — one page minimum)
7. Add shared/ directory with common_keywords.robot and
   assertion_keywords.robot (currently duplicated across web/api/chatbot)
8. Update README to match portfolio README structure from master plan
9. Add @smoke, @critical, @regression tags to all test cases
   (currently uses different tagging or none)
10. Optional: Add Jenkinsfile for CI diversity

---

## Roadmap Note: Eventual Full Retirement (Not Built This Pass)

This repo's narrative currently ends at "Robot retains API automation and
the chatbot widget while Playwright takes over UI" — a permanent-sounding
split. The fuller, real story doesn't stop there: Robot Framework's
remaining role (its API regression suite) was itself eventually retired
years later, on a measured trigger — a routine dependency conflict in a
shared Docker base image — rather than a theoretical one. The suite was
ported into an existing Pytest fixture layer via a POC on the
highest-traffic cases first, then run side-by-side with the old suite for
one full release cycle to confirm zero divergence before decommissioning
anything.

This is documented here only as a forward reference so this spec doesn't
contradict that fuller arc once it's built out — no build work for a
Pytest port, a parallel-run comparison, or a decommissioning step is
scoped in this pass. Robot Framework itself also continues, separately,
as an org-wide API automation base framework outside this specific
platform's scope — that continuity is unaffected by this platform's own
retirement.

---

## Definition of Done

- [ ] `docker-compose up` runs all tests headlessly against Selenium Grid
- [ ] Allure report is generated and readable with test steps visible
- [ ] CI pipeline has at minimum two stages: lint + smoke
- [ ] CI badge in README links to Actions and shows green
- [ ] MIGRATION.md exists and tells a coherent story
- [ ] All test cases have at least one of: @smoke, @critical, @regression
- [ ] No hardcoded credentials anywhere — all via .env
- [ ] README badge row + architecture diagram + coverage table complete
