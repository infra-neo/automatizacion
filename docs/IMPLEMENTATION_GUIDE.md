# Complete Implementation Guide

## Overview

This guide provides step-by-step instructions for implementing the complete infrastructure automation solution, including Ansible playbooks, Docker services, Jenkins pipelines, and monitoring integration.

## Prerequisites

### System Requirements

- **Operating System:** Linux (Ubuntu 20.04+ or RHEL/CentOS 7+)
- **CPU:** 4+ cores
- **RAM:** 16GB+ (32GB recommended)
- **Disk:** 100GB+ available space
- **Docker:** 20.10+
- **Docker Compose:** 1.29+
- **Ansible:** 2.9+
- **Git:** 2.x+

### Network Requirements

- Ports to be accessible:
  - 80, 443 (Nginx)
  - 3000 (Grafana)
  - 3001 (Semaphore)
  - 8080 (Jenkins)
  - 8081, 8082 (Nexus)
  - 8090, 9990 (Wildfly)
  - 8888 (GLPI)
  - 9000 (SonarQube)
  - 9090 (Prometheus)

## Phase 1: Infrastructure Setup

### Step 1: Clone Repository

```bash
git clone https://github.com/infra-neo/automatizacion.git
cd automatizacion
```

### Step 2: Deploy Docker Services

```bash
# Navigate to docker directory
cd docker

# Start all services
docker-compose up -d

# Verify all services are running
docker-compose ps

# Check logs
docker-compose logs -f
```

**Expected Output:**
```
✓ jenkins ... running
✓ semaphore ... running
✓ glpi ... running
✓ wildfly ... running
✓ grafana ... running
✓ prometheus ... running
✓ loki ... running
✓ nexus ... running
```

### Step 3: Initial Service Configuration

#### Jenkins Configuration
```bash
# Access Jenkins
open http://localhost:8080

# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Follow setup wizard
# Install suggested plugins
# Create admin user
```

#### Semaphore Configuration
```bash
# Access Semaphore
open http://localhost:3001

# Login with default credentials
Username: admin
Password: admin

# Change password immediately
# Create new project
# Add Git repository
```

#### GLPI Configuration
```bash
# Access GLPI
open http://localhost:8888

# Follow installation wizard
# Database configuration:
Host: glpi-db
Database: glpi
User: glpi
Password: glpi

# Change all default passwords
```

#### Grafana Configuration
```bash
# Access Grafana
open http://localhost:3000

# Login
Username: admin
Password: admin

# Add data sources:
# 1. Prometheus (http://prometheus:9090)
# 2. Loki (http://loki:3100)
# 3. MySQL for GLPI (glpi-db:3306)
```

## Phase 2: Ansible Configuration

### Step 1: Configure Inventory

```bash
# Create production inventory
cat > ansible/inventories/production/hosts << 'EOF'
[all:vars]
ansible_user=ansible
ansible_become=yes
ansible_python_interpreter=/usr/bin/python3

[webservers]
web1.company.com
web2.company.com

[databases]
db1.company.com

[monitoring]
monitor.company.com

[appservers]
app1.company.com
app2.company.com
EOF
```

### Step 2: Test Ansible Connectivity

```bash
# Test ping
ansible all -i ansible/inventories/production/hosts -m ping

# Test sudo access
ansible all -i ansible/inventories/production/hosts -m shell -a "whoami" --become
```

### Step 3: Configure SSH Keys

```bash
# Generate SSH key if needed
ssh-keygen -t rsa -b 4096 -C "ansible@automation"

# Copy to managed hosts
for host in web1 web2 db1 app1 app2; do
    ssh-copy-id ansible@${host}.company.com
done
```

## Phase 3: Service Configuration

### Step 1: Configure Rsyslog

```bash
# Run configuration playbook
ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/rsyslog/configure-rsyslog.yml \
    -e "central_log_server=syslog.company.com"

# Validate configuration
ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/rsyslog/validate-rsyslog.yml
```

