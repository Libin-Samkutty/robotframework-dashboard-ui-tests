*** Settings ***

Library    Collections
Library    String
Library    RequestsLibrary
Library    pabot.PabotLib

Resource    ../data/common_properties.robot
Resource    ../data/testdata/common_error_messages.robot
Resource    ../../shared/test_data/shared_testdata.robot
Resource    ../../shared/keywords/common_keywords.robot
Resource    ../../shared/keywords/assertion_keywords.robot

*** Keywords ***

# ============================================================================
# Notes API Common Keywords
# Session, auth, and CRUD keywords for practice.expandtesting.com/notes/api
# All write endpoints on this API take formData, not JSON.
# expected_status=any is used throughout so negative-path responses are
# returned as objects for assertion instead of raising an exception.
# ============================================================================

Create Notes API Session
    [Documentation]    Create a RequestsLibrary session against the Notes API
    [Arguments]        ${env}=${ENV}
    ${base}=    Resolve Base URL For Environment    ${env}
    Create Session    ${api_session_name}    ${base}${api_base_path}    verify=True    max_retries=0

Register New API User
    [Documentation]    Register a new Notes API user account
    [Arguments]        ${name}    ${email}    ${password}
    ${payload}=    Create Dictionary    name=${name}    email=${email}    password=${password}
    ${response}=    POST On Session
    ...    ${api_session_name}    ${users_register_endpoint}
    ...    data=${payload}    expected_status=any
    RETURN    ${response}

Login API User
    [Documentation]    Log in a Notes API user and return the response (contains data.token on success)
    [Arguments]        ${email}    ${password}
    ${payload}=    Create Dictionary    email=${email}    password=${password}
    ${response}=    POST On Session
    ...    ${api_session_name}    ${users_login_endpoint}
    ...    data=${payload}    expected_status=any
    RETURN    ${response}

Set Auth Token
    [Documentation]    Store the auth token for use by Create Auth Headers
    [Arguments]        ${token}
    Set Suite Variable    ${AUTH_TOKEN}    ${token}

Create Auth Headers
    [Documentation]    Build the x-auth-token header dictionary from the stored token
    ${headers}=    Create Dictionary    x-auth-token=${AUTH_TOKEN}
    RETURN    ${headers}

Register And Login New API User
    [Documentation]    Register a new user, log in, and store the auth token - the
    ...                standard suite-setup flow so tests share one account instead
    ...                of creating a new one per test against the shared public API
    [Arguments]        ${name}    ${email}    ${password}
    Register New API User    ${name}    ${email}    ${password}
    ${login_response}=    Login API User    ${email}    ${password}
    Response Should Have Status Code    ${login_response}    ${success_200}
    ${token}=    Get From Dictionary    ${login_response.json()['data']}    token
    Set Auth Token    ${token}
    RETURN    ${token}

Ensure Shared API Test User
    [Documentation]    Register ONE Notes API test user for the whole pabot run - via
    ...                PabotLib's cross-process "run only once" coordination - and log
    ...                in with it from this process. Avoids registering a brand-new
    ...                account per test once --testlevelsplit turns what used to be a
    ...                once-per-suite setup into a once-per-test one; every process
    ...                still performs its own lightweight login, since HTTP sessions
    ...                and auth tokens can't be shared across pabot's separate worker
    ...                processes. Falls back to plain once-per-process behaviour when
    ...                run without pabot (PabotLib degrades to local-only locking).
    Create Notes API Session
    Run Only Once    Register Shared API Test User
    ${email}=    Get Parallel Value For Key    SHARED_API_TEST_EMAIL
    ${password}=    Get Parallel Value For Key    SHARED_API_TEST_PASSWORD
    ${login_response}=    Login API User    ${email}    ${password}
    Response Should Have Status Code    ${login_response}    ${success_200}
    ${token}=    Get From Dictionary    ${login_response.json()['data']}    token
    Set Auth Token    ${token}
    Set Suite Variable    ${TEST_USER_EMAIL}    ${email}
    Set Suite Variable    ${TEST_USER_PASSWORD}    ${password}

Register Shared API Test User
    [Documentation]    Perform the actual one-time registration against the Notes
    ...                API. Only ever invoked through Ensure Shared API Test User's
    ...                Run Only Once call above, and only in whichever process wins
    ...                the race to run it first.
    ${name}    ${email}    ${password}=    Generate Unique Test User
    ${response}=    Register New API User    ${name}    ${email}    ${password}
    Response Should Have Status Code    ${response}    ${created_201}
    Set Parallel Value For Key    SHARED_API_TEST_EMAIL    ${email}
    Set Parallel Value For Key    SHARED_API_TEST_PASSWORD    ${password}

Tear Down Shared API Test User Once
    [Documentation]    Delete the shared test user account exactly once, after every
    ...                parallel process has gone through this teardown step - via
    ...                PabotLib's Run Teardown Only Once.
    Run Teardown Only Once    Delete Shared API Test User

