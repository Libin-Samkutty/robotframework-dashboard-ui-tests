*** Settings ***

Library    DateTime
Library    String
Library    SeleniumLibrary
Library    FakerLibrary

Resource    ../test_data/shared_testdata.robot

*** Keywords ***

# ============================================================================
# Common Keywords
# Environment resolution, browser lifecycle, and cross-module helpers shared
# by web/ and api/. Centralised here to remove the duplication that used to
# exist per-module (env/country routing, teardown boilerplate, timestamps).
# ============================================================================

Resolve Base URL For Environment
    [Documentation]    Resolve the real base URL for a given environment name.
    ...                Only one real target exists today (practice.expandtesting.com);
    ...                STAGING/PROD are kept structurally and both resolve to it.
    [Arguments]        ${env}=${ENV}
    IF    '${env}' == '${STAGING}' or '${env}' == '${PROD}'
        RETURN    ${BASE_URL}
    END
    Fail    Invalid environment: ${env}

Open Browser To Application
    [Documentation]    Open a browser (local or against a Selenium Grid via
    ...                REMOTE_URL) and navigate to the given path.
    [Arguments]        ${path}=/    ${env}=${ENV}    ${browser}=${BROWSER}
    ${base}=    Resolve Base URL For Environment    ${env}
    IF    '${REMOTE_URL}' != '${EMPTY}'
        Open Browser    ${base}${path}    ${browser}    remote_url=${REMOTE_URL}
    ELSE
        Open Browser    ${base}${path}    ${browser}
    END
    Maximize Browser Window

Go To Application Path
    [Documentation]    Navigate the current browser to a path on the resolved
    ...                base URL, without opening a new browser session.
    [Arguments]        ${path}    ${env}=${ENV}
    ${base}=    Resolve Base URL For Environment    ${env}
    Go To    ${base}${path}

Get Timestamp For Screenshot
    [Documentation]    Return compact timestamp string for use in screenshot filenames
    ${timestamp}=    Get Current Date    result_format=%d%m%H%M%S
    RETURN    ${timestamp}

Take Screenshot
    [Documentation]    Capture screenshot with timestamp in filename
    ${timestamp}=    Get Timestamp For Screenshot
    Capture Page Screenshot    screenshots/screenshot_${timestamp}.png

Capture Screenshot If Test Failed
    [Documentation]    Standard test teardown step - screenshot only on failure
    Run Keyword If Test Failed    Take Screenshot

Close All Test Browsers
    [Documentation]    Standard suite teardown step - close every open browser
    Close All Browsers

Generate Unique Test User
    [Documentation]    Generate a name/email/password for a new API test user.
    ...                Faker alone can repeat values across runs, so a random
    ...                String-library suffix is appended to guarantee
    ...                uniqueness across parallel/repeat runs against the
    ...                shared public Notes API.
    ${suffix}=    Generate Random String    8    [LOWER][NUMBERS]
    ${first}=    FakerLibrary.First Name
    ${name}=    Set Variable    ${first} ${suffix}
    ${email}=    Set Variable    ${first}.${suffix}@example-test.com
    ${password}=    Set Variable    TestPass!${suffix}123
    RETURN    ${name}    ${email}    ${password}
