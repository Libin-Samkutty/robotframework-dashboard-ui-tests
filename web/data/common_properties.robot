*** Settings ***

Resource    ../../shared/test_data/shared_testdata.robot

*** Variables ***

# ============================================================================
# Web - Common Properties
# BASE_URL, ENV, BROWSER, and timeouts live in shared/test_data/shared_testdata.robot.
# This file holds only web-module-specific content constants.
# ============================================================================

# Verified live text on the login/secure pages of practice.expandtesting.com
${LOGIN_SUCCESS_MESSAGE}                    You logged into a secure area!
${LOGOUT_SUCCESS_MESSAGE}                   You logged out of the secure area!
${INVALID_USERNAME_MESSAGE}                 Your username is invalid!
${INVALID_PASSWORD_MESSAGE}                 Your password is invalid!
