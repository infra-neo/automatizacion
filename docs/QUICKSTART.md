# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Clone and Start Infrastructure

```bash
# Clone repository
git clone https://github.com/infra-neo/automatizacion.git
cd automatizacion

# Start all CI/CD tools
cd docker
docker-compose up -d

# Wait for services to start (2-3 minutes)
docker-compose ps
```

### Step 2: Access Services

Open your browser and access:

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Jenkins | http://localhost:8080 | Get from: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword` |
| Nexus | http://localhost:8081 | admin / Get from: `docker exec nexus cat /nexus-data/admin.password` |
| SonarQube | http://localhost:9000 | admin / admin |
| Grafana | http://localhost:3000 | admin / admin |
| Vault | http://localhost:8200 | root-token (dev mode) |

### Step 3: Configure Jenkins

```bash
# Get initial password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Open http://localhost:8080
# 1. Enter password
# 2. Install suggested plugins
# 3. Create admin user
# 4. Save and finish
```

### Step 4: Create Your First Pipeline

1. In Jenkins, click "New Item"
2. Enter name: "my-java-app"
3. Select "Pipeline"
4. In Pipeline section, select "Pipeline script from SCM"
5. SCM: Git
6. Repository URL: your-repo-url
7. Script Path: `jenkins/Jenkinsfile-java-maven`
8. Save and build!

### Step 5: Configure Vault for Secrets

```bash
# Access Vault container
docker exec -it vault sh

# Login (dev mode uses root-token)
vault login root-token

# Enable KV secrets engine
vault secrets enable -path=secret kv-v2

# Store your first secret
vault kv put secret/qa/database \
  host="db-qa.company.com" \
  port="5432" \
  username="dbuser" \
  password="your-secure-password"

# Verify
vault kv get secret/qa/database
```

## 🎯 Common Tasks

### Deploy Application to QA

```bash
# Using GitLab CI/CD
git checkout -b qa
git push origin qa
# Pipeline runs automatically

# Using Jenkins
# 1. Open pipeline job
# 2. Click "Build with Parameters"
# 3. Select Environment: qa
# 4. Click Build
```

### View Application Logs

```bash
# Using Grafana/Loki
# 1. Open Grafana: http://localhost:3000
# 2. Go to Explore
# 3. Select Loki datasource
# 4. Query: {job="application",environment="qa"}
```

### Monitor Build Metrics

```bash
# Using Grafana
# 1. Open Grafana: http://localhost:3000
# 2. Go to Dashboards
# 3. Import dashboard from grafana/dashboards/
# 4. View CI/CD metrics
```

### Run Ansible Automation

```bash
# Configure rsyslog on servers
cd ansible-blueprints
ansible-playbook -i ../ansible/inventories/production/hosts \
  rsyslog/configure-rsyslog.yml

# Monitor disk space
ansible-playbook -i ../ansible/inventories/production/hosts \
  disk-monitoring/monitor-disk-space.yml
```

## 🔐 Security Quick Setup

### 1. Scan Code for Secrets

```bash
cd /home/runner/work/automatizacion/automatizacion
./scripts/scan-secrets.sh
```

### 2. Run SonarQube Analysis

```bash
# From your Java project
mvn clean verify sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=your-token
```

### 3. Check for Vulnerabilities

```bash
# OWASP Dependency Check
mvn org.owasp:dependency-check-maven:check
```

## 📊 View Reports

### Build Reports (Jenkins)
1. Open Jenkins job
2. Click on build number
3. View:
   - Console Output
   - Test Results
   - OWASP Report
   - Artifacts

### Code Quality (SonarQube)
1. Open SonarQube: http://localhost:9000
2. View project dashboard
3. Check:
   - Bugs
   - Vulnerabilities
   - Code Smells
   - Coverage

### Artifact Repository (Nexus)
1. Open Nexus: http://localhost:8081
2. Browse repositories
3. View uploaded artifacts

## 🆘 Troubleshooting

### Services Won't Start

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f <service-name>

# Restart service
docker-compose restart <service-name>
```

### Cannot Access Service

```bash
# Check if service is running
docker ps

# Check service health
docker inspect <container-name> | grep Health

# View service logs
docker logs <container-name>
```

### Pipeline Fails

```bash
# Check Jenkins console output
# Common issues:
# 1. Missing credentials → Configure in Jenkins Credentials
# 2. Vault unavailable → Check Vault status
# 3. Nexus connection → Verify Nexus is running
```

## 📚 Next Steps

1. **Read Full Documentation**: See [Complete Guide](README_COMPLETE.md)
2. **Configure Production**: Follow production setup guide
3. **Set Up Monitoring**: Configure Grafana dashboards
4. **Enable Notifications**: Set up email/Slack alerts
5. **Create Backups**: Implement backup strategy

## 🎓 Learn More

- [GitLab CI/CD Configuration](../gitlab/GITLAB_CONFIGURATION.md)
- [Jenkins Pipeline Guide](../jenkins/Jenkinsfile-java-maven)
- [Vault Secrets Management](../vault/VAULT_CONFIGURATION.md)
- [Monitoring Setup](../grafana/GRAFANA_CONFIGURATION.md)
- [Ansible Automation](../ansible-blueprints/)

## 💡 Tips

1. **Change default passwords** immediately in production
2. **Enable SSL/TLS** for all services
3. **Configure backups** before deploying to production
4. **Test in QA** before promoting to staging
5. **Document changes** in commit messages
6. **Review security scans** before deployment

---

Need help? Check the [Troubleshooting Guide](TROUBLESHOOTING.md) or create an issue.
