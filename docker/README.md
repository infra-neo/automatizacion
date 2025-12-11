# Docker Compose Configuration for CI/CD Tools

## Quick Start

### Start All Services
```bash
cd docker
docker-compose up -d
```

### Check Service Status
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f jenkins
```

### Stop All Services
```bash
docker-compose down
```

### Stop and Remove Volumes
```bash
docker-compose down -v
```

## Service URLs

After starting the services, access them at:

- **Jenkins**: http://localhost:8080
- **Nexus**: http://localhost:8081
- **SonarQube**: http://localhost:9000
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **Vault**: http://localhost:8200
- **MailHog**: http://localhost:8025

## Default Credentials

### Jenkins
- Username: admin
- Password: Run `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`

### Nexus
- Username: admin
- Password: Run `docker exec nexus cat /nexus-data/admin.password`

### SonarQube
- Username: admin
- Password: admin (change on first login)

### Grafana
- Username: admin
- Password: admin (change on first login)

### Vault
- Root Token: root-token (DEV MODE - change for production)

## Environment-Specific Deployment

### QA Environment
```bash
docker-compose -f docker-compose.yml -f docker-compose.qa.yml up -d
```

### Staging Environment
```bash
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
```

### Production Environment
```bash
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
```

## Service Configuration

### Jenkins

#### Install Plugins
```bash
docker exec jenkins jenkins-plugin-cli --plugins \
  git \
  workflow-aggregator \
  docker-workflow \
  kubernetes \
  vault \
  sonar \
  nexus-artifact-uploader
```

#### Configure Jenkins
1. Access http://localhost:8080
2. Enter initial admin password
3. Install suggested plugins
4. Create admin user
5. Configure system settings

### Nexus

#### Configure Repositories
1. Access http://localhost:8081
2. Login with admin credentials
3. Create repositories:
   - maven-qa (hosted)
   - maven-staging (hosted)
   - maven-production (hosted)
   - maven-central-proxy (proxy)

#### Configure Blob Stores
```bash
# Via Nexus API
curl -X POST "http://localhost:8081/service/rest/v1/blobstores/file" \
  -u admin:password \
  -H "Content-Type: application/json" \
  -d '{
    "name": "qa-storage",
    "path": "/nexus-data/blobs/qa-storage"
  }'
```

### SonarQube

#### Initial Setup
1. Access http://localhost:9000
2. Login with admin/admin
3. Change password
4. Create project
5. Generate token for CI/CD integration

#### Configure Quality Gates
```bash
curl -X POST "http://localhost:9000/api/qualitygates/create" \
  -u admin:newpassword \
  -d "name=CI/CD Quality Gate"
```

### Vault

#### Initialize Vault (Production)
```bash
docker exec -it vault vault operator init
# Save unseal keys and root token securely!
```

#### Unseal Vault
```bash
docker exec -it vault vault operator unseal <key1>
docker exec -it vault vault operator unseal <key2>
docker exec -it vault vault operator unseal <key3>
```

#### Enable Secrets Engine
```bash
docker exec -it vault vault secrets enable -path=secret kv-v2
```

### Grafana

#### Add Data Sources
```bash
# Prometheus
curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://prometheus:9090",
    "access": "proxy",
    "isDefault": true
  }'

# Loki
curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Loki",
    "type": "loki",
    "url": "http://loki:3100",
    "access": "proxy"
  }'
```

## Backup and Restore

### Backup All Data
```bash
#!/bin/bash
BACKUP_DIR="/backup/cicd/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup volumes
docker run --rm \
  -v jenkins_home:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/jenkins_home.tar.gz -C /data .

docker run --rm \
  -v nexus_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/nexus_data.tar.gz -C /data .

docker run --rm \
  -v grafana_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/grafana_data.tar.gz -C /data .
```

### Restore Data
```bash
#!/bin/bash
BACKUP_DIR=$1

# Restore Jenkins
docker run --rm \
  -v jenkins_home:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar xzf /backup/jenkins_home.tar.gz -C /data

# Restart service
docker-compose restart jenkins
```

## Monitoring

### Health Checks
```bash
#!/bin/bash
# Check all services health

services=(jenkins nexus sonarqube grafana prometheus loki vault)

for service in "${services[@]}"; do
  status=$(docker inspect -f '{{.State.Health.Status}}' $service 2>/dev/null || echo "no healthcheck")
  echo "$service: $status"
done
```

### Resource Usage
```bash
docker stats --no-stream
```

## Troubleshooting

### View Container Logs
```bash
docker logs -f <container_name>
```

### Access Container Shell
```bash
docker exec -it <container_name> /bin/bash
```

### Restart Service
```bash
docker-compose restart <service_name>
```

### Remove and Recreate Service
```bash
docker-compose rm -f <service_name>
docker-compose up -d <service_name>
```

### Check Network Connectivity
```bash
docker exec jenkins ping nexus
```

## Production Considerations

### Security
1. Change all default passwords
2. Enable SSL/TLS for all services
3. Use secrets management (Vault)
4. Implement network segmentation
5. Enable audit logging

### Performance
1. Allocate sufficient resources
2. Configure persistent storage
3. Set up log rotation
4. Monitor resource usage
5. Implement caching

### High Availability
1. Use external databases
2. Configure load balancing
3. Implement backup strategy
4. Set up monitoring and alerting
5. Document disaster recovery procedures

## Updating Services

### Update Single Service
```bash
docker-compose pull <service_name>
docker-compose up -d <service_name>
```

### Update All Services
```bash
docker-compose pull
docker-compose up -d
```

## Clean Up

### Remove Unused Resources
```bash
docker system prune -a --volumes
```

### Remove Specific Service
```bash
docker-compose rm -f -s -v <service_name>
```
