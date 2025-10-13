pipeline {
    agent any

    environment {
        DEP_CHECK_VERSION = "12.1.7" // Change to latest if needed
        DEP_CHECK_HOME = "${WORKSPACE}/dependency-check"
        DEP_CHECK_DATA = "${WORKSPACE}/dependency-check-data"
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
                echo "📥 Downloading Dependency-Check CLI ${DEP_CHECK_VERSION}..."
                sh """
                    mkdir -p ${DEP_CHECK_HOME}
                    curl -L -o ${DEP_CHECK_HOME}/dependency-check.zip https://github.com/dependency-check/DependencyCheck/releases/download/v${DEP_CHECK_VERSION}/dependency-check-${DEP_CHECK_VERSION}-release.zip
                    unzip -q -o ${DEP_CHECK_HOME}/dependency-check.zip -d ${DEP_CHECK_HOME}
                    chmod +x ${DEP_CHECK_HOME}/bin/dependency-check.sh
                    mkdir -p ${DEP_CHECK_DATA}
                    chmod -R 777 ${DEP_CHECK_DATA}
                """
            }
        }

        stage('Run OWASP Dependency-Check') {
            environment {
                // Make sure NVD API Key is stored in Jenkins credentials
                NVD_API_KEY = credentials('nvd-api-key-id')
            }
            steps {
                echo "🔍 Running Dependency-Check scan..."
                sh """
                    # Optional: update NVD database first
                    ${DEP_CHECK_HOME}/bin/dependency-check.sh --updateOnly --nvdApiKey '${NVD_API_KEY}' --data ${DEP_CHECK_DATA}

                    # Run scan
                    ${DEP_CHECK_HOME}/bin/dependency-check.sh \
                        --project MyProject \
                        --scan . \
                        --format HTML \
                        --out dependency-check-report \
                        --nvdApiKey '${NVD_API_KEY}' \
                        --data ${DEP_CHECK_DATA}
                """
                archiveArtifacts artifacts: 'dependency-check-report/*.html', fingerprint: true
            }
        }
    }

    post {
        always {
            echo "📦 Cleaning up..."
            sh "rm -rf ${DEP_CHECK_HOME} ${DEP_CHECK_DATA}"
        }
    }
}
