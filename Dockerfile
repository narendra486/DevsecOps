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
    tini -y \ 
    software-properties-common \
    lsb-release && \
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

# Optionally, disable strict host key checking (not recommended for production):
# ENV GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
# ----------------------------
# 7️⃣ Add DevSecOps Tools (Trivy, Hadolint, Semgrep)
# ----------------------------
RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/* && \
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
    curl -sL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o /usr/local/bin/hadolint && \
    chmod +x /usr/local/bin/hadolint && \
    pip3 install --break-system-packages semgrep

# ----------------------------
# 8️⃣ Fix SSH-Agent socket permissions for Git Plugin and Docker socket
# ----------------------------
RUN chown -R jenkins:jenkins /var/run && \
    chmod -R 755 /var/run

# 8.1️⃣ (Recommended) When running the container, mount the Docker socket:
#   -v /var/run/docker.sock:/var/run/docker.sock
# This allows Jenkins jobs to use Docker CLI on the host.

# ----------------------------
# 9️⃣ Switch back to Jenkins user
# ----------------------------
USER jenkins

# Expose Jenkins ports
EXPOSE 8080
EXPOSE 50000


# Use the default CMD from the Jenkins base image (no override)


# Example run command:
# docker run -d \
#   -p 8080:8080 -p 50000:50000 \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   --name jenkins-dev-container jenkins-dev
