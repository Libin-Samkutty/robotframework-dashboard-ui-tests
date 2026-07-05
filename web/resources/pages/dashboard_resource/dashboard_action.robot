*** Settings ***
Library    SeleniumLibrary

Resource    ../../../data/locators/dashboard_page_locators.robot
Resource    ../../../data/common_properties.robot
Resource    ../../utilities/utility_keywords.robot

*** Keywords ***

User Logs Out Of The Secure Area
    [Documentation]    Click the logout link on the secure page
    Wait For Element And Click    ${SECURE_LOGOUT_BUTTON}
