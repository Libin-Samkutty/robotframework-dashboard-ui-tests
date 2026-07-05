*** Variables ***

# ============================================================================
# Staging Environment Test Data
# There is only one real target today (practice.expandtesting.com); this file
# is kept to demonstrate the per-environment testdata pattern from the spec.
# Real login credentials are documented publicly on the login page itself.
# ============================================================================

${login_username}                           %{DEFAULT_USERNAME=practice}
${login_password}                           %{DEFAULT_PASSWORD=SuperSecretPassword!}
