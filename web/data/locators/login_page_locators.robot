*** Variables ***

# ============================================================================
# Login Page Locators
# Verified live against https://practice.expandtesting.com/login
# ============================================================================

# Form Fields
${LOGIN_USERNAME_FIELD}                     id:username
${LOGIN_PASSWORD_FIELD}                     id:password

# Buttons
${LOGIN_SUBMIT_BUTTON}                      id:submit-login

# Page Identifiers
${LOGIN_PAGE_HEADING}                       xpath://h1[contains(text(), 'Test Login page')]

# Flash Message (shared by success/error states - success/danger/info alert classes)
${LOGIN_FLASH_MESSAGE}                      id:flash
