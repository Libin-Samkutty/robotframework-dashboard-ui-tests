*** Variables ***

# ============================================================================
# Shared Test Data
# Single canonical source for environment, base URL, and timeout variables
# used across web/ and api/. Robot Framework variable names are case,
# space, and underscore insensitive, so these must not be redefined
# elsewhere in the repo.
# ============================================================================

# System Under Test - read from the OS environment (.env / CI env / docker-compose
# env_file) with the real public site as the default fallback
${BASE_URL}                                 %{BASE_URL=https://practice.expandtesting.com}

# Environment (structural only - both resolve to the same real BASE_URL,
# retained to demonstrate the environment-switch pattern)
${ENV}                                      %{ENV=STAGING}
${STAGING}                                  STAGING
${PROD}                                     PROD

# Timeouts (in seconds)
${default_timeout}                          60s
${short_timeout}                            3s
${very_short_timeout}                       1s
${keyword_succeed_timeout}                  30s

# Browser Configuration
${BROWSER}                                  %{BROWSER=Chrome}
# Options: Chrome, Firefox, Edge
${REMOTE_URL}                               %{REMOTE_URL=}
# Set to a Selenium Grid hub URL (e.g. http://localhost:4444/wd/hub) to run
# against a remote Grid instead of a local browser driver.
