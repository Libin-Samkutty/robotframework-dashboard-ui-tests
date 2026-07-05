*** Settings ***
Documentation    Health check, auth, and CRUD smoke scenarios against
...              https://practice.expandtesting.com/notes/api

Library    Collections
Library    RequestsLibrary

Resource    ../../resources/common_resources.robot
Resource    ../../data/common_properties.robot
Resource    ../../../shared/test_data/shared_testdata.robot
Resource    ../../../shared/keywords/common_keywords.robot
Resource    ../../../shared/keywords/assertion_keywords.robot

Suite Setup       Set Up Notes API Smoke Suite
Suite Teardown    Tear Down Notes API Smoke Suite

*** Test Cases ***

Verify Notes API Health Check Returns Success
    [Tags]    @smoke    HealthCheck
    [Documentation]    Verify the Notes API health check endpoint is up

    ${response}=    Perform Health Check
    Response Should Have Status Code    ${response}    ${success_200}
    Response Body Value Should Equal    ${response}    message    Notes API is Running

Verify New User Can Register And Login And Receive Auth Token
    [Tags]    @smoke    @critical    Auth
    [Documentation]    Verify the shared test user (registered once for the whole run
    ...                by Suite Setup) can log in and receive an auth token.

    ${response}=    Login API User    ${TEST_USER_EMAIL}    ${TEST_USER_PASSWORD}
    Response Should Have Status Code    ${response}    ${success_200}
    Response Body Should Contain Key    ${response}    data
    Should Not Be Empty    ${response.json()['data']['token']}

Verify Authenticated User Can Retrieve Profile
    [Tags]    @smoke    Auth
    [Documentation]    Verify the authenticated user can retrieve their own profile

    ${response}=    Get User Profile
    Response Should Have Status Code    ${response}    ${success_200}
    Response Body Value Should Equal    ${response}    message    Profile successful

Verify Authenticated User Can Create And Retrieve A Note
    [Tags]    @smoke    @critical
    [Documentation]    Verify the authenticated user can create a note and retrieve it

    ${create_response}=    Create Note    Practice Note    Created by the smoke suite    Work
    Response Should Have Status Code    ${create_response}    ${success_200}
    Response Body Should Contain Key    ${create_response}    data

    ${get_response}=    Get All Notes
    Response Should Have Status Code    ${get_response}    ${success_200}
    Response Body Should Contain Key    ${get_response}    data

Verify Authenticated User Can Update And Delete A Note
    [Tags]    @smoke
    [Documentation]    Verify the authenticated user can update and then delete a note.
    ...                Creates its own note rather than reusing one from another test -
    ...                under pabot's --testlevelsplit each test runs as an isolated
    ...                suite, so a Suite Variable set by one test is never visible to
    ...                another.

    ${create_response}=    Create Note    Practice Note For Update    Created for the update/delete smoke test    Work
    Response Should Have Status Code    ${create_response}    ${success_200}
    ${note_id}=    Get From Dictionary    ${create_response.json()['data']}    id

    ${update_response}=    Mark Note Completed    ${note_id}    ${True}
    Response Should Have Status Code    ${update_response}    ${success_200}
    Response Body Value Should Equal    ${update_response}    message    Note successfully Updated

    ${delete_response}=    Delete Note    ${note_id}
    Response Should Have Status Code    ${delete_response}    ${success_200}

*** Keywords ***

Set Up Notes API Smoke Suite
    [Documentation]    Ensure exactly one shared Notes API test user exists for the
    ...                whole pabot run (registered once, not once per test/process)
    ...                and log in with it for this process - see
    ...                Ensure Shared API Test User for how the once-only
    ...                registration is coordinated.
    Ensure Shared API Test User

Tear Down Notes API Smoke Suite
    [Documentation]    Close this process's own session, then delete the shared test
    ...                user account exactly once, after every parallel process has
    ...                finished with it.
    Close API Session
    Tear Down Shared API Test User Once
