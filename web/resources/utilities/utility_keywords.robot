*** Settings ***

Library    SeleniumLibrary

Resource    ../../../shared/test_data/shared_testdata.robot

*** Keywords ***

# ============================================================================
# Utility Keywords
# Generic Selenium wait-and-act helpers. Screenshot/teardown helpers and
# test-data generation now live in shared/keywords/common_keywords.robot.
# ============================================================================

Wait For Element And Click
    [Documentation]    Wait for element to be visible, then click it via JavaScript.
    ...                practice.expandtesting.com renders live ad iframes that can
    ...                overlap elements regardless of scroll position, intercepting a
    ...                native WebDriver click - a JS click bypasses that entirely.
    [Arguments]        ${locator}    ${timeout}=${default_timeout}
    Wait Until Element Is Visible  ${locator}    ${timeout}
    ${element}=    Get WebElement    ${locator}
    Execute Javascript    arguments[0].scrollIntoView({block: 'center'});    ARGUMENTS    ${element}
    Execute Javascript    arguments[0].click();    ARGUMENTS    ${element}

Wait For Element And Type
    [Documentation]    Wait for element to be visible, clear it, then type text
    [Arguments]        ${locator}    ${text}    ${timeout}=${default_timeout}
    Wait Until Element Is Visible  ${locator}    ${timeout}
    Clear Element Text             ${locator}
    Input Text                     ${locator}    ${text}

Scroll To Element
    [Documentation]    Scroll page to make element visible
    [Arguments]        ${locator}
    Scroll Element Into View    ${locator}
