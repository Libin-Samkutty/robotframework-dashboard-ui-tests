*** Variables ***

# ============================================================================
# Production Environment Test Data
# There is only one real target today (practice.expandtesting.com); this file
# is kept to demonstrate the per-environment testdata pattern from the spec.
# PROD resolves to the same real credentials as STAGING - see MIGRATION.md.
# ============================================================================

${login_username}                           %{DEFAULT_USERNAME=practice}
${login_password}                           %{DEFAULT_PASSWORD=SuperSecretPassword!}
