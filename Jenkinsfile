pipeline {
    agent any

    environment {
        SONAR_HOST_URL = "http://167.86.125.122:1338"
        NVD_API_KEY = credentials('nvd-api-key')
        SNYK_TOKEN = credentials('snyk-token-id')
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo "✅ Checking out code..."
                checkout scm
            }
        }

        stage('Security & Quality Scans') {
            stages {
                stage('SonarQube Analysis') {
                    environment {
                        scannerHome = tool 'sonar-scanner'
                    }
                    steps {
                        script {
                            def running = sh(script: "docker ps --format '{{.Names}}' | grep -w sonarqube || true", returnStdout: true).trim()
                            if (!running) {
                                sh 'docker compose up -d sonarqube'
                                echo "SonarQube container started. Waiting for health..."
                                sleep 30
                            } else {
                                echo "SonarQube container already running."
                            }

                            def healthy = false
                            for (int i = 1; i <= 10; i++) {
                                def code = sh(script: "curl -L -o /dev/null -s -w '%{http_code}' ${SONAR_HOST_URL}", returnStdout: true).trim()
                                echo "SonarQube HTTP code attempt ${i}: ${code}"
                                if (code == '200') {
                                    healthy = true
                                    echo "SonarQube is up!"
                                    break
                                }
                                sleep 10
                            }
                            if (!healthy) {
                                echo "Warning: SonarQube did not become healthy in time; continuing pipeline."
                            }
                        }

                        withSonarQubeEnv('SonarQube Server') {
                            sh """${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=vprofile \
                                -Dsonar.projectName=vprofile-repo \
                                -Dsonar.projectVersion=1.0 \
                                -Dsonar.sources=. \
                                -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
                                -Dsonar.junit.reportsPath=target/surefire-reports/ \
                                -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                                -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
                            """
                        }
                        timeout(time: 20, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }

                stage('OWASP Dependency-Check') {
                    steps {
                        script {
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
                                echo "✅ Dependency-Check CLI already exists."
                            }
                            echo "🔍 Running Dependency-Check scan..."
                            sh '''
                                mkdir -p dependency-check-report
                                dependency-check/dependency-check/bin/dependency-check.sh \
                                    --project "MyProject" \
                                    --scan . \
                                    --format "ALL" \
                                    --out dependency-check-report \
                                    --data dependency-check-data \
                                    --nvdApiKey $NVD_API_KEY \
                                    --prettyPrint
                            '''
                            echo "📄 Publishing Dependency-Check reports..."
                            dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml'
                        }
                    }
                }

                stage('Snyk Scans') {
                    steps {
                        sh '''
                            echo "⬇️ Installing latest Snyk CLI..."
                            curl -sL https://github.com/snyk/cli/releases/latest/download/snyk-linux -o snyk
                            chmod +x snyk
                            mv snyk /usr/local/bin/snyk
                            snyk --version

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

                            echo "🛠️ Running IaC Scan..."
                            snyk iac test --report --json-file-output=snyk-reports/snyk-iac.json || true

                            echo "💻 Running Snyk Code (SAST) Scan..."
                            snyk code test --project-name="devsecops-dvwa" --report --json-file-output=snyk-reports/snyk-code.json || true
                        '''
                        archiveArtifacts artifacts: 'snyk-reports/*.json', fingerprint: true
                    }
                }
            }
        }

        stage('Build DVWA') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    echo "🚀 Starting DVWA container"
                    script {
                        def running = sh(script: "docker ps --format '{{.Names}}' | grep -w dvwa_test_instance || true", returnStdout: true).trim()
                        if (running) {
                            echo "DVWA container is already running."
                        } else {
                            echo "DVWA container not running. Attempting to start..."
                            sh 'docker rm dvwa_test_instance || true'
                            sh 'docker run -d --name dvwa_test_instance -p 1337:80 vulnerables/web-dvwa'
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up temporary files..."
            sh 'rm -rf dependency-check/*.tmp'
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check logs for details."
        }
    }
}