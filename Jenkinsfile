pipeline {
  agent any

  environment {
    SONAR_HOST_URL = "http://167.86.125.122:1338"
  }

  stages {
    stage('Start SonarQube') {
      steps {
        echo "🚦 Starting SonarQube Community Edition using Docker..."
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
      }
    }

    stage('Checkout') {
      steps {
        echo "✅ Checking out code"
        checkout scm
      }
    }

    stage('Build && SonarQube analysis') {
      environment {
        scannerHome = tool 'sonar-scanner' // must match Manage Jenkins > Tools > SonarQube Scanner name
      }
      steps {
        withSonarQubeEnv('SonarQube Server') {  // replace with your SonarQube server name exactly
          sh """${scannerHome}/bin/sonar-scanner \
            -Dsonar.projectKey=vprofile \
            -Dsonar.projectName=vprofile-repo \
            -Dsonar.projectVersion=1.0 \
            -Dsonar.sources=src/ \
            -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
            -Dsonar.junit.reportsPath=target/surefire-reports/ \
            -Dsonar.jacoco.reportsPath=target/jacoco.exec \
            -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
          """
        }
      }
    }

    stage("Quality Gate") {
      steps {
        timeout(time: 1, unit: 'HOURS') {
          waitForQualityGate abortPipeline: true
        }
      }
    }

    // Add other stages as needed
  }
}