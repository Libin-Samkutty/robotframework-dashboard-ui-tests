# Page Object Model Architecture

This project follows the Page Object Model (POM) pattern for test automation.
The architecture separates concerns into four layers: Shared, Data, Resources,
and Tests.

## Layers

### Layer 0: Shared (`shared/`)
Cross-module keywords and test data used by both `web/` and `api/`, so
environment resolution, timeouts, and generic assertions are defined exactly
once instead of duplicated per module.

- `keywords/common_keywords.robot` - environment/base-URL resolution, browser
  open/navigate, screenshot/teardown helpers, unique test-user generation
- `keywords/assertion_keywords.robot` - generic wait-then-assert wrappers used
  by both the Selenium (web) and Requests (api) layers
- `test_data/shared_testdata.robot` - `${BASE_URL}`, `${ENV}`, `${BROWSER}`,
  `${REMOTE_URL}`, and timeout variables

### Layer 1: Data (`*/data/`)
Static test data, locators, and configuration - no logic.

- `locators/` - UI element selectors
- `testdata/` - CSV files and environment-specific data
- `common_properties.robot` - module-specific configuration variables

### Layer 2: Resources (`*/resources/`)
Reusable keywords organized by functionality.

- `pages/*/action.robot` - keywords that interact with the UI (click, type)
- `pages/*/result.robot` - keywords that assert and verify state
- `utilities/` - helper keywords for common operations
- `common_resources.robot` - shared setup/teardown and session keywords

Keywords are named as high-level, user-centric actions, not technical
operations.

### Layer 3: Tests (`*/tests/`)
Test cases that compose resource-layer keywords into scenarios.

## Module Structure

### Web Module

```
web/
├── data/
│   ├── locators/
│   │   ├── login_page_locators.robot
│   │   └── dashboard_page_locators.robot   # models the /secure page
│   ├── testdata/
│   │   ├── login_credentials.csv
│   │   ├── stage/
│   │   │   └── stage_testdata.robot
│   │   └── prod/
│   │       └── prod_testdata.robot
│   └── common_properties.robot
├── resources/
│   ├── pages/
│   │   ├── login_resource/
│   │   │   ├── login_action.robot
│   │   │   └── login_result.robot
│   │   └── dashboard_resource/             # secure-area actions/results
│   │       ├── dashboard_action.robot
│   │       └── dashboard_result.robot
│   ├── utilities/
│   │   └── utility_keywords.robot
│   └── common_resources.robot
└── tests/
    ├── login_suite/
    │   ├── login_page_test.robot
    │   └── login_data_driven_test.robot
    └── dashboard_suite/
        └── dashboard_page_test.robot
```

### API Module

```
api/
├── data/
│   ├── common_properties.robot
│   └── testdata/
│       └── common_error_messages.robot
├── resources/
│   ├── utilities/
│   │   └── utility_keywords.robot
│   └── common_resources.robot              # Notes API session/auth/CRUD
└── tests/
    ├── smoke/
    │   └── Verify_Smoke_Scenarios.robot
    └── negative/
        └── Verify_Error_Responses.robot
```

There is no chatbot module - see `docs/MIGRATION.md` for why it was retired
when the system under test was retargeted to practice.expandtesting.com.

## Best Practices Applied

### 1. Locator Centralization
All UI selectors are defined in dedicated locators files, verified against
the real DOM.

```robot
# web/data/locators/login_page_locators.robot
${LOGIN_USERNAME_FIELD}                     id:username
${LOGIN_PASSWORD_FIELD}                     id:password
${LOGIN_SUBMIT_BUTTON}                      id:submit-login
```

### 2. Action/Result Separation

```robot
# web/resources/pages/login_resource/login_action.robot
User Enters Username
    [Arguments]        ${username}
    Wait For Element And Type    ${LOGIN_USERNAME_FIELD}    ${username}

# web/resources/pages/login_resource/login_result.robot
Login Page Should Load Successfully
    Element Should Be Visible    ${LOGIN_USERNAME_FIELD}
    Element Should Be Visible    ${LOGIN_PASSWORD_FIELD}
    Element Should Be Visible    ${LOGIN_SUBMIT_BUTTON}
```

### 3. Return Values Over Globals
Keywords return data instead of setting global variables (the one deliberate
exception is a suite-scoped auth token shared across an API suite's tests -
see `api/resources/common_resources.robot :: Set Auth Token`).

### 4. Keyword Naming Convention
Keywords are named from the user's perspective: `User Logs In With Username
And Password`, not `Input Text Into Username Field`.

### 5. Test Data via Environment Variables
Test data reads from the OS environment with sensible defaults, so `.env`,
Docker's `env_file`, or CI secrets all flow through without code changes:

```robot
# shared/test_data/shared_testdata.robot
${BASE_URL}                                 %{BASE_URL=https://practice.expandtesting.com}
${BROWSER}                                  %{BROWSER=Chrome}

# web/data/testdata/stage/stage_testdata.robot
${login_username}                           %{DEFAULT_USERNAME=practice}
${login_password}                           %{DEFAULT_PASSWORD=SuperSecretPassword!}
```

### 6. Three-Level Keyword Composition

```robot
# Level 3 (Test)
Given User Opens The Login Page

# Level 2 (Resource - action)
User Opens The Login Page
    [Arguments]    ${env}=${ENV}
    Open Browser To Application    path=/login    env=${env}

# Level 1 (shared keyword, wraps SeleniumLibrary)
Open Browser To Application
    ...
    Open Browser    ${base}${path}    ${browser}    remote_url=${REMOTE_URL}
```

### 7. Environment Parameterization
`${ENV}` (STAGING/PROD) is retained structurally to demonstrate the pattern,
but both values resolve to the same real `${BASE_URL}` today - there is one
real target site. See `shared/keywords/common_keywords.robot ::
Resolve Base URL For Environment`.

### 8. Data-Driven Testing

```robot
# web/data/testdata/login_credentials.csv
*** Test Cases ***,${username},${password},${expected_outcome},${test_tag}
Valid login,practice,SuperSecretPassword!,secure,@smoke
Invalid username,not_a_real_user,SuperSecretPassword!,invalid_username,@regression
```

Note the first column header must be the literal string `*** Test Cases ***`
for the DataDriver library to recognize it as the test-name column, and the
`Library DataDriver` import needs `dialect=excel` for comma-delimited files -
DataDriver's own default dialect is semicolon-delimited (`Excel-EU`).

### 9. Secrets Management
No real secrets exist for this SUT: the web login credentials are the
publicly documented practice.expandtesting.com demo credentials, and the
Notes API token is obtained dynamically at runtime via registration+login,
never stored statically. `.env.example` documents the variable names without
implying any of them are sensitive.

## Import Hierarchy

```robot
# Tests import Resources (action/result)
Resource    ../../resources/pages/login_resource/login_action.robot
Resource    ../../resources/pages/login_resource/login_result.robot

# Resources import Data and Shared
Resource    ../../data/locators/login_page_locators.robot
Resource    ../../../shared/keywords/common_keywords.robot

# Resources import other Resources/utilities
Resource    ../utilities/utility_keywords.robot
```

## Maintenance Guidelines

When adding new tests, see `docs/ADDING_TESTS.md`.

When modifying UI:

1. Update only the locator file (`data/locators/*.robot`)
2. Action/result keywords automatically use the updated locator
3. Tests are unaffected
