*** Settings ***

Library    SeleniumLibrary

Resource    ../../../data/locators/login_page_locators.robot
Resource    ../../../data/common_properties.robot
Resource    ../../../../shared/keywords/assertion_keywords.robot

*** Keywords ***

Login Page Should Load Successfully
    [Documentation]    Verify username field, password field, and submit button are all visible
    Element Should Be Visible    ${LOGIN_USERNAME_FIELD}
    Element Should Be Visible    ${LOGIN_PASSWORD_FIELD}
    Element Should Be Visible    ${LOGIN_SUBMIT_BUTTON}

User Should Be On Secure Page
    [Documentation]    Verify successful login landed on /secure with the success flash message
    Element Should Be Visible And Contain Text    ${LOGIN_FLASH_MESSAGE}    ${LOGIN_SUCCESS_MESSAGE}

User Should See Invalid Username Error
    [Documentation]    Verify the invalid-username flash message is displayed
    Element Should Be Visible And Contain Text    ${LOGIN_FLASH_MESSAGE}    ${INVALID_USERNAME_MESSAGE}

User Should See Invalid Password Error
    [Documentation]    Verify the invalid-password flash message is displayed
    Element Should Be Visible And Contain Text    ${LOGIN_FLASH_MESSAGE}    ${INVALID_PASSWORD_MESSAGE}

User Should Be Redirected To Login Page
    [Documentation]    Confirm the browser landed back on the login page
    Wait Until Page Contains Element    ${LOGIN_USERNAME_FIELD}    ${default_timeout}
