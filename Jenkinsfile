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

        stage('Run Snyk Test') {
            steps {
                sh '''
                    echo "🔐 Authenticating with Snyk..."
                    snyk auth ${SNYK_TOKEN}

                    echo "🚀 Running Snyk test on current repository..."
                    snyk test --all-projects
                '''
            }
        }
    }
}