**Expected Output:**
```
TASK [Display validation summary]
ok: [web1.company.com] => {
    "msg": [
        "Host: web1.company.com",
        "Service Running: YES",
        "Configuration Valid: YES",
        "Test Message Delivered: YES"
    ]
}
```

### Step 2: Configure Logrotate

```bash
# Run configuration playbook
ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/logrotate/configure-logrotate.yml \
    -e "log_rotation_count=7" \
    -e "max_size=200M"

# Validate configuration
ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/logrotate/validate-logrotate.yml
```

**Expected Output:**
```
TASK [Display configuration summary]
ok: [web1.company.com] => {
    "msg": [
        "Host: web1.company.com",
        "Configuration Valid: YES",
        "Rotations to Keep: 7",
        "Max Size: 200M"
    ]
}
```

### Step 3: Deploy GLPI Agents

```bash
# Deploy GLPI agents
ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/glpi-agent/configure-glpi-agent.yml \
    -e "glpi_server=http://glpi:8888/plugins/fusioninventory"

# Force immediate inventory
ansible all -i ansible/inventories/production/hosts \
    -m shell \
    -a "glpi-agent --server http://glpi:8888/plugins/fusioninventory --force" \
    --become
```

**Verify in GLPI:**
1. Navigate to Plugins > FusionInventory > Agents
2. Verify all hosts are listed
3. Check inventory data

### Step 4: Configure Zabbix Agents (Optional)

```bash
# Deploy Zabbix agents
ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/zabbix/configure-zabbix-agent.yml \
    -e "zabbix_server=zabbix.company.com"
```

## Phase 4: Jenkins Pipeline Setup

### Step 1: Create Pipeline Jobs

**Rsyslog Validation Pipeline:**
```bash
# In Jenkins UI:
1. New Item > Pipeline
2. Name: rsyslog-validation
3. Pipeline > Definition: Pipeline script from SCM
4. SCM: Git
5. Repository URL: https://github.com/infra-neo/automatizacion
6. Script Path: jenkins/Jenkinsfile-rsyslog-validation
7. Save
```

**Logrotate Validation Pipeline:**
```bash
# In Jenkins UI:
1. New Item > Pipeline
2. Name: logrotate-validation
3. Pipeline script from SCM
4. Script Path: jenkins/Jenkinsfile-logrotate-validation
5. Save
```

**Wildfly Deployment Pipeline:**
```bash
# In Jenkins UI:
1. New Item > Pipeline
2. Name: wildfly-deployment
3. Pipeline script from SCM
4. Script Path: jenkins/Jenkinsfile-wildfly-deployment
5. Save
```

### Step 2: Configure Credentials

```bash
# In Jenkins > Credentials > System > Global credentials

Add:
1. Username/Password
   - ID: wildfly-admin-user
   - Username: admin
   - Password: <wildfly-password>

2. Username/Password
   - ID: nexus-credentials
   - Username: <nexus-user>
   - Password: <nexus-password>

3. Secret file
   - ID: config_env_secret
   - File: config.env
```

### Step 3: Test Pipelines

```bash
# Test rsyslog validation
# In Jenkins, run rsyslog-validation job with parameters:
Environment: qa
Target Hosts: all

# Test logrotate validation
# Run logrotate-validation job

# Test Wildfly deployment (if artifact available)
# Run wildfly-deployment job with parameters:
Environment: qa
Artifact Version: latest
```

## Phase 5: Semaphore Configuration

### Step 1: Create Semaphore Project

```bash
# In Semaphore UI (http://localhost:3001):
1. Click "New Project"
2. Name: Infrastructure Automation
3. Save
```

### Step 2: Add Key Store

```bash
1. Key Store > New Key
2. Type: SSH
3. Name: ansible-ssh-key
4. Upload private SSH key
5. Save
```

### Step 3: Add Inventory

```bash
1. Environment > Inventory > New Inventory
2. Name: Production
3. Type: File
4. Content: (paste inventory file content)
5. Save
```

### Step 4: Add Repository

