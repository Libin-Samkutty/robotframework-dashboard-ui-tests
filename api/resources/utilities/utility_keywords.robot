*** Settings ***

Library    Collections
Library    OperatingSystem
Library    String
Library    JSONLibrary

Resource    ../common_resources.robot

*** Keywords ***

# ============================================================================
# API Utilities
# Generic JSON/dict helpers, independent of any specific endpoint
# ============================================================================

Convert JSON String To Dictionary
    [Documentation]    Convert JSON string to Robot Framework dictionary
    [Arguments]        ${json_string}
    ${dictionary}=     Evaluate    json.loads("""${json_string}""")    json
    RETURN             ${dictionary}

Merge Two Dictionaries
    [Documentation]    Merge two dictionaries into one
    [Arguments]        ${dict1}    ${dict2}
    ${merged}=         Create Dictionary    &{dict1}    &{dict2}
    RETURN             ${merged}

Get Nested Dictionary Value
    [Documentation]    Get value from nested dictionary using dot notation (e.g. "user.address.city")
    [Arguments]        ${dictionary}    ${key_path}
    ${keys}=           Split String    ${key_path}    .
    ${value}=          Set Variable    ${dictionary}
    FOR    ${key}    IN    @{keys}
        ${value}=      Get From Dictionary    ${value}    ${key}
    END
    RETURN             ${value}

Create Payload From Template
    [Documentation]    Create API payload from dictionary template
    [Arguments]        ${template}    ${replacements}
    ${payload}=        Merge Two Dictionaries    ${template}    ${replacements}
    RETURN             ${payload}

Validate JSON Schema
    [Documentation]    Validate JSON response against expected structure
    [Arguments]        ${response_json}    @{required_keys}
    FOR    ${key}    IN    @{required_keys}
        Dictionary Should Contain Key    ${response_json}    ${key}
    END

Convert List To Query Parameters
    [Documentation]    Convert list of key-value pairs to query string
    [Arguments]        @{params}
    ${query_string}=    Create List
    FOR    ${param}    IN    @{params}
        Append To List    ${query_string}    ${param}
    END
    ${result}=         Catenate    SEPARATOR=&    @{query_string}
    RETURN             ${result}

Parse JSON Array Response
    [Documentation]    Parse JSON array response and return length
    [Arguments]        ${response_json}
    ${length}=         Get Length    ${response_json}
    RETURN             ${length}

Filter Dictionary By Keys
    [Documentation]    Create new dictionary containing only specified keys
    [Arguments]        ${dictionary}    @{keys_to_keep}
    ${filtered}=       Create Dictionary
    FOR    ${key}    IN    @{keys_to_keep}
        ${value}=      Get From Dictionary    ${dictionary}    ${key}
        Set To Dictionary    ${filtered}    ${key}=${value}
    END
    RETURN             ${filtered}
