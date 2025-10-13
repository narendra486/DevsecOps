pipeline {
    agent any

    environment {
        DC_VERSION = "12.1.7"
        DC_HOME = "${WORKSPACE}/dependency-check-${DC_VERSION}"
    }

stage('Install Dependency-Check') {
    steps {
        echo "📥 Downloading Dependency-Check CLI 12.1.7..."
        sh """
            curl -L -o dependency-check.zip https://github.com/dependency-check/DependencyCheck/releases/download/v12.1.7/dependency-check-12.1.7-release.zip
            unzip -q -o dependency-check.zip
            chmod +x ${WORKSPACE}/dependency-check/bin/dependency-check.sh
        """
    }
}

stage('Run OWASP Dependency-Check') {
    steps {
        echo "🔍 Running Dependency-Check scan..."
        sh """
            ${WORKSPACE}/dependency-check/bin/dependency-check.sh \
              --project MyProject \
              --scan . \
              --format HTML \
              --out dependency-check-report \
              --enableExperimental
        """
        archiveArtifacts artifacts: 'dependency-check-report/*.html', fingerprint: true
    }
}


}