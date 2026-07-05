*** Settings ***
Documentation    CSV-driven login scenarios - see data/testdata/login_credentials.csv
...              for the credential matrix.

Library     SeleniumLibrary
Library     DataDriver    file=../../data/testdata/login_credentials.csv    encoding=utf-8    dialect=excel

Resource    ../../data/common_properties.robot
Resource    ../../resources/pages/login_resource/login_action.robot
Resource    ../../resources/pages/login_resource/login_result.robot
Resource    ../../resources/common_resources.robot
Resource    ../../resources/utilities/utility_keywords.robot
Resource    ../../../shared/keywords/common_keywords.robot

Test Template     Verify Login Behavior With Credentials
Test Teardown     Capture Screenshot If Test Failed
Suite Teardown    Close All Test Browsers

*** Test Cases ***
Verify Login Behavior With Credentials    ${username}    ${password}    ${expected_outcome}    ${test_tag}

*** Keywords ***

Verify Login Behavior With Credentials
    [Documentation]    Template keyword - receives row data from DataDriver CSV
    ...                Tests various login scenarios: valid credentials, invalid username,
    ...                invalid password, empty username
    [Arguments]        ${username}    ${password}    ${expected_outcome}    ${test_tag}
    [Tags]    DataDriven    Login    ${test_tag}

    Given User Opens The Login Page
    And Login Page Should Load Successfully

    When User Logs In With Username And Password    ${username}    ${password}

    IF    '${expected_outcome}' == 'secure'
        Then User Should Be On Secure Page
    ELSE IF    '${expected_outcome}' == 'invalid_username'
        Then User Should See Invalid Username Error
    ELSE IF    '${expected_outcome}' == 'invalid_password'
        Then User Should See Invalid Password Error
    ELSE
        Fail    Unknown expected outcome: ${expected_outcome}
    END