```bash
1. Environment > Repositories > New Repository
2. Name: Automatizacion
3. URL: https://github.com/infra-neo/automatizacion
4. Branch: main
5. Access Key: ansible-ssh-key
6. Save
```

### Step 5: Import Blueprint

```bash
1. Task Templates > New Template
2. Import from file: semaphore-blueprint.json
3. Or manually create templates for:
   - Configure Rsyslog
   - Validate Rsyslog
   - Configure Logrotate
   - Validate Logrotate
   - Configure GLPI Agent
   - Full System Configuration
```

### Step 6: Run Tasks

```bash
# Run via UI:
1. Select template
2. Configure environment variables
3. Click "Run"
4. Monitor execution in real-time

# Or via API:
curl -X POST http://localhost:3001/api/project/1/tasks \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "template_id": 1,
    "environment": {"ENVIRONMENT": "production"}
  }'
```

## Phase 6: Monitoring Setup

### Step 1: Configure Grafana Dashboards

```bash
# Import dashboards
1. In Grafana, go to Dashboards > Import
2. Upload: grafana/dashboards/infrastructure-monitoring.json
3. Select data sources:
   - Prometheus
   - Loki
   - MySQL (GLPI)
4. Import
```

### Step 2: Configure Prometheus Targets

```bash
# Edit prometheus.yml
cat >> docker/prometheus/prometheus.yml << 'EOF'
scrape_configs:
  - job_name: 'wildfly'
    static_configs:
      - targets: ['wildfly:9990']
  
  - job_name: 'glpi'
    static_configs:
      - targets: ['glpi:8888']
  
  - job_name: 'jenkins'
    static_configs:
      - targets: ['jenkins:8080']
EOF

# Reload Prometheus
docker-compose restart prometheus
```

### Step 3: Configure Loki Log Sources

```bash
# Logs are automatically collected from:
- Docker containers (via Promtail)
- Rsyslog forwarding
- Application logs
```

### Step 4: Set Up Alerts

```bash
# Create alert rules in Grafana
1. Alerting > Alert rules > New alert rule
2. Configure alerts for:
   - Service down
   - Inventory not updated (> 48h)
   - Deployment failures
   - Log errors
3. Configure notification channels
```

## Phase 7: Validation and Testing

### Step 1: Full System Test

```bash
# Run full configuration
ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/rsyslog/configure-rsyslog.yml

ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/logrotate/configure-logrotate.yml

ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/glpi-agent/configure-glpi-agent.yml
```

### Step 2: Run All Validations

```bash
# Via Semaphore
# Run "Full System Validation" task

# Or via Ansible
ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/rsyslog/validate-rsyslog.yml

ansible-playbook -i ansible/inventories/production/hosts \
    ansible-blueprints/logrotate/validate-logrotate.yml
```

### Step 3: Review Reports

```bash
# Check generated reports
ls -la reports/

# View reports
cat reports/rsyslog-validation-*.txt
cat reports/logrotate-validation-*.txt
cat reports/glpi-*.txt
```

### Step 4: Test Wildfly Deployment

```bash
# Create test WAR file
mkdir -p test-app/WEB-INF
cat > test-app/index.html << 'EOF'
<html><body><h1>Test Application</h1></body></html>
EOF

cd test-app
jar -cvf ../test.war *
cd ..

# Deploy via Jenkins pipeline
# Or manually:
docker cp test.war wildfly:/opt/jboss/wildfly/standalone/deployments/

# Verify deployment
curl http://localhost:8090/test/
```

## Phase 8: Documentation

### Step 1: Take Screenshots

Capture screenshots of:
```bash
docs/screenshots/
├── ansible/
│   ├── rsyslog-config.png
│   ├── rsyslog-validation.png
│   ├── logrotate-config.png
│   └── logrotate-validation.png
├── jenkins/
│   ├── rsyslog-pipeline.png
│   ├── logrotate-pipeline.png
│   └── wildfly-deployment.png
├── semaphore/
│   ├── dashboard.png
│   ├── task-execution.png
│   └── inventory-view.png
├── glpi/
│   ├── inventory-overview.png
│   ├── computer-details.png
│   └── agent-status.png
└── grafana/
    ├── infrastructure-dashboard.png
    ├── log-viewer.png
    └── metrics-graphs.png
```

