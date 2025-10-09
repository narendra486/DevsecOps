pipeline {
    agent any

    environment {
        DVWA_TARGET_URL = 'http://167.86.125.122:1337'
        DVWA_CONTAINER_NAME = 'dvwa_test_instance'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Pulling latest code from GitHub...'
                git url: 'git@github.com:narendra486/DevsecOps.git', 
                    credentialsId: 'github-ssh', 
                    branch: 'master'
            }
        }
        
        stage('Build and Deploy to Test/Staging') {
            steps {
                echo 'Cleaning up old DVWA container and deploying new instance...'
                
                sh "docker stop ${DVWA_CONTAINER_NAME} || true" 
                sh "docker rm ${DVWA_CONTAINER_NAME} || true"

                sh "docker run -d --name ${DVWA_CONTAINER_NAME} -p 1337:80 vulnerables/web-dvwa"

                sh 'echo "Waiting 15 seconds for application startup..."; sleep 15'
                
                sh 'curl -f -s -o /dev/null -w "%{http_code}" ${DVWA_TARGET_URL}'
                echo "Deployment successful. Starting tests."
            }
        }
        
        stage('DAST Scan') {
            steps {
                echo "Application is ready at ${DVWA_TARGET_URL}. DAST Scan placeholder."
            }
        }
    }
}