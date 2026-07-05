*** Variables ***

# ============================================================================
# Notes API - Common Properties
# Endpoints and status codes for practice.expandtesting.com/notes/api
# Base URL, ENV, and timeouts live in shared/test_data/shared_testdata.robot
# ============================================================================

${api_session_name}                         notes_api_session
${api_base_path}                            /notes/api

# Endpoints
${health_check_endpoint}                    /health-check
${users_register_endpoint}                  /users/register
${users_login_endpoint}                     /users/login
${users_profile_endpoint}                   /users/profile
${users_delete_account_endpoint}            /users/delete-account
${notes_endpoint}                           /notes

# Default Headers
${default_content_type}                     application/json
${default_accept}                           application/json

# Retry Configuration
${api_retry_count}                          3
${api_retry_delay}                          1s

# Response Codes
${success_200}                              200
${created_201}                              201
${bad_request_400}                          400
${unauthorized_401}                         401
${not_found_404}                            404
${server_error_500}                         500
