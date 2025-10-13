pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        echo "✅ Checking out code"
        checkout scm
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
  }
}
