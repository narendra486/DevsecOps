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
          def retries = 5
          def success = false
          for (int i = 0; i < retries; i++) {
            def code = sh(script: "curl -L -o /dev/null -s -w '%{http_code}' http://127.0.0.1:1337", returnStdout: true).trim()
            echo "HTTP code: ${code} (attempt ${i + 1}/${retries})"
            if (code == '200' || code == '302') {
              echo "DVWA is up (HTTP ${code})"
              success = true
              break
            }
            echo "Still waiting for DVWA..."
            sleep 15
          }
          if (!success) {
            error "❌ DVWA failed to start in time after ${retries} attempts."
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