Delete Shared API Test User
    [Documentation]    Log in as the shared test user one final time (independent of
    ...                whichever process's session created it) and delete the
    ...                account. Only ever invoked through Tear Down Shared API Test
    ...                User Once above.
    Create Notes API Session
    ${email}=    Get Parallel Value For Key    SHARED_API_TEST_EMAIL
    ${password}=    Get Parallel Value For Key    SHARED_API_TEST_PASSWORD
    ${login_response}=    Login API User    ${email}    ${password}
    ${token}=    Get From Dictionary    ${login_response.json()['data']}    token
    Set Auth Token    ${token}
    Delete Test User Account
    Close API Session

Get User Profile
    [Documentation]    Retrieve the authenticated user's profile
    ${headers}=    Create Auth Headers
    ${response}=    GET On Session
    ...    ${api_session_name}    ${users_profile_endpoint}
    ...    headers=${headers}    expected_status=any
    RETURN    ${response}

Create Note
    [Documentation]    Create a note for the authenticated user
    [Arguments]        ${title}    ${description}    ${category}=Home
    ${headers}=    Create Auth Headers
    ${payload}=    Create Dictionary    title=${title}    description=${description}    category=${category}
    ${response}=    POST On Session
    ...    ${api_session_name}    ${notes_endpoint}
    ...    data=${payload}    headers=${headers}    expected_status=any
    RETURN    ${response}

Get All Notes
    [Documentation]    Retrieve all notes for the authenticated user
    ${headers}=    Create Auth Headers
    ${response}=    GET On Session
    ...    ${api_session_name}    ${notes_endpoint}
    ...    headers=${headers}    expected_status=any
    RETURN    ${response}

Get Note By Id
    [Documentation]    Retrieve a single note by id
    [Arguments]        ${note_id}
    ${headers}=    Create Auth Headers
    ${response}=    GET On Session
    ...    ${api_session_name}    ${notes_endpoint}/${note_id}
    ...    headers=${headers}    expected_status=any
    RETURN    ${response}

Update Note
    [Documentation]    Update an existing note's title/description/category
    [Arguments]        ${note_id}    ${title}    ${description}    ${category}=Home    ${completed}=${False}
    ${headers}=    Create Auth Headers
    ${payload}=    Create Dictionary
    ...    title=${title}    description=${description}    category=${category}    completed=${completed}
    ${response}=    PUT On Session
    ...    ${api_session_name}    ${notes_endpoint}/${note_id}
    ...    data=${payload}    headers=${headers}    expected_status=any
    RETURN    ${response}

Mark Note Completed
    [Documentation]    Update only the completed flag of a note. The API expects
    ...                a lowercase "true"/"false" string in the formData body -
    ...                Python's default bool-to-str ("True"/"False") is rejected.
    [Arguments]        ${note_id}    ${completed}=${True}
    ${headers}=    Create Auth Headers
    ${completed_str}=    Convert To String    ${completed}
    ${completed_value}=    Convert To Lowercase    ${completed_str}
    ${payload}=    Create Dictionary    completed=${completed_value}
    ${response}=    PATCH On Session
    ...    ${api_session_name}    ${notes_endpoint}/${note_id}
    ...    data=${payload}    headers=${headers}    expected_status=any
    RETURN    ${response}

Delete Note
    [Documentation]    Delete a note by id
    [Arguments]        ${note_id}
    ${headers}=    Create Auth Headers
    ${response}=    DELETE On Session
    ...    ${api_session_name}    ${notes_endpoint}/${note_id}
    ...    headers=${headers}    expected_status=any
    RETURN    ${response}

Delete Test User Account
    [Documentation]    Delete the currently authenticated test user account (cleanup)
    ${headers}=    Create Auth Headers
    DELETE On Session
    ...    ${api_session_name}    ${users_delete_account_endpoint}
    ...    headers=${headers}    expected_status=any

Perform Health Check
    [Documentation]    Call the Notes API health check endpoint
    ${response}=    GET On Session    ${api_session_name}    ${health_check_endpoint}    expected_status=${success_200}
    RETURN    ${response}

Attempt Request Without Auth Token
    [Documentation]    Call an endpoint with no auth header at all
    [Arguments]        ${endpoint}
    ${response}=    GET On Session    ${api_session_name}    ${endpoint}    expected_status=any
    RETURN    ${response}

Attempt Request With Invalid Auth Token
    [Documentation]    Call an endpoint with a syntactically valid but bogus auth token
    [Arguments]        ${endpoint}
    ${headers}=    Create Dictionary    x-auth-token=invalid-token-does-not-exist
    ${response}=    GET On Session    ${api_session_name}    ${endpoint}    headers=${headers}    expected_status=any
    RETURN    ${response}

Close API Session
    [Documentation]    Close the Notes API session
    Delete All Sessions
