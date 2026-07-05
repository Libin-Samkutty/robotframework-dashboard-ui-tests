# argfile.robot - Default Robot Framework argument file
# Standard configuration for consistent test execution across local and CI environments
#
# Usage:
#   robot --argumentfile argfile.robot web/tests/
#   robot -A argfile.robot api/tests/
#   robot --argumentfile argfile.robot --include @smoke .

# Environment variables - can be overridden via command line
--variable    ENV:STAGING

# Test filtering
--include     @smoke

# Allure listener - emits reports/allure-results/*.json
--listener    allure_robotframework:reports/allure-results

# Output configuration
--outputdir   reports
--loglevel    INFO
--timestampoutputs

# Do not generate individual reports here - use rebot to merge outputs
--report      NONE
