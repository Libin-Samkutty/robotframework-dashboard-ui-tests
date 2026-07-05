# Adding New Tests Following POM

Step-by-step guide for adding new test suites while maintaining Page Object
Model integrity.

## Adding Web UI Tests

### Step 1: Create Locator File

Create `web/data/locators/feature_page_locators.robot`:

```robot
*** Variables ***

# Feature Page Locators
${FEATURE_BUTTON}                           id:feature-btn
${FEATURE_INPUT}                            id:feature-input
${FEATURE_RESULT}                           xpath://div[@data-testid='result']
```

### Step 2: Create Action Keywords

Create `web/resources/pages/feature_resource/feature_action.robot`:

```robot
*** Settings ***
Library    SeleniumLibrary
Resource    ../../../data/locators/feature_page_locators.robot
Resource    ../../../data/common_properties.robot
Resource    ../../utilities/utility_keywords.robot

*** Keywords ***

User Clicks Feature Button
    [Documentation]    Click the feature button
    Wait For Element And Click    ${FEATURE_BUTTON}

User Enters Feature Input
    [Documentation]    Enter text in the feature input field
    [Arguments]        ${text}
    Wait For Element And Type    ${FEATURE_INPUT}    ${text}
```

### Step 3: Create Result Keywords

Create `web/resources/pages/feature_resource/feature_result.robot`:

```robot
*** Settings ***
Library    SeleniumLibrary
Resource    ../../../data/locators/feature_page_locators.robot
Resource    ../../../../shared/keywords/assertion_keywords.robot

*** Keywords ***

Feature Result Should Contain
    [Documentation]    Verify the feature result contains the expected text
    [Arguments]        ${expected_text}
    Element Should Be Visible And Contain Text    ${FEATURE_RESULT}    ${expected_text}
```

### Step 4: Create Test File

Create `web/tests/feature_suite/feature_test.robot`:

```robot
*** Settings ***
Library    SeleniumLibrary

Resource    ../../data/common_properties.robot
Resource    ../../resources/pages/feature_resource/feature_action.robot
Resource    ../../resources/pages/feature_resource/feature_result.robot
Resource    ../../../shared/keywords/common_keywords.robot

Test Teardown     Capture Screenshot If Test Failed
Suite Teardown    Close All Test Browsers

*** Test Cases ***

Verify Feature Works
    [Tags]    @smoke    Feature
    [Documentation]    Verify feature basic functionality

    User Clicks Feature Button
    User Enters Feature Input    test value

    Feature Result Should Contain    test value
```

Every test case must carry at least one of `@smoke`, `@critical`, or
`@regression` - these are the tags CI filters on.

## Adding API Tests

### Step 1: Add Keywords

Add to `api/resources/common_resources.robot` (or a new module-specific
resource file if the endpoint belongs to a different API):

```robot
Get Feature By Id
    [Documentation]    Retrieve a feature by id
    [Arguments]        ${feature_id}
    ${headers}=    Create Auth Headers
    ${response}=    GET On Session    ${api_session_name}    /features/${feature_id}    headers=${headers}    expected_status=any
    RETURN    ${response}
```

### Step 2: Create Test File

Create `api/tests/feature/Verify_Feature_Scenarios.robot`:

```robot
*** Settings ***
Documentation    Feature endpoint smoke scenarios

Library    Collections
Library    RequestsLibrary

Resource    ../../resources/common_resources.robot
Resource    ../../../shared/keywords/assertion_keywords.robot

Suite Setup       Create Notes API Session
Suite Teardown    Close API Session

*** Test Cases ***

Verify Get Feature Returns 200
    [Tags]    @smoke    Feature

    ${response}=    Get Feature By Id    feature-123
    Response Should Have Status Code    ${response}    ${success_200}
    Response Body Should Contain Keys    ${response}    id    name
```

## Adding Data-Driven Tests

### Step 1: Create CSV File

Create `web/data/testdata/feature_scenarios.csv`. The first column header
must be the literal string `*** Test Cases ***` (DataDriver uses it to
identify the test-name column):

```
*** Test Cases ***,${input},${expected_result}
Valid input,test value,success
Empty input,,error
```

### Step 2: Create Template Keyword

```robot
Verify Feature With Input
    [Documentation]    Template keyword for feature data-driven tests
    [Arguments]        ${input}    ${expected_result}
    [Tags]    DataDriven    Feature    @regression

    User Enters Feature Input    ${input}
    User Clicks Feature Button

    IF    '${expected_result}' == 'success'
        Feature Result Should Contain    ${input}
    ELSE
        Feature Error Should Be Visible
    END
```

### Step 3: Create Test File with DataDriver

Comma-delimited CSVs need `dialect=excel` - DataDriver's own default dialect
is semicolon-delimited (`Excel-EU`):

```robot
*** Settings ***
Library    SeleniumLibrary
Library    DataDriver    file=../../data/testdata/feature_scenarios.csv    dialect=excel

Resource    ../../data/common_properties.robot
Resource    ../../resources/pages/feature_resource/feature_action.robot
Resource    ../../resources/pages/feature_resource/feature_result.robot
Resource    ../../../shared/keywords/common_keywords.robot

Test Template     Verify Feature With Input
Test Teardown     Capture Screenshot If Test Failed
Suite Teardown    Close All Test Browsers

*** Test Cases ***
Verify Feature With Input    ${input}    ${expected_result}
```

## Best Practices Checklist

### Locators
- [ ] All UI selectors in a dedicated locator file
- [ ] No hardcoded XPath/CSS in action/result keywords
- [ ] Locators verified against the real DOM, not guessed

### Keywords
- [ ] Action keywords use "User [verb]..." naming
- [ ] Result keywords use "... Should ..." naming
- [ ] Keywords have `[Documentation]`
- [ ] Keywords return values, not `Set Global Variable`
- [ ] Cross-module logic goes in `shared/`, not duplicated per module

### Tests
- [ ] Meaningful test names describing the scenario
- [ ] At least one of `@smoke` / `@critical` / `@regression`
- [ ] `[Documentation]` explaining the test's purpose

### Data
- [ ] Test data in `data/testdata/*.robot`, not hardcoded in resources
- [ ] Values that could vary by deployment read via `%{VAR=default}`
- [ ] No real secrets - if a real secret is ever needed, it belongs in `.env`
      only, never committed

### Imports
- [ ] Tests import Resources (action/result)
- [ ] Resources import Data and `shared/`
- [ ] No circular imports

## Running New Tests

```bash
robot web/tests/feature_suite/feature_test.robot
robot web/tests/feature_suite/feature_data_driven_test.robot
robot --include @smoke web/tests/feature_suite/
```

## Common Mistakes to Avoid

1. **Locators in keywords** - never hardcode selectors in action/result keywords
2. **Global variables** - use `RETURN` instead of `Set Global Variable`
3. **Duplicated cross-module logic** - if both `web/` and `api/` need it, put
   it in `shared/`
4. **Missing tags** - every test needs `@smoke`/`@critical`/`@regression`
5. **Unclear keyword names** - use "User Clicks Feature Button", not "Click"
6. **Guessed locators** - verify real element ids/attributes before writing
   a locator; practice.expandtesting.com's markup is stable but not
   documented, so check it live

## Extending Existing Features

1. Add locators to the existing locator file (if needed)
2. Add action keywords to the existing action file
3. Add result keywords to the existing result file
4. Create a new test file in the same suite

Never add logic directly to test files - always use keywords for reusability.
