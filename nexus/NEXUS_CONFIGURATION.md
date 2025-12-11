# Nexus Repository Manager Configuration

## Overview
This document describes the Nexus repository configuration for managing artifacts across different environments (QA, Staging, Production) with proper access controls.

## Repository Structure

### Maven Repositories

#### 1. maven-qa (Hosted Repository)
**Purpose**: Store QA environment artifacts
**Type**: Hosted
**Version Policy**: Mixed (Snapshot + Release)
**Deployment Policy**: Allow Redeploy
**Access**:
- Read: developers, qa-team, implementacion
- Write: developers, implementacion
- Deploy: CI/CD pipelines (QA)

**Configuration**:
```json
{
  "name": "maven-qa",
  "type": "hosted",
  "format": "maven2",
  "storage": {
    "blobStoreName": "qa-storage",
    "strictContentTypeValidation": true,
    "writePolicy": "ALLOW_ONCE"
  },
  "cleanup": {
    "policyNames": ["cleanup-qa-snapshots"]
  },
  "maven": {
    "versionPolicy": "MIXED",
    "layoutPolicy": "STRICT"
  }
}
```

#### 2. maven-staging (Hosted Repository)
**Purpose**: Store staging environment artifacts
**Type**: Hosted
**Version Policy**: Release
**Deployment Policy**: Disable Redeploy
**Access**:
- Read: implementacion, qa-team
- Write: implementacion
- Deploy: CI/CD pipelines (Staging)

**Configuration**:
```json
{
  "name": "maven-staging",
  "type": "hosted",
  "format": "maven2",
  "storage": {
    "blobStoreName": "staging-storage",
    "strictContentTypeValidation": true,
    "writePolicy": "ALLOW_ONCE"
  },
  "cleanup": {
    "policyNames": ["cleanup-staging-old-releases"]
  },
  "maven": {
    "versionPolicy": "RELEASE",
    "layoutPolicy": "STRICT"
  }
}
```

#### 3. maven-production (Hosted Repository)
**Purpose**: Store production-ready artifacts
**Type**: Hosted
**Version Policy**: Release
**Deployment Policy**: Disable Redeploy (Immutable)
**Access**:
- Read: implementacion only
- Write: implementacion only
- Deploy: CI/CD pipelines (Production) with approval

**Configuration**:
```json
{
  "name": "maven-production",
  "type": "hosted",
  "format": "maven2",
  "storage": {
    "blobStoreName": "production-storage",
    "strictContentTypeValidation": true,
    "writePolicy": "ALLOW_ONCE"
  },
  "cleanup": {
    "policyNames": ["cleanup-production-very-old"]
  },
  "maven": {
    "versionPolicy": "RELEASE",
    "layoutPolicy": "STRICT"
  }
}
```

#### 4. maven-proxy (Proxy Repository)
**Purpose**: Proxy to Maven Central
**Type**: Proxy
**Remote URL**: https://repo1.maven.org/maven2/
**Access**: All authenticated users (read-only)

**Configuration**:
```json
{
  "name": "maven-central-proxy",
  "type": "proxy",
  "format": "maven2",
  "proxy": {
    "remoteUrl": "https://repo1.maven.org/maven2/",
    "contentMaxAge": 1440,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true
  },
  "storage": {
    "blobStoreName": "proxy-storage",
    "strictContentTypeValidation": true
  }
}
```

#### 5. maven-group (Group Repository)
**Purpose**: Aggregate all Maven repositories
**Type**: Group
**Members**: maven-qa, maven-staging, maven-production, maven-central-proxy

**Configuration**:
```json
{
  "name": "maven-all",
  "type": "group",
  "format": "maven2",
  "group": {
    "memberNames": [
      "maven-production",
      "maven-staging",
      "maven-qa",
      "maven-central-proxy"
    ]
  },
  "storage": {
    "blobStoreName": "default"
  }
}
```

## Access Control

### Roles and Privileges

#### 1. nexus-qa-developer
**Privileges**:
- nx-repository-view-maven2-maven-qa-browse
- nx-repository-view-maven2-maven-qa-read
- nx-repository-view-maven2-maven-qa-edit
- nx-repository-view-maven2-maven-qa-add
- nx-repository-view-maven2-maven-central-proxy-browse
- nx-repository-view-maven2-maven-central-proxy-read

#### 2. nexus-staging-deployer
**Privileges**:
- nx-repository-view-maven2-maven-staging-*
- nx-repository-view-maven2-maven-qa-read
- nx-repository-view-maven2-maven-central-proxy-read

#### 3. nexus-production-deployer
**Privileges**:
- nx-repository-view-maven2-maven-production-*
- nx-repository-admin-maven2-maven-production-*

#### 4. nexus-implementacion-admin
**Privileges**:
- nx-all (Full access to all repositories)

### User Groups

#### developers-group
**Members**: Development team
**Roles**: nexus-qa-developer

#### implementacion-group
**Members**: Implementation/DevOps team
**Roles**: nexus-implementacion-admin, nexus-staging-deployer, nexus-production-deployer

#### ci-cd-group
**Members**: Jenkins/GitLab CI service accounts
**Roles**: Environment-specific deployer roles

