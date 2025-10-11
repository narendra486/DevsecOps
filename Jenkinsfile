pipeline {
  agent any

  environment {
    SONAR_HOST_URL = "http://167.86.125.122:1338"
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
        timeout(time: 10, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
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
  }
}