# Use official Jenkins LTS image with JDK 17
FROM jenkins/jenkins:lts-jdk17

# Switch to root for setup
USER root

# ----------------------------
# 1️⃣ Install dependencies
# ----------------------------
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    tini \
    software-properties-common \
    lsb-release \
    unzip \
    wget \
    openjdk-17-jre \
    python3 \
    python3-pip && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------
# 2️⃣ Install Docker CLI & Compose
# ----------------------------
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------
# 2.1️⃣ Install Jenkins plugins from plugins.txt
# ----------------------------
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# ----------------------------
# 3️⃣ Add Docker group (Match Host GID)
# ----------------------------
# IMPORTANT: Match the Docker group GID to your host's Docker group for socket access.
# On host, run: `getent group docker` and use that GID below (default is often 999 or 109)
ARG DOCKER_GID=109
RUN groupadd -f -g $DOCKER_GID docker && \
    usermod -aG docker jenkins

# ----------------------------
# 4️⃣ Create SSH Directory and Fix Host Key Verification for GitHub
# ----------------------------
RUN mkdir -p /var/jenkins_home/.ssh && \
    chown -R jenkins:jenkins /var/jenkins_home/.ssh && \
    chmod 700 /var/jenkins_home/.ssh && \
    touch /var/jenkins_home/.ssh/known_hosts && \
    ssh-keyscan github.com >> /var/jenkins_home/.ssh/known_hosts && \
    chown jenkins:jenkins /var/jenkins_home/.ssh/known_hosts && \
    chmod 644 /var/jenkins_home/.ssh/known_hosts

# ----------------------------
# 6️⃣ Install SonarQube Scanner CLI
# ----------------------------
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -O /tmp/sonar-scanner.zip && \
    unzip /tmp/sonar-scanner.zip -d /opt && \
    ln -s /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip

# ----------------------------
# 7️⃣ Add DevSecOps Tools (Trivy, Hadolint, Semgrep)
# ----------------------------
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
    curl -sL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint && \
    chmod +x /usr/local/bin/hadolint && \
    pip3 install --break-system-packages semgrep

# ----------------------------
# 8️⃣ Fix SSH-Agent socket permissions for Git Plugin and Docker socket
# ----------------------------
RUN chown -R jenkins:jenkins /var/run && \
    chmod -R 755 /var/run

# ----------------------------
# 9️⃣ Switch back to Jenkins user
# ----------------------------
USER jenkins

# Expose Jenkins ports
EXPOSE 8080
EXPOSE 50000