## Blob Stores

### Storage Configuration
```
/opt/sonatype-work/nexus3/blobs/
├── qa-storage/          # QA artifacts
├── staging-storage/     # Staging artifacts
├── production-storage/  # Production artifacts
└── proxy-storage/       # Cached proxy artifacts
```

### Blob Store Quotas
- **qa-storage**: 50 GB soft limit
- **staging-storage**: 100 GB soft limit
- **production-storage**: 200 GB soft limit
- **proxy-storage**: 100 GB soft limit

## Cleanup Policies

### cleanup-qa-snapshots
**Criteria**:
- Remove snapshots older than 30 days
- Keep last 5 versions

### cleanup-staging-old-releases
**Criteria**:
- Remove releases older than 90 days
- Keep last 10 versions

### cleanup-production-very-old
**Criteria**:
- Remove releases older than 365 days
- Keep last 20 versions
- Never delete tagged releases

## Maven Settings Configuration

### settings.xml for QA Environment
```xml
<settings>
  <servers>
    <server>
      <id>nexus-qa</id>
      <username>${env.NEXUS_USER}</username>
      <password>${env.NEXUS_PASSWORD}</password>
    </server>
  </servers>
  
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>https://nexus.company.com/repository/maven-all/</url>
    </mirror>
  </mirrors>
  
  <profiles>
    <profile>
      <id>nexus-qa</id>
      <repositories>
        <repository>
          <id>nexus-qa</id>
          <url>https://nexus.company.com/repository/maven-qa/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>
  
  <activeProfiles>
    <activeProfile>nexus-qa</activeProfile>
  </activeProfiles>
</settings>
```

### settings.xml for Production Environment
```xml
<settings>
  <servers>
    <server>
      <id>nexus-production</id>
      <username>${env.NEXUS_PROD_USER}</username>
      <password>${env.NEXUS_PROD_PASSWORD}</password>
    </server>
  </servers>
  
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>https://nexus.company.com/repository/maven-all/</url>
    </mirror>
  </mirrors>
  
  <profiles>
    <profile>
      <id>nexus-production</id>
      <repositories>
        <repository>
          <id>nexus-production</id>
          <url>https://nexus.company.com/repository/maven-production/</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>false</enabled></snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>
  
  <activeProfiles>
    <activeProfile>nexus-production</activeProfile>
  </activeProfiles>
</settings>
```

## Deployment Configuration in pom.xml

```xml
<distributionManagement>
  <repository>
    <id>nexus-releases</id>
    <name>Nexus Release Repository</name>
    <url>https://nexus.company.com/repository/maven-${environment}/</url>
  </repository>
  <snapshotRepository>
    <id>nexus-snapshots</id>
    <name>Nexus Snapshot Repository</name>
    <url>https://nexus.company.com/repository/maven-${environment}/</url>
  </snapshotRepository>
</distributionManagement>
```

## Security Best Practices

1. **Authentication**: Use LDAP/AD integration for user authentication
2. **Authorization**: Role-based access control (RBAC)
3. **Credentials**: Store in Vault, never in code
4. **SSL/TLS**: Enable HTTPS for all connections
5. **Audit**: Enable audit logging for all repository operations
6. **Backup**: Daily automated backups of blob stores and configuration

## Monitoring and Alerts

### Nexus Metrics to Monitor
- Repository storage usage
- Number of artifacts per repository
- Download/upload statistics
- Failed authentication attempts
- API usage patterns

### Alerting Thresholds
- Blob store > 80% capacity
- More than 10 failed auth attempts per hour
- Unusual upload patterns to production repository

## Backup and Disaster Recovery

### Backup Strategy
```bash
# Daily backup script
#!/bin/bash
BACKUP_DIR="/backup/nexus/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup blob stores
rsync -av /opt/sonatype-work/nexus3/blobs/ $BACKUP_DIR/blobs/

# Backup configuration
tar czf $BACKUP_DIR/nexus-config.tar.gz /opt/sonatype-work/nexus3/etc/

# Backup database
pg_dump nexus > $BACKUP_DIR/nexus-db.sql

# Retention: Keep last 30 days
find /backup/nexus/ -type d -mtime +30 -exec rm -rf {} \;
```

### Recovery Procedure
1. Install Nexus Repository Manager
2. Restore blob stores from backup
3. Restore configuration files
4. Restore database
5. Start Nexus service
6. Verify repository accessibility
7. Test artifact retrieval

## API Usage Examples

### Upload Artifact via API
```bash
curl -v -u $NEXUS_USER:$NEXUS_PASSWORD \
  --upload-file myapp-1.0.0.war \
  "https://nexus.company.com/repository/maven-qa/com/company/myapp/1.0.0/myapp-1.0.0.war"
```

### Search for Artifacts
```bash
curl -u $NEXUS_USER:$NEXUS_PASSWORD \
  "https://nexus.company.com/service/rest/v1/search?repository=maven-qa&name=myapp"
```

### Delete Old Snapshots
```bash
curl -X DELETE -u $NEXUS_USER:$NEXUS_PASSWORD \
  "https://nexus.company.com/service/rest/v1/components/{componentId}"
```
