*** Settings ***

Library    Collections
Library    SeleniumLibrary

*** Keywords ***

# ============================================================================
# Assertion Keywords
# Generic wait-then-assert wrappers reused by both the web (Selenium) and
# api (Requests/Collections) layers. Page-specific result keywords keep
# their own names and locators, but delegate the actual wait/assert logic
# here instead of duplicating it inline.
# ============================================================================

Element Should Be Visible And Contain Text
    [Documentation]    Wait for an element to be visible, then wait for it to
    ...                contain the expected text - a bare visibility check isn't
    ...                enough where an element id is reused across pages (e.g.
    ...                the login/secure #flash message): the old page's element
    ...                can still be visible for an instant during navigation,
    ...                so the content itself must be polled too, not just presence.
    [Arguments]        ${locator}    ${text}    ${timeout}=${default_timeout}
    Wait Until Element Is Visible    ${locator}    ${timeout}
    Wait Until Element Contains    ${locator}    ${text}    ${timeout}

Page Should Contain Text Within Timeout
    [Documentation]    Wait for the page to contain the given text
    [Arguments]        ${text}    ${timeout}=${default_timeout}
    Wait Until Page Contains    ${text}    ${timeout}

Response Should Have Status Code
    [Documentation]    Assert an HTTP response object has the expected status code
    [Arguments]        ${response}    ${expected_status}
    Should Be Equal As Strings    ${response.status_code}    ${expected_status}

Response Body Should Contain Key
    [Documentation]    Assert an HTTP response's JSON body contains a given key
    [Arguments]        ${response}    ${key}
    Dictionary Should Contain Key    ${response.json()}    ${key}

Response Body Should Contain Keys
    [Documentation]    Assert an HTTP response's JSON body contains all given keys
    [Arguments]        ${response}    @{keys}
    FOR    ${key}    IN    @{keys}
        Response Body Should Contain Key    ${response}    ${key}
    END

Response Body Value Should Equal
    [Documentation]    Assert a key in an HTTP response's JSON body equals a value
    [Arguments]        ${response}    ${key}    ${expected_value}
    ${value}=    Get From Dictionary    ${response.json()}    ${key}
    Should Be Equal As Strings    ${value}    ${expected_value}
