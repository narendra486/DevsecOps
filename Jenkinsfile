pipeline {
  agent any

  environment {
    // Assume SonarQube token and server configured globally, no need to redeclare here
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
            def code = sh(script: "curl -L -o /dev/null -s -w '%{http_code}' http://167.86.125.122:1338", returnStdout: true).trim()
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
        echo "🔍 Running SonarQube scan..."
        withSonarQubeEnv('SonarQube Server') {
          sh 'sonar-scanner -Dsonar.projectKey=myProjectKey -Dsonar.sources=./ -Dsonar.host.url=http://167.86.125.122:1338'
        }
      }
    }

    stage('Quality Gate') {
      steps {
        echo "⏳ Waiting for SonarQube Quality Gate result..."
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    stage('Build DVWA') {
      steps {
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

    stage('Wait for DVWA Startup') {
      steps {
        echo "⌛ Waiting for DVWA to become ready..."
        script {
          sleep 60
          def code = sh(script: "curl -L -o /dev/null -s -w '%{http_code}' http://167.86.125.122:1337", returnStdout: true).trim()
          echo "HTTP code after 1 minute: ${code}"
          if (code == '200' || code == '302') {
            echo "DVWA is up (HTTP ${code})"
          } else {
            echo "Warning: DVWA is not reachable after 1 minute (HTTP ${code}). Pipeline will continue."
          }
        }
      }
    }

    stage('DAST Scan') {
      steps {
        echo "🧪 Running DAST scan (placeholder)..."
        // Add actual DAST scanning commands here
      }
    }
  }
}
