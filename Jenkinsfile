pipeline {
    agent any

    environment {
        SONAR_HOST_URL = "http://167.86.125.122:1338"
    }

    stages {
        stage('SonarQube Analysis - Fixed') {
            environment {
                scannerHome = tool 'sonar-scanner'
            }
            steps {
                script {
                    echo "🔍 Checking SonarQube container..."
                    def running = sh(script: "docker ps --format '{{.Names}}' | grep -w sonarqube || true", returnStdout: true).trim()
                    if (!running) {
                        sh 'docker compose up -d sonarqube'
                        sleep 30
                    }
                    sh "curl -I ${SONAR_HOST_URL} || true"
                }

                withSonarQubeEnv('SonarQube Server') {
                    sh """
                        ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=devsecops-dvwa \
                            -Dsonar.projectName='DevSecOps DVWA' \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.exclusions=**/node_modules/**,**/vendor/**,**/*.zip,**/*.jar \
                            -Dsonar.sourceEncoding=UTF-8 \
                            -Dsonar.php.coverage.reportPaths=coverage.xml \
                            -Dsonar.python.version=3.10
                    """
                }

                // Optional: Quality gate waiting only if report-task.txt exists
                script {
                    if (fileExists('.scannerwork/report-task.txt')) {
                        timeout(time: 10, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    } else {
                        echo "⚠️ Skipping quality gate: report-task.txt not found"
                    }
                }
            }
        }
    }
}