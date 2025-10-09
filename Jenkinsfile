pipeline {
    agent any

    environment {
        DVWA_TARGET_URL = 'http://167.86.125.122:1337'
        DVWA_CONTAINER_NAME = 'dvwa_test_instance'
        GIT_REPO = 'https://github.com/narendra486/DevsecOps.git' // HTTPS repo
        GIT_BRANCH = 'master' // or 'main'
        GIT_CREDENTIALS_ID = 'github-ssh' // Jenkins credentials ID for GitHub token
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Cleaning workspace and pulling latest code from GitHub...'
                cleanWs()
                retry(2) {
                    git url: "${GIT_REPO}",
                        branch: "${GIT_BRANCH}",
                        credentialsId: "${GIT_CREDENTIALS_ID}"
                }
            }
        }

        stage('Build and Deploy to Test/Staging') {
            steps {
                echo 'Stopping old DVWA container if exists...'
                sh "docker stop ${DVWA_CONTAINER_NAME} || true"
                sh "docker rm ${DVWA_CONTAINER_NAME} || true"

                echo 'Starting new DVWA container...'
                sh "docker run -d --name ${DVWA_CONTAINER_NAME} -p 1337:80 vulnerables/web-dvwa"

                echo 'Waiting for the application to start...'
                
                script {
                    // Retry loop to wait for app startup
                    def retries = 6
                    def wait = 10
                    def status = 0

                    for (int i = 1; i <= retries; i++) {
                        status = sh(
                            script: "curl -L -o /dev/null -s -w '%{http_code}' ${DVWA_TARGET_URL}",
                            returnStdout: true
                        ).trim()
                        echo "Attempt ${i}: HTTP status ${status}"

                        if (status == '200') {
                            echo "Application is up!"
                            break
                        }

                        if (i == retries) {
                            error "Application not reachable after ${retries} attempts! Last status: ${status}"
                        }

                        echo "Waiting ${wait} seconds before next attempt..."
                        sleep(wait)
                    }
                }

                echo "Deployment successful. Ready for DAST scan."
            }
        }

        stage('DAST Scan') {
            steps {
                echo "Running DAST Scan placeholder for ${DVWA_TARGET_URL}..."
                // Add your DAST scan commands here
            }
        }
    }

    post {
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
        failure {
            echo 'Build failed. Check logs for details.'
        }
    }
}