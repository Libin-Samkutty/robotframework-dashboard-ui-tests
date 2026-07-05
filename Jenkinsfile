// ============================================================================
// Jenkinsfile - illustrative pipeline demonstrating that the test suite is
// portable beyond GitHub Actions. Not wired up to a live Jenkins instance
// for this portfolio repo; included per SPEC.md for CI diversity.
// ============================================================================

pipeline {
    agent {
        docker {
            image 'python:3.12-slim'
            args '--network host'
        }
    }

    environment {
        REMOTE_URL = 'http://localhost:4444/wd/hub'
    }

    stages {
        stage('Install') {
            steps {
                sh 'pip install --upgrade pip'
                sh 'pip install -r requirements.txt'
            }
        }

        stage('Lint') {
            steps {
                sh 'robocop check web api shared'
            }
        }

        stage('Start Grid') {
            steps {
                sh 'docker compose up -d selenium-hub chrome'
                sh '''
                  timeout 60 sh -c \
                    "until curl -sf http://localhost:4444/wd/hub/status | grep -q '\\"ready\\":true'; do sleep 2; done"
                '''
            }
        }

        stage('Smoke') {
            steps {
                sh '''
                  robot --variable REMOTE_URL:http://localhost:4444/wd/hub \
                        --variable BROWSER:chrome \
                        --listener allure_robotframework:reports/allure-results \
                        --include @smoke \
                        --outputdir reports \
                        web api
                '''
            }
        }

        stage('Report') {
            steps {
                sh 'apt-get update && apt-get install -y --no-install-recommends default-jre-headless curl'
                sh 'allure generate reports/allure-results -o reports/allure-report --clean'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/allure-report/**', allowEmptyArchive: true
                }
            }
        }
    }

    post {
        always {
            sh 'docker compose down -v || true'
        }
    }
}
