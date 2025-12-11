# Troubleshooting Guide

## Common Issues and Solutions

### 🐳 Docker Issues

#### Services Won't Start

**Problem**: `docker-compose up -d` fails or services don't start

**Solutions**:
```bash
# Check Docker is running
systemctl status docker

# Check available resources
docker system df

# Check service logs
docker-compose logs <service-name>

# Remove and recreate
docker-compose down -v
docker-compose up -d

# Increase memory for Docker Desktop
# Settings → Resources → Memory (minimum 8GB recommended)
```

#### Port Already in Use

**Problem**: `Error: port is already allocated`

**Solutions**:
```bash
# Find process using port
sudo lsof -i :<port-number>
# or
sudo netstat -tulpn | grep <port-number>

# Kill process
sudo kill -9 <pid>

# Or change port in docker-compose.yml
# ports:
#   - "8081:8080"  # Host:Container
```

#### Volume Permission Issues

**Problem**: Permission denied errors in containers

**Solutions**:
```bash
# Fix ownership
sudo chown -R $USER:$USER ./docker

# For specific volumes
docker run --rm -v <volume>:/data alpine chown -R 1000:1000 /data
```

### 🔧 Jenkins Issues

#### Cannot Access Jenkins

**Problem**: Jenkins shows 404 or connection refused

**Solutions**:
```bash
# Check if Jenkins is running
docker ps | grep jenkins

# Check logs
docker logs jenkins

# Restart Jenkins
docker-compose restart jenkins

# Wait for Jenkins to fully start (can take 2-3 minutes)
```

#### Build Fails with "Permission Denied"

**Problem**: Build fails accessing Docker socket

**Solutions**:
```bash
# Add Jenkins user to docker group in container
docker exec -u root jenkins usermod -aG docker jenkins
docker-compose restart jenkins
```

#### Vault Integration Fails

**Problem**: Cannot retrieve secrets from Vault

**Solutions**:
```bash
# Check Vault is unsealed
docker exec vault vault status

# Verify token
docker exec vault vault token lookup

# Check network connectivity
docker exec jenkins ping vault

# Verify Vault URL in Jenkins configuration
# Should be: http://vault:8200
```

### 📦 Nexus Issues

#### Cannot Upload Artifacts

**Problem**: `401 Unauthorized` or `403 Forbidden`

**Solutions**:
```bash
# Get admin password
docker exec nexus cat /nexus-data/admin.password

# Check Maven settings.xml has correct credentials
# Verify repository exists in Nexus
# Check repository write permissions for user
```

#### Nexus Won't Start

**Problem**: Nexus container keeps restarting

**Solutions**:
```bash
# Check logs
docker logs nexus

# Common issue: Insufficient memory
# Increase in docker-compose.yml:
# environment:
#   - INSTALL4J_ADD_VM_PARAMS=-Xms2g -Xmx4g

# Clear data and restart (WARNING: Deletes all artifacts)
docker-compose down
docker volume rm nexus_data
docker-compose up -d nexus
```

### 🔐 Vault Issues

#### Vault is Sealed

**Problem**: Cannot access secrets, Vault shows as sealed

**Solutions**:
```bash
# Check status
docker exec vault vault status

# Unseal Vault (requires unseal keys)
docker exec vault vault operator unseal <key1>
docker exec vault vault operator unseal <key2>
docker exec vault vault operator unseal <key3>

# For dev mode (auto-unsealed):
# Vault should unseal automatically on restart
docker-compose restart vault
```

#### Cannot Login to Vault

**Problem**: `vault login` fails

**Solutions**:
```bash
# For dev mode
docker exec vault vault login root-token

# For production, use proper token
docker exec vault vault login <your-token>

# Generate new token
docker exec vault vault token create
```

### 🔍 SonarQube Issues

#### Analysis Fails

**Problem**: Maven sonar:sonar fails

**Solutions**:
```bash
# Check SonarQube is accessible
curl http://localhost:9000/api/system/status

# Verify token is valid
curl -u <token>: http://localhost:9000/api/authentication/validate

# Run with debug
mvn sonar:sonar -X -Dsonar.verbose=true

# Check project exists in SonarQube
```

#### Quality Gate Always Fails

**Problem**: Quality gate fails even for good code

**Solutions**:
```bash
# Review quality gate conditions in SonarQube
# Quality Gates → Your Gate → Conditions

# Check which condition is failing
# View project → Quality Gate

# Adjust conditions or fix code issues
```

