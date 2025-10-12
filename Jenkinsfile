pipeline {
  agent any

  environment {
    SONAR_HOST_URL = "http://167.86.125.122:1338"
    SNYK_TOKEN = credentials('snyk-token-id')
    DEPTRACK_API_KEY = credentials('dependencytrack-api-key')
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
        echo "🔍 Running SonarQube scan..."
        withSonarQubeEnv('SonarQube Server') {
          sh "sonar-scanner -Dsonar.projectKey=myProjectKey -Dsonar.sources=./ -Dsonar.host.url=${SONAR_HOST_URL}"
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

    stage('OWASP Dependency-Check') {
      steps {
        echo "🔍 Running OWASP Dependency-Check SCA scan..."
        sh '''
          dependency-check.sh --project MyProjectName --scan . --format HTML --out dependency-check-report
        '''
        archiveArtifacts artifacts: 'dependency-check-report/*.html'
      }
    }

    stage('Collect Docker Images and Run Snyk') {
      environment {
        SNYK_TOKEN = credentials('snyk-token-id')
      }
      steps {
        script {
          // Extract base Docker images referenced in Dockerfiles
          def images = sh(script: "grep -r '^FROM ' --include Dockerfile* . | awk '{print \$2}' | sort | uniq", returnStdout: true).trim()

          if (images) {
            echo "Docker base images found:\n${images}"

            // Authenticate Snyk CLI
            sh "snyk auth ${SNYK_TOKEN}"

            // Run general Snyk scans on all projects
            sh "snyk test --all-projects"
            sh "snyk monitor --all-projects"

            // Scan each Docker image found
            def imagesList = images.split('\\n')
            for (img in imagesList) {
              echo "Running Snyk container scan on image: ${img}"
              try {
                sh "snyk container test ${img}"
                sh "snyk container monitor ${img}"
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