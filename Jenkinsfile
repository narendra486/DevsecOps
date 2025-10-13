pipeline {
    agent any

    environment {
        NVD_API_KEY = credentials('nvd-api-key') // Jenkins Secret Text
    }

    stages {
        stage('Checkout') {
            steps {
                echo "✅ Checking out code..."
                checkout scm
            }
        }

        stage('Install Dependency-Check CLI') {
            steps {
                echo "📥 Downloading Dependency-Check CLI 12.1.7..."
                sh '''
                    mkdir -p dependency-check
                    curl -L -o dependency-check/dependency-check.zip https://github.com/dependency-check/DependencyCheck/releases/download/v12.1.7/dependency-check-12.1.7-release.zip
                    unzip -q -o dependency-check/dependency-check.zip -d dependency-check
                    chmod +x dependency-check/dependency-check/bin/dependency-check.sh
                    mkdir -p dependency-check-data
                    chmod -R 777 dependency-check-data
                '''
            }
        }

        stage('Run OWASP Dependency-Check') {
            steps {
                echo "🔍 Running Dependency-Check scan..."
                sh '''
                    dependency-check/dependency-check/bin/dependency-check.sh \
                        --project MyProject \
                        --scan . \
                        --format HTML \
                        --out dependency-check-report \
                        --nvdApiKey '${NVD_API_KEY}' \
                        --data dependency-check-data
                '''
            }
        }

        stage('Archive Reports') {
            steps {
                echo "📦 Archiving Dependency-Check HTML report..."
                archiveArtifacts artifacts: 'dependency-check-report/*.html', fingerprint: true
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up temporary files..."
            sh 'rm -rf dependency-check dependency-check-data'
        }
        success {
            echo "✅ Dependency-Check scan completed successfully!"
        }
        failure {
            echo "❌ Dependency-Check scan failed!"
        }
    }
}