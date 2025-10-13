pipeline {
    agent any

    stages {
        stage('Run Snyk Test') {
            environment {
                SNYK_TOKEN = credentials('snyk-token-id')
            }
            steps {
                script {
                    def snykHome = tool name: 'Snyk', type: 'SnykInstallation'
                    
                    // Authenticate Snyk
                    sh "${snykHome}/bin/snyk auth ${SNYK_TOKEN}"
                    
                    // Run a simple Snyk scan on the repository
                    sh "${snykHome}/bin/snyk test"
                }
            }
        }
    }
}