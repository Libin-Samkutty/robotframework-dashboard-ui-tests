*** Variables ***

# ============================================================================
# Secure (Dashboard) Page Locators
# Verified live against https://practice.expandtesting.com/secure
# ============================================================================

${SECURE_PAGE_HEADING}                      xpath://h1[contains(text(), 'Secure Area')]
${SECURE_WELCOME_MESSAGE}                   id:username
${SECURE_LOGOUT_BUTTON}                     xpath://a[contains(@href, 'logout')]

# Flash Message (shared by the success/logout-confirmation states)
${SECURE_FLASH_MESSAGE}                     id:flash
