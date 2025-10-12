pipeline {
  agent any

  environment {
    SONAR_HOST_URL = "http://167.86.125.122:1338"
    SNYK_TOKEN = credentials('snyk-token-id')
  }

  stages {
    stage('Start SonarQube') {
      steps {
        echo "🚦 Starting SonarQube Community Edition on port 1338..."
        script {
          def running = sh(script: "docker ps --format '{{.Names}}' | grep -w sonarqube || true", returnStdout: true).trim()
          if (!running) {
            sh 'docker compose up -d sonarqube'
            echo "SonarQube container started. Waiting for it to become healthy..."
            sleep 30
          } else {
            echo "SonarQube container already running."
          }
          def retries = 10
          def healthy = false
          for (int i = 1; i <= retries; i++) {
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
            echo "Warning: SonarQube did not become healthy in time, but pipeline will continue."
          }
        }
      }
    }

    stage('Checkout') {
      steps {
        echo "✅ Checking out repository"
        checkout scm
      }
    }

    stage('SonarQube Scan') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          echo "🔍 Running SonarQube scan..."
          withSonarQubeEnv('SonarQube Server') {
            sh "sonar-scanner -Dsonar.projectKey=myProjectKey -Dsonar.sources=./ -Dsonar.host.url=${SONAR_HOST_URL}"
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          echo "⏳ Waiting for SonarQube Quality Gate result..."
          script {
            def timeoutMinutes = 10
            def pollInterval = 60 * 1000 // 1 minute
            def startTime = System.currentTimeMillis()

            def response = sh(script: "curl -s ${SONAR_HOST_URL}/api/project_analyses/search?project=myProjectKey", returnStdout: true).trim()
            echo "SonarQube analysis search response: ${response}"
            if (!response?.trim()) {
              error "Empty response from SonarQube when searching analyses; cannot proceed."
            }

            def jsonResp = null
            try {
              jsonResp = readJSON text: response
            } catch (Exception e) {
              error "Failed to parse JSON from SonarQube analysis search: ${e.message}"
            }
            def taskId = jsonResp.analyses?.getAt(0)?.taskId
            if (!taskId) {
              error "Could not find analysis taskId in SonarQube response."
            }
            echo "Polling SonarQube task ID: ${taskId} every minute for quality gate result..."

            while (true) {
              def taskResp = sh(script: "curl -s ${SONAR_HOST_URL}/api/ce/task?id=${taskId}", returnStdout: true).trim()
              echo "SonarQube task status response: ${taskResp}"
              if (!taskResp?.trim()) {
                error "Empty response when polling task status."
              }

              def taskJson = null
              try {
                taskJson = readJSON text: taskResp
              } catch (Exception e) {
                error "Failed to parse JSON from task status: ${e.message}"
              }
              def status = taskJson.task?.status
              echo "SonarQube analysis status: ${status}"

              if (status == 'SUCCESS' || status == 'FAILED' || status == 'CANCELED') {
                if (status == 'SUCCESS') {
                  echo "Quality Gate passed!"
                } else {
                  error "Quality Gate failed or canceled with status: ${status}"
                }
                break
              }

              if ((System.currentTimeMillis() - startTime) > timeoutMinutes * 60 * 1000) {
                error "Timeout waiting for quality gate result"
              }

              sleep pollInterval / 1000
            }
          }
        }
      }
    }

    stage('Semgrep SAST Scan') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          echo "🔍 Running Semgrep SAST scan..."
          sh '''
            semgrep --config=auto --json --output=semgrep-results.json .
          '''
          archiveArtifacts artifacts: 'semgrep-results.json', fingerprint: true
        }
      }
    }

    stage('OWASP Dependency-Check') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          script {
            def dcHome = tool name: 'Dependency-Check', type: 'DependencyCheckInstallation'
            sh """
              ${dcHome}/bin/dependency-check.sh --version
              ${dcHome}/bin/dependency-check.sh --project MyProjectName --scan . --format HTML --out dependency-check-report
            """
          }
          archiveArtifacts artifacts: 'dependency-check-report/*.html'
        }
      }
    }

    stage('Collect Docker Images and Run Snyk') {
      environment {
        SNYK_TOKEN = credentials('snyk-token-id')
      }
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          script {
            def snykHome = tool name: 'Snyk', type: 'SnykInstallation'
            def images = sh(script: "grep -r '^FROM ' --include Dockerfile* . | awk '{print \$2}' | sort | uniq", returnStdout: true).trim()
            if (images) {
              echo "Docker base images found:\n${images}"
              sh "${snykHome}/bin/snyk auth ${SNYK_TOKEN}"
              sh "${snykHome}/bin/snyk test --all-projects"
              sh "${snykHome}/bin/snyk monitor --all-projects"
              def imagesList = images.split('\\n')
              for (img in imagesList) {
                echo "Running Snyk container test on image: ${img}"
                try {
                  sh "${snykHome}/bin/snyk container test ${img}"
                  sh "${snykHome}/bin/snyk container monitor ${img}"
                } catch (err) {
                  echo "Warning: Scan failed for image ${img} - ${err}"
                }
              }
            } else {
              echo "No Docker images found in Dockerfiles."
            }
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
}