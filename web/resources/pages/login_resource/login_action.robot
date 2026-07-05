*** Settings ***

Library    SeleniumLibrary

Resource    ../../../data/locators/login_page_locators.robot
Resource    ../../../data/common_properties.robot
Resource    ../../../data/testdata/stage/stage_testdata.robot
Resource    ../../../data/testdata/prod/prod_testdata.robot
Resource    ../../utilities/utility_keywords.robot
Resource    ../../../../shared/keywords/common_keywords.robot

*** Keywords ***

User Opens The Login Page
    [Documentation]    Open the login page in the specified environment
    [Arguments]        ${env}=${ENV}
    Open Browser To Application    path=/login    env=${env}
    Wait Until Page Contains Element    ${LOGIN_USERNAME_FIELD}    ${default_timeout}

User Enters Username
    [Documentation]    Enter a username into the login form
    [Arguments]        ${username}
    Wait For Element And Type    ${LOGIN_USERNAME_FIELD}    ${username}

User Enters Password
    [Documentation]    Enter a password into the login form
    [Arguments]        ${password}
    Wait For Element And Type    ${LOGIN_PASSWORD_FIELD}    ${password}

User Clicks Login Button
    [Documentation]    Click the login submit button
    Wait For Element And Click    ${LOGIN_SUBMIT_BUTTON}

User Logs In With Username And Password
    [Documentation]    Convenience composite - enter credentials and submit
    [Arguments]        ${username}    ${password}
    User Enters Username    ${username}
    User Enters Password    ${password}
    User Clicks Login Button

User Opens The Secure Page Directly Without Logging In
    [Documentation]    Open a fresh browser straight at /secure without authenticating first
    [Arguments]        ${env}=${ENV}
    Open Browser To Application    path=/secure    env=${env}
