# Complete CI/CD and Automation Infrastructure

## Overview
This repository contains a comprehensive CI/CD and automation infrastructure for Java applications (Maven, JBoss/Wildfly) with complete integration of industry-standard tools and security best practices.

## 🏗️ Architecture

### Environments
- **QA**: Development testing and quality assurance
- **Staging**: Pre-production validation
- **Production**: Live production environment (highly secured)

### Tools Integrated
- **GitLab**: Source control and CI/CD orchestration
- **Jenkins**: Build automation and deployment pipelines
- **Nexus**: Artifact repository manager (separated by environment)
- **SonarQube**: Code quality and security analysis
- **HashiCorp Vault**: Secrets management
- **Grafana**: Monitoring dashboards
- **Loki**: Log aggregation
- **Prometheus**: Metrics collection
- **Ansible**: Configuration management and automation

## 📁 Repository Structure

```
automatizacion/
├── .gitlab-ci.yml                    # GitLab CI/CD configuration
├── .gitignore                        # Git ignore rules
├── Jenkinsfile                       # Basic Jenkins pipeline
│
├── ansible/                          # Ansible automation
│   ├── inventories/                  # Environment inventories
│   ├── playbooks/                    # Deployment playbooks
│   └── roles/                        # Ansible roles
│
├── ansible-blueprints/              # Ansible automation blueprints
│   ├── rsyslog/                     # Rsyslog configuration
│   ├── process-monitoring/          # Process monitoring
│   ├── disk-monitoring/             # Disk space monitoring
│   ├── glpi-agent/                  # GLPI agent setup
│   └── common/                      # Common tasks
│
├── config-repos/                    # Application configurations
│   ├── qa/                          # QA configurations
│   ├── staging/                     # Staging configurations
│   └── production/                  # Production configurations
│
├── docker/                          # Docker configurations
│   ├── docker-compose.yml           # Main compose file
│   └── README.md                    # Docker documentation
│
├── gitlab/                          # GitLab configuration
│   └── GITLAB_CONFIGURATION.md      # GitLab setup guide
│
├── jenkins/                         # Jenkins configuration
│   ├── Jenkinsfile-java-maven       # Java/Maven pipeline
│   └── shared-library/              # Jenkins shared libraries
│
├── nexus/                           # Nexus configuration
│   └── NEXUS_CONFIGURATION.md       # Nexus setup guide
│
├── vault/                           # Vault configuration
│   ├── VAULT_CONFIGURATION.md       # Vault setup guide
│   ├── policies/                    # Vault policies
│   └── scripts/                     # Vault automation scripts
│
├── sonarqube/                       # SonarQube configuration
│   └── quality-profiles/            # Quality profiles
│
├── grafana/                         # Grafana configuration
│   ├── GRAFANA_CONFIGURATION.md     # Grafana setup guide
│   ├── dashboards/                  # Dashboard definitions
│   └── provisioning/                # Auto-provisioning configs
│
├── loki/                            # Loki configuration
│   └── LOKI_CONFIGURATION.md        # Loki setup guide
│
├── scripts/                         # Utility scripts
│   ├── deploy-to-wildfly.sh         # Wildfly deployment
│   ├── scan-secrets.sh              # Secret scanning
│   ├── health-check.sh              # Health checks
│   └── send-notification.sh         # Notifications
│
├── pipelines/                       # Pipeline definitions
│   ├── build/                       # Build pipelines
│   ├── deploy/                      # Deployment pipelines
│   └── test/                        # Test pipelines
│
├── reports/                         # Generated reports
│   └── templates/                   # Report templates
│
├── notifications/                   # Notification templates
│   ├── email/                       # Email templates
│   ├── slack/                       # Slack templates
│   └── teams/                       # Teams templates
│
└── docs/                            # Documentation
    ├── QUICKSTART.md                # Quick start guide
    ├── SECURITY.md                  # Security guidelines
    ├── TROUBLESHOOTING.md           # Troubleshooting guide
    └── BEST_PRACTICES.md            # Best practices
```

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- Access to GitLab/GitHub
- JDK 17 or 18
- Maven 3.9+
- Ansible 2.9+

### 1. Clone Repository
```bash
git clone https://gitlab.company.com/infra-neo/automatizacion.git
cd automatizacion
```

### 2. Start CI/CD Infrastructure
```bash
cd docker
docker-compose up -d
```

### 3. Configure Tools

#### Jenkins
```bash
# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Access: http://localhost:8080
# Install suggested plugins
# Configure credentials for GitLab, Nexus, Vault
```

#### Nexus
```bash
# Get admin password
docker exec nexus cat /nexus-data/admin.password

# Access: http://localhost:8081
# Configure repositories (maven-qa, maven-staging, maven-production)
```

#### Vault
```bash
# Initialize Vault
docker exec -it vault vault operator init

# Unseal Vault (use keys from init)
docker exec -it vault vault operator unseal <key>

# Login and configure secrets
docker exec -it vault vault login <root-token>
docker exec -it vault vault secrets enable -path=secret kv-v2
```

### 4. Set Up GitLab CI/CD

#### Configure GitLab Variables
In GitLab project settings, add:
- `NEXUS_URL`
- `SONARQUBE_URL`
- `SONARQUBE_TOKEN`
- `VAULT_ADDRESS`
- `VAULT_TOKEN`
- Environment-specific credentials

#### Configure GitLab Runners
```bash
docker exec -it gitlab-runner gitlab-runner register
# Follow prompts to register runner
```

### 5. Deploy First Application

#### Using GitLab CI/CD
```bash
# Push to qa branch
git checkout -b qa
git push origin qa

# Pipeline will automatically:
# 1. Build application
# 2. Run tests
# 3. Perform security scans
# 4. Upload to Nexus
# 5. Deploy to QA environment
```

