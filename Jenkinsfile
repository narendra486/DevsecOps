pipeline {
    agent any

    environment {
        // NVD API key stored in Jenkins credentials (Secret Text)
        NVD_API_KEY = credentials('nvd-api-key')
    }

    options {
        skipDefaultCheckout(true)
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo "✅ Checking out code..."
                checkout scm
            }
        }

        stage('Install Dependency-Check CLI') {
            steps {
                script {
                    // Only download CLI if not present
                    if (!fileExists('dependency-check/dependency-check/bin/dependency-check.sh')) {
                        echo "📥 Downloading Dependency-Check CLI 12.1.7..."
                        sh '''
                        mkdir -p dependency-check
                        curl -L -o dependency-check/dependency-check.zip https://github.com/dependency-check/DependencyCheck/releases/download/v12.1.7/dependency-check-12.1.7-release.zip
                        unzip -q -o dependency-check/dependency-check.zip -d dependency-check
                        chmod +x dependency-check/dependency-check/bin/dependency-check.sh
                        mkdir -p dependency-check-data
                        chmod -R 777 dependency-check-data
                        '''
                    } else {
                        echo "✅ Dependency-Check CLI already exists, skipping download."
                    }
                }
            }
        }

        stage('OWASP Dependency-Check Scan') {
            steps {
                echo "🔍 Running Dependency-Check scan..."
                withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                    sh '''
                    dependency-check/dependency-check/bin/dependency-check.sh \
                        --project "MyProject" \
                        --scan . \
                        --format "ALL" \
                        --out dependency-check-report \
                        --data dependency-check-data \
                        --nvdApiKey $NVD_API_KEY \
                        --prettyPrint \
                        --disableNvd
                    '''
                }
            }
        }

        stage('Publish Reports') {
            steps {
                echo "📄 Publishing Dependency-Check reports..."
                dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml'
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up temporary files..."
            sh 'rm -rf dependency-check/*.tmp'
        }

        success {
            echo "✅ Dependency-Check scan completed successfully!"
        }

        failure {
            echo "❌ Dependency-Check scan failed! Check logs for details."
        }
    }
}