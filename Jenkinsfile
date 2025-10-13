pipeline {
    agent any

    environment {
        // Change these paths if needed
        DEP_CHECK_DIR = "${WORKSPACE}/dependency-check"
        DEP_CHECK_DATA = "${WORKSPACE}/dependency-check-data"
        DEP_CHECK_REPORT = "${WORKSPACE}/dependency-check-report"
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
                echo "📥 Downloading Dependency-Check CLI 12.1.7..."
                sh '''
                    mkdir -p $DEP_CHECK_DIR
                    curl -L -o $DEP_CHECK_DIR/dependency-check.zip https://github.com/dependency-check/DependencyCheck/releases/download/v12.1.7/dependency-check-12.1.7-release.zip
                    unzip -q -o $DEP_CHECK_DIR/dependency-check.zip -d $DEP_CHECK_DIR
                    chmod +x $DEP_CHECK_DIR/dependency-check/bin/dependency-check.sh
                    mkdir -p $DEP_CHECK_DATA
                    chmod -R 777 $DEP_CHECK_DATA
                '''
            }
        }

        stage('Run OWASP Dependency-Check') {
            steps {
                echo "🔍 Running Dependency-Check scan..."
                withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                    sh '''
                        $DEP_CHECK_DIR/dependency-check/bin/dependency-check.sh \
                            --project MyProject \
                            --scan . \
                            --format HTML \
                            --out $DEP_CHECK_REPORT \
                            --nvdApiKey $NVD_API_KEY \
                            --data $DEP_CHECK_DATA
                    '''
                }
            }
        }

        stage('Archive Reports') {
            steps {
                echo "📂 Archiving Dependency-Check report..."
                archiveArtifacts artifacts: 'dependency-check-report/*.html', fingerprint: true
            }
        }
    }
}
