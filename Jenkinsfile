pipeline {
  agent any

  environment {
    SONAR_HOST_URL = "http://167.86.125.122:1338"
    SNYK_TOKEN = credentials('snyk-token-id')
  }

  stages {
    stage('Start SonarQube') {
      steps {
        echo "🚦 Starting SonarQube Community Edition..."
        script {
          def running = sh(script: "docker ps --format '{{.Names}}' | grep -w sonarqube || true", returnStdout: true).trim()
          if (!running) {
            sh 'docker compose up -d sonarqube'
            echo "SonarQube container started; waiting for health."
            sleep 30
          } else {
            echo "SonarQube container already running."
          }
          def healthy = false
          for (int i = 1; i <= 10; i++) {
            def code = sh(script: "curl -L -o /dev/null -s -w '%{http_code}' ${SONAR_HOST_URL}", returnStdout: true).trim()
            echo "SonarQube HTTP code attempt ${i}: ${code}"
            if (code == '200') { healthy = true; break }
            sleep 10
          }
          if (!healthy) { echo "Warning: SonarQube did not become healthy in time." }
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
        echo "🔍 Running SonarQube scan..."
        withSonarQubeEnv('SonarQube Server') {
          sh "sonar-scanner -Dsonar.projectKey=myProjectKey -Dsonar.sources=./ -Dsonar.host.url=${SONAR_HOST_URL}"
        }
      }
    }

    stage('Quality Gate: Get Analysis') {
      steps {
        echo "⏳ Checking for analysis report..."
        script {
          env.SONAR_ANALYSIS_JSON = sh(script: "curl -s ${SONAR_HOST_URL}/api/project_analyses/search?project=myProjectKey", returnStdout: true).trim()
          echo "SonarQube analysis search response: ${env.SONAR_ANALYSIS_JSON}"
        }
      }
    }

    stage('Quality Gate: Extract TaskId') {
      steps {
        echo "🔍 Parsing analysis JSON for taskId..."
        script {
          if (!env.SONAR_ANALYSIS_JSON?.trim()) { error "Empty response when searching analyses." }
          def jsonResp = readJSON text: env.SONAR_ANALYSIS_JSON
          env.SONAR_TASK_ID = jsonResp.analyses?.getAt(0)?.taskId
          echo "Extracted SonarQube Task ID: ${env.SONAR_TASK_ID}"
          if (!env.SONAR_TASK_ID) { error "Could not find analysis taskId." }
        }
      }
    }

    stage('Quality Gate: Poll Status') {
      steps {
        echo "🔄 Polling SonarQube quality gate status..."
        script {
          def timeoutMinutes = 10
          def pollInterval = 60 * 1000 // 1 min
          def startTime = System.currentTimeMillis()
          while (true) {
            def taskResp = sh(script: "curl -s ${SONAR_HOST_URL}/api/ce/task?id=${env.SONAR_TASK_ID}", returnStdout: true).trim()
            echo "Task status response: ${taskResp}"
            if (!taskResp?.trim()) { error "Empty response when polling task status." }
            def taskJson = readJSON text: taskResp
            def status = taskJson.task?.status
            echo "SonarQube analysis status: ${status}"
            if (status in ['SUCCESS', 'FAILED', 'CANCELED']) {
              if (status != 'SUCCESS') { error "Quality Gate failed or canceled (${status})" }
              echo "Quality Gate passed!"
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

    stage('Semgrep SAST Scan') {
      steps {
        echo "🔍 Running Semgrep SAST scan..."
        sh '''
          semgrep --config=auto --json --output=semgrep-results.json .
        '''
        archiveArtifacts artifacts: 'semgrep-results.json', fingerprint: true
      }
    }

    stage('Dependency-Check Tool Setup') {
      steps {
        script {
          def dcHome = tool name: 'Dependency-Check', type: 'DependencyCheckInstallation'
          echo "Dependency-Check tool installed at: ${dcHome}"
        }
      }
    }

    stage('Dependency-Check Version') {
      steps {
        script {
          def dcHome = tool name: 'Dependency-Check', type: 'DependencyCheckInstallation'
          sh "${dcHome}/bin/dependency-check.sh --version"
        }
      }
    }

    stage('Dependency-Check Scan') {
      steps {
        script {
          def dcHome = tool name: 'Dependency-Check', type: 'DependencyCheckInstallation'
          sh "${dcHome}/bin/dependency-check.sh --project MyProjectName --scan . --format HTML --out dependency-check-report"
        }
        archiveArtifacts artifacts: 'dependency-check-report/*.html'
      }
    }

    stage('Snyk Tool Setup') {
      steps {
        script {
          def snykHome = tool name: 'Snyk', type: 'SnykInstallation'
          echo "Snyk tool installed at: ${snykHome}"
        }
      }
    }

    stage('Snyk Authenticate') {
      environment {
        SNYK_TOKEN = credentials('snyk-token-id')
      }
      steps {
        script {
          def snykHome = tool name: 'Snyk', type: 'SnykInstallation'
          sh "${snykHome}/bin/snyk auth ${SNYK_TOKEN}"
        }
      }
    }

    stage('Snyk Test All Projects') {
      steps {
        script {
          def snykHome = tool name: 'Snyk', type: 'SnykInstallation'
          sh "${snykHome}/bin/snyk test --all-projects"
        }
      }
    }

    stage('Snyk Monitor All Projects') {
      steps {
        script {
          def snykHome = tool name: 'Snyk', type: 'SnykInstallation'
          sh "${snykHome}/bin/snyk monitor --all-projects"
        }
      }
    }

    stage('Snyk Docker Image Scan') {
      steps {
        script {
          def snykHome = tool name: 'Snyk', type: 'SnykInstallation'
          def images = sh(script: "grep -r '^FROM ' --include Dockerfile* . | awk '{print \$2}' | sort | uniq", returnStdout: true).trim()
          if (images) {
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

    stage('Build DVWA Container') {
      steps {
        echo "🚀 Starting DVWA container"
        script {
          def running = sh(script: "docker ps --format '{{.Names}}' | grep -w dvwa_test_instance || true", returnStdout: true).trim()
          if (running) {
            echo "DVWA container is already running."
          } else {
            sh 'docker rm dvwa_test_instance || true'
            sh 'docker run -d --name dvwa_test_instance -p 1337:80 vulnerables/web-dvwa'
          }
        }
      }
    }
  }
}