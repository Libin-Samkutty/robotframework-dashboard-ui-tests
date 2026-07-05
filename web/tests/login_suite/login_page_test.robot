*** Settings ***
Documentation    Login scenarios against https://practice.expandtesting.com/login -
...              valid credentials, invalid username, invalid password.

Library    SeleniumLibrary

Resource    ../../data/common_properties.robot
Resource    ../../data/testdata/stage/stage_testdata.robot
Resource    ../../resources/pages/login_resource/login_action.robot
Resource    ../../resources/pages/login_resource/login_result.robot
Resource    ../../resources/utilities/utility_keywords.robot
Resource    ../../../shared/keywords/common_keywords.robot

Test Teardown     Capture Screenshot If Test Failed
Suite Teardown    Close All Test Browsers

*** Test Cases ***

Verify User Can Login With Valid Credentials
    [Tags]    @smoke    @critical    Login
    [Documentation]    Verify user can successfully login with valid credentials

    Given User Opens The Login Page
    And Login Page Should Load Successfully

    When User Logs In With Username And Password    ${login_username}    ${login_password}

    Then User Should Be On Secure Page

Verify Login Page Loads Successfully
    [Tags]    @smoke    Login
    [Documentation]    Verify login page UI elements are displayed correctly

    Given User Opens The Login Page

    Then Login Page Should Load Successfully

Verify User Cannot Login With Invalid Username
    [Tags]    @regression    Login
    [Documentation]    Verify login fails with an invalid username

    Given User Opens The Login Page

    When User Logs In With Username And Password    not_a_real_user    ${login_password}

    Then User Should See Invalid Username Error

Verify User Cannot Login With Invalid Password
    [Tags]    @regression    Login
    [Documentation]    Verify login fails with an incorrect password

    Given User Opens The Login Page

    When User Logs In With Username And Password    ${login_username}    WrongPassword123

    Then User Should See Invalid Password Error
