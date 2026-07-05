*** Settings ***
Documentation    Secure (post-login) area scenarios against
...              https://practice.expandtesting.com/secure - authenticated load,
...              session/redirect validation, and logout.

Library    SeleniumLibrary

Resource    ../../data/common_properties.robot
Resource    ../../data/testdata/stage/stage_testdata.robot
Resource    ../../resources/pages/login_resource/login_action.robot
Resource    ../../resources/pages/login_resource/login_result.robot
Resource    ../../resources/pages/dashboard_resource/dashboard_action.robot
Resource    ../../resources/pages/dashboard_resource/dashboard_result.robot
Resource    ../../resources/common_resources.robot
Resource    ../../resources/utilities/utility_keywords.robot
Resource    ../../../shared/keywords/common_keywords.robot

Test Teardown     Capture Screenshot If Test Failed
Suite Teardown    Close All Test Browsers

*** Test Cases ***

Verify Authenticated User Sees Secure Area Content
    [Tags]    @smoke    @critical    Secure
    [Documentation]    Verify the secure page renders after a successful login

    Given User Opens The Login Page
    And User Logs In With Username And Password    ${login_username}    ${login_password}

    Then Secure Page Should Load Successfully

Verify Direct Navigation To Secure Page Without Login Redirects
    [Tags]    @regression    Secure    Auth
    [Documentation]    Verify navigating directly to /secure without logging in redirects to /login

    Given User Opens The Secure Page Directly Without Logging In

    Then User Should Be Redirected To Login Page

Verify User Can Log Out From Secure Page
    [Tags]    @smoke    @critical    Secure    Auth
    [Documentation]    Verify logging out from the secure page redirects back to the login page

    Given User Opens The Login Page
    And User Logs In With Username And Password    ${login_username}    ${login_password}
    And Secure Page Should Load Successfully

    When User Logs Out Of The Secure Area

    Then User Should Be Redirected To Login Page

Verify Logout Confirmation Message Is Displayed
    [Tags]    @regression    Secure    Auth
    [Documentation]    Verify the login page shows a logout confirmation message after logout

    Given User Opens The Login Page
    And User Logs In With Username And Password    ${login_username}    ${login_password}
    And Secure Page Should Load Successfully

    When User Logs Out Of The Secure Area

    Then User Should See Logout Confirmation Message
