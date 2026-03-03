# 📌 Pre-Requisites

- Ubuntu EC2 instance
- Docker installed
- Security Group ports open:

| Service | Port |
|--------|-------|
| Jenkins | 8090 |
| SonarQube | 9000 |

---

# ☕ Install Java (JDK 17)

```bash
sudo apt update
sudo apt install openjdk-17-jre -y
```

Verify:

```bash
java -version
```

---

# 🔧 Install Jenkins

## Add Jenkins repository

```bash
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
```

## Install Jenkins

```bash
sudo apt update
sudo apt install jenkins -y
```

---

# 🔁 Change Jenkins Port (8080 → 8090)

```bash
sudo sed -i 's/Environment="JENKINS_PORT=8080"/Environment="JENKINS_PORT=8090"/' /usr/lib/systemd/system/jenkins.service
sudo systemctl daemon-reload
sudo systemctl restart jenkins
```

Open:

```
http://<EC2-IP>:8090
```

---

# 🔓 Give Jenkins Docker Access

```bash
sudo usermod -aG docker jenkins
```

---

# 🔑 Get Jenkins Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

# 📊 Install SonarQube

## Create user

```bash
sudo adduser sonarqube
```

## Download & Setup

```bash
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.4.1.88267.zip
sudo apt install unzip -y
sudo unzip sonarqube-10.4.1.88267.zip
sudo mv sonarqube-10.4.1.88267 sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube
```

---

## Create SonarQube Service

```bash
sudo nano /etc/systemd/system/sonarqube.service
```

Paste:

```ini
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```

---

## Start SonarQube

```bash
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube
sudo systemctl status sonarqube
```

Open:

```
http://<EC2-IP>:9000
```

---

# 🟢 Install Node.js 18

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs -y
```

Verify:

```bash
node -v
npm -v
```

---

# 🔍 Install Sonar Scanner

```bash
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip sonar-scanner-cli-5.0.1.3006-linux.zip
sudo mv sonar-scanner-5.0.1.3006-linux /opt/sonar-scanner
```

Add to PATH:

```bash
echo 'export PATH=$PATH:/opt/sonar-scanner/bin' | sudo tee -a /etc/environment
source /etc/environment
```

Verify:

```bash
sonar-scanner --version
```

Allow Jenkins access:

```bash
sudo ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner
sudo -u jenkins sonar-scanner --version
```

---

# 🔗 SonarQube → Jenkins Webhook

In SonarQube:

```
Administration → Configuration → Webhooks → Create
```

Add:

```
Name: jenkins
URL: http://<EC2-IP>:8090/sonarqube-webhook/
```

---

# 🔗 Configure SonarQube in Jenkins

```
Manage Jenkins → System → SonarQube Servers
```

Add:

```
Name: SonarQube
Server URL: http://<EC2-IP>:9000
Token: <your-token>
```

---

# 🔔 GitHub Webhook → Jenkins

In your repo on GitHub:

## Enable trigger in Jenkins

```
Job → Configure → Build Triggers
✔ GitHub hook trigger for GITScm polling
```

## Add webhook

```
Settings → Webhooks → Add webhook
```

Fill:

```
Payload URL: http://<EC2-IP>:8090/github-webhook/
Content type: application/json
Events: Just the push event
```

---

# ✅ Final Results

After setup:

- Jenkins → http://IP:8090
- SonarQube → http://IP:9000
- GitHub push → triggers Jenkins build

---

