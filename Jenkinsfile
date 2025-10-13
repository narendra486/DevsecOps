pipeline {
  agent any

  environment {
    SONAR_HOST_URL = "http://167.86.125.122:1338"
    // sonarScanner 'Sonar-scanner'
  }

  stages {
    stage('Checkout') {
      steps {
        echo "✅ Checking out code"
        checkout scm
      }
    }

    stage('Build && SonarQube analysis') {
      environment {
        scannerHome = tool 'Sonar-scanner' // must match name in Manage Jenkins > Tools > SonarQube Scanner
      }
      steps {
        withSonarQubeEnv('sonar') { // 'sonar' must match the name of your SonarQube server in Jenkins settings
          sh '''${scannerHome}/bin/sonar-scanner \
            -Dsonar.projectKey=vprofile \
            -Dsonar.projectName=vprofile-repo \
            -Dsonar.projectVersion=1.0 \
            -Dsonar.sources=src/ \
            -Dsonar.java.binaries=target/test-classes/com/visualpathit/account/controllerTest/ \
            -Dsonar.junit.reportsPath=target/surefire-reports/ \
            -Dsonar.jacoco.reportsPath=target/jacoco.exec \
            -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml
          '''
        }
      }
    }

    stage("Quality Gate") {
      steps {
        timeout(time: 1, unit: 'HOURS') {
          // Will abort the pipeline if the quality gate fails
          waitForQualityGate abortPipeline: true
        }
      }
    }
    // ... Add other stages as needed ...
  }
}