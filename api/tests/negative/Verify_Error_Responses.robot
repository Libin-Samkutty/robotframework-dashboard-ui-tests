*** Settings ***
Documentation    401, 404, and validation error scenarios against
...              https://practice.expandtesting.com/notes/api

Library    Collections
Library    RequestsLibrary

Resource    ../../resources/common_resources.robot
Resource    ../../data/common_properties.robot
Resource    ../../data/testdata/common_error_messages.robot
Resource    ../../../shared/test_data/shared_testdata.robot
Resource    ../../../shared/keywords/common_keywords.robot
Resource    ../../../shared/keywords/assertion_keywords.robot

Suite Setup       Create Notes API Session
Suite Teardown    Close API Session

*** Test Cases ***

Verify Request Without Auth Token Returns 401
    [Tags]    @regression    @critical    Auth
    [Documentation]    Verify requesting a protected endpoint with no auth token returns 401

    ${response}=    Attempt Request Without Auth Token    ${users_profile_endpoint}
    Response Should Have Status Code    ${response}    ${unauthorized_401}
    Response Body Value Should Equal    ${response}    message    ${ERROR_NO_AUTH_TOKEN}

Verify Request With Invalid Auth Token Returns 401
    [Tags]    @regression    Auth
    [Documentation]    Verify requesting a protected endpoint with a bogus auth token returns 401

    ${response}=    Attempt Request With Invalid Auth Token    ${users_profile_endpoint}
    Response Should Have Status Code    ${response}    ${unauthorized_401}

Verify Unknown Endpoint Returns 404 Not Found
    [Tags]    @regression
    [Documentation]    Verify a request to a non-existent endpoint returns 404

    ${response}=    GET On Session    ${api_session_name}    /does-not-exist-xyz    expected_status=any
    Response Should Have Status Code    ${response}    ${not_found_404}
    Response Body Value Should Equal    ${response}    message    ${ERROR_NOT_FOUND}

Verify Registration With Invalid Email Returns 400 Validation Error
    [Tags]    @regression    Validation
    [Documentation]    Verify registering with an invalid email format returns 400.
    ...                This request never succeeds, so no account is ever created
    ...                and no cleanup is required.

    ${response}=    Register New API User    Practice User    not-an-email    SomePassword123
    Response Should Have Status Code    ${response}    ${bad_request_400}
    Response Body Value Should Equal    ${response}    message    ${ERROR_INVALID_EMAIL}

Verify Login With Incorrect Credentials Returns 401
    [Tags]    @regression    @critical    Auth
    [Documentation]    Verify logging in with incorrect credentials returns 401

    ${response}=    Login API User    nonexistent-user@example-test.com    WrongPassword123
    Response Should Have Status Code    ${response}    ${unauthorized_401}
    Response Body Value Should Equal    ${response}    message    ${ERROR_INCORRECT_CREDENTIALS}
