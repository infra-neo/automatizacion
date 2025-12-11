# SonarQube Configuration for CI/CD

## Overview
SonarQube provides continuous inspection of code quality and security for Java applications.

## Installation and Setup

### Using Docker
```bash
# Already included in docker-compose.yml
docker-compose up -d sonarqube
```

### Access SonarQube
- **URL**: http://localhost:9000
- **Default credentials**: admin/admin (change on first login)

## Initial Configuration

### 1. Create Quality Gate
```bash
# Login to SonarQube
# Navigate to Quality Gates → Create

# Set conditions:
# - Bugs: 0 (on new code)
# - Vulnerabilities: 0 (on new code)
# - Security Hotspots: Review required
# - Code Coverage: >= 80% (on new code)
# - Duplicated Lines: <= 3% (on new code)
# - Maintainability Rating: A (on new code)
# - Reliability Rating: A (on new code)
# - Security Rating: A (on new code)
```

### 2. Create Authentication Token
```bash
# For CI/CD integration
curl -u admin:newpassword -X POST \
  "http://localhost:9000/api/user_tokens/generate?name=ci-cd-token"
```

### 3. Configure Projects
```bash
# Create project
curl -u admin:newpassword -X POST \
  "http://localhost:9000/api/projects/create?name=my-app&project=my-app"

# Set quality gate
curl -u admin:newpassword -X POST \
  "http://localhost:9000/api/qualitygates/select?projectKey=my-app&gateId=1"
```

## Maven Integration

### pom.xml Configuration
```xml
<properties>
  <sonar.projectKey>my-app</sonar.projectKey>
  <sonar.projectName>My Application</sonar.projectName>
  <sonar.host.url>http://sonarqube:9000</sonar.host.url>
  <sonar.login>${env.SONAR_TOKEN}</sonar.login>
  
  <!-- Code Coverage -->
  <sonar.coverage.jacoco.xmlReportPaths>
    target/site/jacoco/jacoco.xml
  </sonar.coverage.jacoco.xmlReportPaths>
  
  <!-- Exclusions -->
  <sonar.exclusions>
    **/test/**,
    **/generated/**,
    **/*Test.java
  </sonar.exclusions>
</properties>

<build>
  <plugins>
    <plugin>
      <groupId>org.sonarsource.scanner.maven</groupId>
      <artifactId>sonar-maven-plugin</artifactId>
      <version>3.9.1.2184</version>
    </plugin>
  </plugins>
</build>
```

### Run Analysis
```bash
# Local analysis
mvn clean verify sonar:sonar \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=your-token

# In pipeline (uses env vars)
mvn sonar:sonar
```

## Quality Profiles

### Java Quality Profile
```yaml
# Custom rules for Java applications
rules:
  # Security
  - squid:S2068  # Hardcoded credentials
  - squid:S2658  # SSRF vulnerabilities
  - squid:S3649  # SQL injection
  - squid:S5145  # Logging sensitive data
  
  # Code Smells
  - squid:S1172  # Unused parameters
  - squid:S1481  # Unused local variables
  - squid:S1186  # Empty methods
  
  # Bugs
  - squid:S2259  # NullPointerException
  - squid:S2095  # Resource leak
  - squid:S2629  # Logging performance
```

## Integration with CI/CD

### GitLab CI
```yaml
sonarqube-check:
  stage: security-scan
  image: maven:3.9-openjdk-17
  script:
    - mvn verify sonar:sonar
        -Dsonar.projectKey=$CI_PROJECT_NAME
        -Dsonar.host.url=$SONAR_HOST_URL
        -Dsonar.login=$SONAR_TOKEN
  only:
    - merge_requests
    - main
```

### Jenkins
```groovy
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh 'mvn sonar:sonar'
        }
    }
}

stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

## Webhooks

### Configure Webhook for Notifications
```bash
curl -u admin:password -X POST \
  "http://localhost:9000/api/webhooks/create" \
  -d "name=Jenkins" \
  -d "url=http://jenkins:8080/sonarqube-webhook/"
```

## Quality Gate Reports

### View in SonarQube
- Navigate to project dashboard
- View quality gate status
- Review issues by severity
- Check code coverage trends

### Export Reports
```bash
# Get quality gate status
curl -u token: \
  "http://localhost:9000/api/qualitygates/project_status?projectKey=my-app"

# Get metrics
curl -u token: \
  "http://localhost:9000/api/measures/component?component=my-app&metricKeys=bugs,vulnerabilities,code_smells,coverage"
```

## Security Hotspots

### Review Process
1. Navigate to Security Hotspots
2. Review each hotspot
3. Mark as Safe or To Fix
4. Document decision
5. Fix if necessary

### Common Security Issues
- Hardcoded credentials
- SQL injection risks
- XSS vulnerabilities
- Insecure random generators
- Weak cryptography

## Monitoring

### Metrics to Track
- Overall quality gate status
- New issues per build
- Code coverage trends
- Technical debt ratio
- Security hotspots count

### Prometheus Integration
```yaml
# sonarqube-exporter configuration
scrape_configs:
  - job_name: 'sonarqube'
    static_configs:
      - targets: ['sonarqube-exporter:9119']
```

## Best Practices

1. **Fix Issues Early**: Address issues in development
2. **Maintain Coverage**: Keep code coverage above 80%
3. **Review Security Hotspots**: Never ignore security issues
4. **Use Quality Gates**: Fail builds on quality gate failures
5. **Regular Updates**: Keep SonarQube and plugins updated
6. **Custom Rules**: Create project-specific rules
7. **Documentation**: Document suppressions and exceptions

## Troubleshooting

### Analysis Fails
```bash
# Enable debug logging
mvn sonar:sonar -X -Dsonar.verbose=true
```

### Quality Gate Not Updating
```bash
# Check webhook configuration
# Verify SonarQube can reach Jenkins/GitLab
# Review SonarQube logs
docker logs sonarqube
```

### High Memory Usage
```bash
# Increase SonarQube memory in docker-compose.yml
SONAR_WEB_JAVAOPTS: "-Xmx2g -Xms512m"
```

## Backup and Restore

### Backup
```bash
# Backup database
docker exec sonarqube-db pg_dump -U sonar sonar > sonar-backup.sql

# Backup data directory
docker run --rm \
  -v sonarqube_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/sonarqube-data.tar.gz -C /data .
```

### Restore
```bash
# Restore database
docker exec -i sonarqube-db psql -U sonar sonar < sonar-backup.sql

# Restore data
docker run --rm \
  -v sonarqube_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/sonarqube-data.tar.gz -C /data
```