### Step 2: Document Execution Results

Create documentation for each component showing:
- Configuration steps
- Execution output
- Validation results
- Common issues and solutions

## Maintenance Schedule

### Daily Tasks
```bash
# Check service health
docker-compose ps

# Review logs
docker-compose logs --tail=100

# Monitor Grafana dashboards
```

### Weekly Tasks
```bash
# Run validation playbooks
ansible-playbook validate-all.yml

# Review GLPI inventory updates
# Check for outdated agents

# Review deployment logs
# Update documentation
```

### Monthly Tasks
```bash
# Update Docker images
docker-compose pull
docker-compose up -d

# Database maintenance
docker exec glpi-db mysqlcheck --optimize glpi

# Backup volumes
./scripts/backup-volumes.sh

# Review and update Ansible playbooks
# Security updates
```

## Troubleshooting

### Service Issues

**Service won't start:**
```bash
# Check logs
docker-compose logs <service>

# Check port conflicts
netstat -tuln | grep <port>

# Restart service
docker-compose restart <service>
```

**Ansible connection issues:**
```bash
# Test connectivity
ansible all -i inventory -m ping -vvv

# Check SSH keys
ssh -v ansible@target-host

# Verify sudo access
ansible all -m shell -a "whoami" --become
```

**Pipeline failures:**
```bash
# Check Jenkins logs
docker logs jenkins

# Review pipeline console output
# Verify credentials
# Check Ansible inventory
```

## Security Checklist

- [ ] Change all default passwords
- [ ] Configure firewall rules
- [ ] Enable SSL/TLS on all services
- [ ] Set up regular backups
- [ ] Configure log retention
- [ ] Enable audit logging
- [ ] Implement access controls
- [ ] Regular security updates
- [ ] Monitor security logs
- [ ] Document security procedures

## Success Criteria

✓ All Docker services running
✓ Ansible playbooks executing successfully
✓ Jenkins pipelines configured and tested
✓ Semaphore tasks executing
✓ GLPI collecting inventory
✓ Grafana dashboards displaying data
✓ Validation reports generated
✓ Documentation complete with screenshots

## Next Steps

1. Configure production inventories
2. Set up monitoring alerts
3. Implement backup strategy
4. Train team on tools
5. Document custom procedures
6. Set up disaster recovery
7. Configure log retention policies
8. Implement compliance checks

## Support and Resources

- **Documentation:** `docs/` directory
- **Ansible Playbooks:** `ANSIBLE_PLAYBOOKS.md`
- **Docker Services:** `DOCKER_SERVICES.md`
- **Jenkins Pipelines:** `JENKINS_PIPELINES.md`
- **GLPI Integration:** `GLPI_INTEGRATION.md`
- **Troubleshooting:** `TROUBLESHOOTING.md`

## Appendix

### Useful Commands

```bash
# Docker
docker-compose ps
docker-compose logs -f <service>
docker-compose restart <service>
docker-compose down
docker-compose up -d

# Ansible
ansible-playbook -i inventory playbook.yml
ansible all -i inventory -m ping
ansible-playbook --check playbook.yml
ansible-playbook --tags tag1,tag2 playbook.yml

# Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080 build job-name
java -jar jenkins-cli.jar -s http://localhost:8080 console job-name

# Git
git status
git add .
git commit -m "message"
git push origin branch-name
```

### Configuration Files

Key configuration files:
- `docker/docker-compose.yml` - Docker services
- `ansible/inventories/*/hosts` - Ansible inventories
- `grafana/dashboards/*.json` - Grafana dashboards
- `jenkins/Jenkinsfile-*` - Jenkins pipelines
- `semaphore-blueprint.json` - Semaphore tasks
