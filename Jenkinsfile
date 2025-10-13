pipeline {
    agent any

    environment {
        SNYK_TOKEN = credentials('snyk-token-id')
    }

    stages {
        stage('Install Snyk CLI') {
            steps {
                sh '''
                    echo "⬇️ Installing latest Snyk CLI..."
                    curl -sL https://github.com/snyk/cli/releases/latest/download/snyk-linux -o snyk
                    chmod +x snyk
                    mv snyk /usr/local/bin/snyk
                    snyk --version
                '''
            }
        }

        stage('Run Snyk Tests (All Types)') {
            steps {
                sh '''
                    echo "🔐 Authenticating with Snyk..."
                    snyk auth ${SNYK_TOKEN}

                    mkdir -p snyk-reports

                    echo "📦 Running Dependency (SCA) Test..."
                    snyk test --all-projects --json > snyk-reports/snyk-dependencies.json || true
                    snyk monitor --all-projects || true

                    echo "🐳 Running Container Image Scan (if Dockerfile exists)..."
                    if [ -f Dockerfile ]; then
                        IMAGE_NAME=$(grep -r '^FROM ' Dockerfile | awk '{print $2}' | head -n 1)
                        echo "Scanning Docker image base: $IMAGE_NAME"
                        snyk container test $IMAGE_NAME --json > snyk-reports/snyk-container.json || true
                        snyk container monitor $IMAGE_NAME || true
                    else
                        echo "No Dockerfile found — skipping container scan."
                    fi

                    echo "🛠️ Running Infrastructure-as-Code (IaC) Scan..."
                    snyk iac test --report --json-file-output=snyk-reports/snyk-iac.json || true

                    echo "💻 Running Snyk Code (SAST) Scan..."
                    snyk code test --project-name="devsecops-dvwa" --report --json-file-output=snyk-reports/snyk-code.json || true

                    echo "✅ All Snyk Scans Completed! Reports saved in snyk-reports/"
                '''
            }
        }

        stage('Archive Reports') {
            steps {
                echo '📁 Archiving all Snyk JSON reports...'
                archiveArtifacts artifacts: 'snyk-reports/*.json', fingerprint: true
            }
        }
    }

    post {
        success {
            echo '✅ Snyk security scans completed successfully!'
        }
        failure {
            echo '❌ Snyk scan failed — check logs or snyk-reports for details.'
        }
    }
}