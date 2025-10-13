pipeline {
    agent any

    environment {
        SNYK_TOKEN = credentials('snyk-token-id')
    }

    stages {
        stage('Install Snyk CLI') {
            steps {
                sh '''
                    echo "⬇️ Installing Snyk CLI..."
                    curl -sL https://github.com/snyk/cli/releases/latest/download/snyk-linux -o snyk
                    chmod +x snyk
                    mv snyk /usr/local/bin/snyk
                    snyk --version
                '''
            }
        }

        stage('Run Snyk Test & Monitor') {
            steps {
                sh '''
                    echo "🔐 Authenticating with Snyk..."
                    snyk auth ${SNYK_TOKEN}

                    echo "🚀 Running Snyk test on current repository..."
                    snyk test --all-projects --json > snyk-report.json

                    echo "☁️ Uploading results to Snyk Cloud Dashboard..."
                    snyk monitor --all-projects
                '''
            }
        }

        stage('Archive Report') {
            steps {
                archiveArtifacts artifacts: 'snyk-report.json', onlyIfSuccessful: true
                echo "📄 Snyk JSON report archived in Jenkins artifacts."
            }
        }
    }
}