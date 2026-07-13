*** Settings ***
Library    SeleniumLibrary

Resource    ../../../data/locators/dashboard_page_locators.robot
Resource    ../../../data/locators/login_page_locators.robot
Resource    ../../../data/common_properties.robot
Resource    ../../../../shared/keywords/assertion_keywords.robot

*** Keywords ***

Secure Page Should Load Successfully
    [Documentation]    Verify the secure page heading and success flash message are visible.
    ...                Waits for the heading rather than a one-shot check - the
    ...                login click returns before the /secure navigation finishes,
    ...                and that race is slow enough on Firefox/geckodriver to fail
    ...                an immediate check even though the page loads fine shortly after.
    Wait Until Element Is Visible    ${SECURE_PAGE_HEADING}    ${default_timeout}
    Element Should Be Visible And Contain Text    ${SECURE_FLASH_MESSAGE}    ${LOGIN_SUCCESS_MESSAGE}

User Should See Logout Confirmation Message
    [Documentation]    Verify the logout redirected to /login and shows the logout flash message.
    ...                Reuses the login page's #flash locator - same element id, different page/content.
    Element Should Be Visible And Contain Text    ${LOGIN_FLASH_MESSAGE}    ${LOGOUT_SUCCESS_MESSAGE}
