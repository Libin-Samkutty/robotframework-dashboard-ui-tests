*** Settings ***
Library    OperatingSystem
Library    SeleniumLibrary    run_on_failure=NOTHING

Resource    ../../shared/test_data/shared_testdata.robot
Resource    ../../shared/keywords/common_keywords.robot

*** Keywords ***

Set Up Web Test Environment
    [Documentation]    Create screenshots directory and configure browser for test run
    Create Directory    screenshots
    Set Selenium Speed    0.1s
