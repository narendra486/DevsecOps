pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        echo "✅ Checking out repository"
        sh 'ls -la'
      }
    }

    stage('Build DVWA') {
      steps {
        echo "🚀 Starting DVWA container"
        sh '''
          docker stop dvwa_test_instance || true
          docker rm dvwa_test_instance || true
          docker run -d --name dvwa_test_instance -p 1337:80 vulnerables/web-dvwa
        '''
      }
    }

    stage('Wait for DVWA Startup') {
      steps {
        echo "⌛ Waiting for DVWA to become ready..."
        script {
          sleep 60 // Wait 1 minute before first check
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
      }
    }
  }

  post {
    always {
      echo "🧹 Cleaning up containers"
      sh "docker stop dvwa_test_instance || true && docker rm dvwa_test_instance || true"
      cleanWs()
    }
  }
}