### 📊 Grafana Issues

#### No Data in Dashboards

**Problem**: Dashboards show "No Data"

**Solutions**:
```bash
# Verify data source connection
# Configuration → Data Sources → Test

# Check Prometheus is scraping targets
# http://localhost:9090/targets

# Verify metric names match
# Explore → Metrics browser

# Check time range in dashboard
```

#### Cannot Add Data Source

**Problem**: Data source configuration fails

**Solutions**:
```bash
# For Prometheus
# URL: http://prometheus:9090 (not localhost)

# For Loki
# URL: http://loki:3100

# Verify service is running
docker-compose ps

# Test connection manually
docker exec grafana curl http://prometheus:9090/api/v1/status/config
```

### 🔄 Pipeline Issues

#### Pipeline Hangs

**Problem**: Pipeline stuck in "pending" or specific stage

**Solutions**:
```bash
# Check Jenkins executor availability
# Manage Jenkins → Manage Nodes

# Check for stuck builds
# Jenkins → Build Queue

# Increase timeout in Jenkinsfile
# options {
#   timeout(time: 2, unit: 'HOURS')
# }

# Check agent availability
docker-compose ps gitlab-runner
```

#### Secret Not Found

**Problem**: `Vault secret not found`

**Solutions**:
```bash
# Verify secret exists
docker exec vault vault kv get secret/<environment>/<app>

# Check path in pipeline matches Vault path

# Verify Vault token has permissions
docker exec vault vault token capabilities secret/<environment>/<app>

# Check Vault policy
docker exec vault vault policy read <policy-name>
```

### 🌐 Network Issues

#### Services Cannot Communicate

**Problem**: Service A cannot reach Service B

**Solutions**:
```bash
# Check all services on same network
docker network inspect cicd-network

# Test connectivity
docker exec jenkins ping nexus
docker exec jenkins ping vault

# Ensure using service names, not localhost
# GOOD: http://nexus:8081
# BAD:  http://localhost:8081
```

### 💾 Storage Issues

#### Disk Space Full

**Problem**: No space left on device

**Solutions**:
```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a --volumes

# Remove old images
docker image prune -a

# Check volume sizes
docker system df -v

# Clean specific volumes (WARNING: Data loss)
docker volume rm <volume-name>
```

### 📧 Notification Issues

#### Email Not Sending

**Problem**: Email notifications not received

**Solutions**:
```bash
# Check SMTP configuration
# In Jenkins/GitLab configuration

# Test SMTP connection
telnet smtp.company.com 587

# Check email logs
docker-compose logs mailhog  # for dev

# Verify firewall allows outbound SMTP
```

## Emergency Procedures

### Complete Reset

**WARNING**: This deletes ALL data

```bash
cd docker
docker-compose down -v
docker system prune -a --volumes
docker-compose up -d
# Reconfigure all services
```

### Backup Before Reset

```bash
# Backup volumes
docker run --rm \
  -v jenkins_home:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/jenkins-backup.tar.gz -C /data .

# Repeat for other volumes
```

### Restore from Backup

```bash
# Restore volume
docker run --rm \
  -v jenkins_home:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/jenkins-backup.tar.gz -C /data

docker-compose restart jenkins
```

## Getting Help

### Collect Diagnostic Information

```bash
#!/bin/bash
# Save this as collect-diagnostics.sh

DIAG_DIR="diagnostics-$(date +%Y%m%d-%H%M%S)"
mkdir -p $DIAG_DIR

# Service status
docker-compose ps > $DIAG_DIR/services-status.txt

# Logs
for service in jenkins nexus sonarqube vault grafana prometheus loki; do
  docker logs $service > $DIAG_DIR/${service}.log 2>&1
done

# Docker info
docker info > $DIAG_DIR/docker-info.txt
docker system df > $DIAG_DIR/docker-df.txt

# Create archive
tar czf $DIAG_DIR.tar.gz $DIAG_DIR
echo "Diagnostics saved to: $DIAG_DIR.tar.gz"
```

### Create Support Ticket

Include:
1. Diagnostic information
2. Description of issue
3. Steps to reproduce
4. Expected vs actual behavior
5. Environment details

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Vault Documentation](https://www.vaultproject.io/docs)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)

---

**Still having issues?** Create an issue in the repository with diagnostic information.