#### Using Jenkins
```bash
# Create new pipeline job
# Point to repository Jenkinsfile
# Configure parameters (ENVIRONMENT, JAVA_VERSION)
# Run build
```

## 🔐 Security

### Secrets Management
All sensitive data is stored in HashiCorp Vault:
```bash
# Store database password
vault kv put secret/qa/database password="secret123"

# Retrieve in pipeline
vault kv get -field=password secret/qa/database
```

### Secret Scanning
Automatic scanning for hardcoded secrets:
```bash
./scripts/scan-secrets.sh
```

### Code Security Scanning
- **SonarQube**: Static code analysis
- **OWASP Dependency Check**: Vulnerability scanning
- **GitLab Secret Detection**: Prevent secret commits

## 📊 Monitoring

### Access Grafana
```
URL: http://localhost:3000
User: admin
Pass: admin
```

### View Logs in Loki
```logql
# View application logs
{job="application", environment="production"}

# Filter errors
{job="application"} |= "ERROR"

# View deployment logs
{job="cicd"} |= "deployment"
```

### Prometheus Metrics
```
URL: http://localhost:9090
```

## 🔧 Configuration

### Application Configuration by Environment

#### QA Environment
```bash
config-repos/qa/app1/application.properties
```

#### Staging Environment
```bash
config-repos/staging/app1/application.properties
```

#### Production Environment
```bash
config-repos/production/app1/application.properties
```

### Maven Settings
```xml
<!-- Use environment-specific settings -->
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>${env.NEXUS_USER}</username>
      <password>${env.NEXUS_PASSWORD}</password>
    </server>
  </servers>
</settings>
```

## 🤖 Ansible Automation

### Available Blueprints

#### Configure Rsyslog
```bash
ansible-playbook -i inventories/production/hosts \
  ansible-blueprints/rsyslog/configure-rsyslog.yml
```

#### Monitor Processes
```bash
ansible-playbook -i inventories/production/hosts \
  ansible-blueprints/process-monitoring/monitor-processes.yml
```

#### Monitor Disk Space
```bash
ansible-playbook -i inventories/production/hosts \
  ansible-blueprints/disk-monitoring/monitor-disk-space.yml
```

#### Configure GLPI Agent
```bash
ansible-playbook -i inventories/production/hosts \
  ansible-blueprints/glpi-agent/configure-glpi-agent.yml
```

## 📧 Notifications

### Email Notifications
Configured in pipelines to send alerts on:
- Build failures
- Deployment success/failure
- Security vulnerabilities
- Quality gate failures

### Slack/Teams Integration
```bash
# Set webhook URLs
export SLACK_WEBHOOK="https://hooks.slack.com/..."
export TEAMS_WEBHOOK="https://outlook.office.com/webhook/..."

# Send notification
./scripts/send-notification.sh success production "Deployment completed"
```

## 🏭 Production Deployment

### Requirements
1. Approval from "implementacion" group (minimum 2 members)
2. All tests passing
3. Security scans passed
4. Code review approved
5. Staging validation completed

### Deployment Process
```bash
# 1. Merge to production branch
git checkout production
git merge staging
git push origin production

# 2. GitLab CI/CD creates deployment package

# 3. Manual approval required in GitLab

# 4. Automated deployment with rollback capability

# 5. Post-deployment verification

# 6. Notification sent to stakeholders
```

## 📖 Documentation

### Complete Guides
- [GitLab Configuration](gitlab/GITLAB_CONFIGURATION.md)
- [Nexus Configuration](nexus/NEXUS_CONFIGURATION.md)
- [Vault Configuration](vault/VAULT_CONFIGURATION.md)
- [Grafana Configuration](grafana/GRAFANA_CONFIGURATION.md)
- [Loki Configuration](loki/LOKI_CONFIGURATION.md)
- [Docker Setup](docker/README.md)

### Best Practices
- Never commit secrets to code
- Use environment variables for configuration
- Always test in QA before staging
- Require code reviews for all changes
- Maintain comprehensive logs
- Regular security audits
- Automated backups

## 🛠️ Troubleshooting

### Common Issues

#### Pipeline Fails at Secret Scanning
```bash
# Review scan results
./scripts/scan-secrets.sh

# Remove any hardcoded secrets
# Use Vault instead
```

#### Deployment Fails
```bash
# Check health endpoint
./scripts/health-check.sh qa

# View logs
docker-compose logs wildfly
```

#### Cannot Access Vault
```bash
# Check Vault status
docker exec vault vault status

# Unseal if needed
docker exec vault vault operator unseal
```

## 👥 Access Control

### Group Permissions

#### implementacion Group
- Full access to all environments
- Can deploy to staging and production
- Can manage secrets and configurations

#### developers Group
- Access to QA environment
- Can create merge requests
- Cannot deploy to production

#### qa-team Group
- Access to QA environment
- Can approve QA deployments
- Read-only access to staging

## 🔄 Backup and Disaster Recovery

### Automated Backups
```bash
# Daily backups configured for:
# - Nexus artifacts (production: 90 days retention)
# - Vault secrets (encrypted backups)
# - Grafana dashboards
# - Configuration repositories
```

### Recovery Procedures
See individual tool documentation for recovery procedures.

## 📞 Support

For issues or questions:
- Create an issue in GitLab
- Contact: infra-neo team
- Documentation: See docs/ folder

## 📄 License

Internal use only - Company proprietary

## 🙏 Acknowledgments

Built using industry-standard open-source tools:
- Jenkins
- Nexus Repository
- SonarQube
- HashiCorp Vault
- Grafana
- Prometheus
- Loki
- Ansible
