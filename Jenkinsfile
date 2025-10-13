pipeline {
    agent any

    environment {
        DC_VERSION = "12.1.7"
        DC_HOME = "${WORKSPACE}/dependency-check"
        NVD_API_KEY = credentials('nvd-api-key') // <-- your credential ID
    }

    stages {
        stage('Install Dependency-Check') {
            steps {
                echo "📥 Downloading Dependency-Check CLI ${DC_VERSION}..."
                sh """
                    curl -L -o dependency-check.zip https://github.com/dependency-check/DependencyCheck/releases/download/v${DC_VERSION}/dependency-check-${DC_VERSION}-release.zip
                    unzip -q -o dependency-check.zip
                    chmod +x ${DC_HOME}/bin/dependency-check.sh
                """
            }
        }

        stage('Run OWASP Dependency-Check') {
            steps {
                echo "🔍 Running Dependency-Check scan..."
                sh """
                    ${DC_HOME}/bin/dependency-check.sh \
                      --project MyProject \
                      --scan . \
                      --format HTML \
                      --out dependency-check-report \
                      --nvdApiKey ${NVD_API_KEY} \
                      --data ${WORKSPACE}/dependency-check-data
                """
                archiveArtifacts artifacts: 'dependency-check-report/*.html', fingerprint: true
            }
        }
    }
}