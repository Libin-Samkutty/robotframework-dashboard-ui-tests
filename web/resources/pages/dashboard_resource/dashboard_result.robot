*** Settings ***
Library    SeleniumLibrary

Resource    ../../../data/locators/dashboard_page_locators.robot
Resource    ../../../data/locators/login_page_locators.robot
Resource    ../../../data/common_properties.robot
Resource    ../../../../shared/keywords/assertion_keywords.robot

*** Keywords ***

Secure Page Should Load Successfully
    [Documentation]    Verify the secure page heading and success flash message are visible
    Element Should Be Visible    ${SECURE_PAGE_HEADING}
    Element Should Be Visible And Contain Text    ${SECURE_FLASH_MESSAGE}    ${LOGIN_SUCCESS_MESSAGE}

User Should See Logout Confirmation Message
    [Documentation]    Verify the logout redirected to /login and shows the logout flash message.
    ...                Reuses the login page's #flash locator - same element id, different page/content.
    Element Should Be Visible And Contain Text    ${LOGIN_FLASH_MESSAGE}    ${LOGOUT_SUCCESS_MESSAGE}
