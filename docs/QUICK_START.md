# Quick Start Guide

Get the test suite running against https://practice.expandtesting.com in 5 minutes.

## Prerequisites

- Python 3.10+
- Git
- A local Chrome or Firefox install (for running `web/` outside Docker) - or
  Docker + Docker Compose (to run against a Selenium Grid instead)

## Installation

```bash
python -m venv .venv
source .venv/bin/activate      # .venv\Scripts\activate on Windows

pip install -r requirements.txt

cp .env.example .env
```

## Configuration

`.env.example` already defaults to the real target site and its publicly
documented practice credentials - no real secrets are required:

```bash
BASE_URL=https://practice.expandtesting.com
NOTES_API_URL=https://practice.expandtesting.com/notes/api
DEFAULT_USERNAME=practice
DEFAULT_PASSWORD=SuperSecretPassword!
```

## Running Tests

```bash
# API tests - fastest feedback, no browser needed
robot api/tests/

# Web tests - uses a local browser driver by default
robot --variable BROWSER:Chrome web/tests/

# Everything, filtered to the smoke tier
robot --include @smoke web api

# Against a Selenium Grid instead of a local driver (see docker-compose.yml)
robot --variable REMOTE_URL:http://localhost:4444/wd/hub --variable BROWSER:chrome web
```

## Running Against Selenium Grid via Docker Compose

```bash
docker compose up -d selenium-hub chrome firefox
docker compose run --rm robot-tests
docker compose down -v
```

## View Results

```bash
open reports/report.html      # Robot's native report
open reports/log.html         # keyword-level debug log

# Allure (richer, step-by-step report)
allure generate reports/allure-results --clean -o reports/allure-report
allure open reports/allure-report
```

## Learning the Project

1. **Understand Architecture**: Read `docs/POM_ARCHITECTURE.md`
2. **Add New Tests**: Follow `docs/ADDING_TESTS.md`
3. **Why this repo is scoped the way it is**: Read `docs/MIGRATION.md`

## Key Files to Know

- `argfile.robot` - Default test arguments (tags, Allure listener, output dir)
- `shared/` - Cross-module keywords and test data (env resolution, timeouts, assertions)
- `web/data/locators/` - UI element selectors
- `web/resources/pages/*/action.robot` - user actions
- `web/resources/pages/*/result.robot` - assertions
- `api/resources/common_resources.robot` - Notes API session/auth/CRUD keywords
- `web/tests/`, `api/tests/` - test cases

## Common Commands

```bash
# Run by priority tag
robot --include @smoke web api
robot --include @critical web api
robot --include @regression web api

# Verbose output
robot --loglevel DEBUG web/tests/

# Run a specific test
robot -t "Verify User Can Login With Valid Credentials" web/tests/login_suite/login_page_test.robot

# Combine multiple runs (e.g. Chrome + Firefox passes) into one report
rebot --merge reports/web/output.xml reports/web-firefox/output.xml
```

## Troubleshooting

Browser not found?
```bash
# Selenium Manager (bundled with Selenium 4.6+) auto-resolves a matching
# driver for a locally installed Chrome/Firefox - no manual driver install
# needed for local runs. For Docker/CI, the Grid supplies the browser instead.
```

Element click intercepted by an ad iframe?
```bash
# practice.expandtesting.com renders live ad iframes that can overlap
# elements. shared/.../utility_keywords.robot's `Wait For Element And Click`
# clicks via JavaScript specifically to avoid this - use it instead of the
# raw `Click Element` keyword.
```

Selenium Grid node won't register / browser crashes in Docker?
```bash
# Chrome/Firefox need more than Docker's default 64MB /dev/shm.
# docker-compose.yml already sets shm_size: 2gb on both nodes - if you're
# running the images another way, set this explicitly.
```

## Project Structure

```
robotframework-dashboard-ui-tests-demo/
├── web/          Web UI tests (login, secure/dashboard area)
├── api/          Notes API tests (smoke, negative)
├── shared/       Cross-module keywords and test data
├── docs/         Documentation
├── argfile.robot Default arguments
└── .env.example  Configuration template
```

## What's Included

- Web: login suite (4 tests + 4 data-driven CSV scenarios), secure-area suite (4 tests)
- API: Notes API smoke (5 tests), negative (5 tests)
- Selenium Grid via Docker Compose, Allure reporting, Robocop linting in CI

## Ready to Go

```bash
robot --argumentfile argfile.robot web/tests/login_suite/login_page_test.robot
```

Check `reports/report.html` for results.
