# Migration from Robot Framework to Playwright

## Context

This document describes a portfolio narrative, not a real historical
migration: this repo and its sibling,
`libin-samkutty-playwright-web-api-automation-ts`, are both built to target
the same real public site, https://practice.expandtesting.com, so that
together they tell a credible story about migrating browser automation from
Robot Framework to Playwright while keeping a stable legacy layer running.
Framing it honestly matters more than framing it dramatically - the value of
this pairing is in showing what a real migration decision process looks
like, not in inventing a fictional incident.

## What Robot Framework Owns

- `web/tests/login_suite/` - login page scenarios (valid credentials,
  invalid username, invalid password), including a CSV data-driven variant
- `web/tests/dashboard_suite/` - the post-login `/secure` area (authenticated
  load, session/redirect gating, logout)
- `api/tests/smoke/` - Notes API health check, registration/login/token flow,
  and note CRUD
- `api/tests/negative/` - 401 (missing/invalid token), 404 (unknown route),
  400 (validation), 401 (bad credentials)

22 test cases total across the two modules.

## What Playwright Replaced

The sibling Playwright repo owns everything that has grown since: 100+ test
cases across 13 domains (authentication flows beyond login, forms, advanced
UI interactions like drag-and-drop and file upload, browser APIs such as
shadow DOM and geolocation, dynamic DOM, network interception, the Notes App
UI, a broader Notes API suite, and observability checks), run with
Playwright's built-in parallelism, tracing, and cross-browser support
(Chromium/Firefox/WebKit) via one API, tagged into `@smoke`/`@critical`/
`@regression`/`@extended` tiers with sharded nightly/weekly runs.

## Why Not Replace Everything

The 22 Robot Framework tests in this repo are stable, have no flake history,
and cover exactly the flows they were written for. Rewriting them in
Playwright purely for tooling uniformity would be pure churn with no
regression-catching benefit - the opposite of what a migration budget should
be spent on. The API suite in particular is a genuinely good fit for Robot
Framework: RequestsLibrary plus DataDriver's CSV support cover HTTP smoke
and negative testing plainly and fast, with nothing Playwright's API testing
would meaningfully improve on for this scope. New feature work and anything
that benefits from Playwright's tracing, network mocking, or multi-browser
matrix goes to the Playwright repo instead; this repo keeps what is already
cheap to maintain.

## Note: chatbot module retirement

The original scope of this repo (before retargeting to
practice.expandtesting.com) included a `chatbot/` module that automated a
WhatsApp Web chat widget against a fictional dashboard product.
practice.expandtesting.com has no chatbot or chat-widget feature at all
(confirmed directly against the live site and its documentation). Rather
than fake or stub chatbot coverage against a real public site that does not
have the feature, the module was deleted outright when the SUT was
retargeted. This is a SUT-driven deletion, not a framework migration
decision - the right call here is "don't test a feature that doesn't exist,"
not "port it to Playwright anyway to preserve a module count."

## Migration Phases

- **Phase 1**: All new feature work goes to Playwright exclusively.
- **Phase 2**: Any high-churn or flaky UI suite (none currently exist in this
  repo) would migrate first, since that's where Playwright's tracing and
  auto-waiting pay off fastest.
- **Phase 3**: Remaining legacy suites are evaluated case-by-case for
  migrate-vs-retain. The API smoke/negative suites are flagged to retain in
  Robot Framework indefinitely per the cost/benefit above.

## Current State

| | Robot Framework (this repo) | Playwright (sibling repo) |
|---|---|---|
| Test cases | 22 | 100+ |
| Domains covered | Login, secure area, Notes API smoke + negative | Auth, forms, advanced UI, browser APIs, dynamic DOM, network, Notes App UI, Notes API, Practice API, observability |
| Browsers | Chrome, Firefox (via Selenium Grid) | Chromium, Firefox, WebKit |
| Tag tiers | `@smoke`, `@critical`, `@regression` | `@smoke`, `@critical`, `@regression`, `@extended` |
| CI cadence | Every push/PR (smoke + full-regression), nightly Grid regression | Smoke every push, critical every PR, regression nightly, extended weekly |
