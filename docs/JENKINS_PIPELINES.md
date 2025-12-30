# Jenkins Pipelines Documentation

## Overview

This document describes the Jenkins pipelines available for configuration validation and application deployment.

## Available Pipelines

### 1. Rsyslog Validation Pipeline

**File:** `jenkins/Jenkinsfile-rsyslog-validation`

**Purpose:** Validates rsyslog configuration across managed hosts

**Parameters:**
- `ENVIRONMENT`: Target environment (qa/staging/production)
- `TARGET_HOSTS`: Target hosts or group (default: all)
- `RUN_VALIDATION`: Run validation after configuration (default: true)

**Stages:**
1. **Prepare Environment** - Set up workspace and reports directory
2. **Validate Rsyslog Configuration** - Run validation playbook
3. **Check Configuration Syntax** - Verify rsyslog syntax
4. **Verify Service Status** - Check rsyslog service state
5. **Generate Validation Report** - Create detailed report
6. **Collect Metrics** - Gather service metrics

**Usage:**

1. **Create Jenkins Job:**
```groovy
// In Jenkins UI:
New Item > Pipeline
Name: rsyslog-validation
Pipeline script from SCM
SCM: Git
Repository: https://github.com/infra-neo/automatizacion
Script Path: jenkins/Jenkinsfile-rsyslog-validation
```

2. **Run Pipeline:**
```bash
# Via Jenkins UI
Build with Parameters > Select Environment > Build

# Via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080 build rsyslog-validation \
  -p ENVIRONMENT=qa \
  -p TARGET_HOSTS=webservers
```

3. **Expected Output:**
```
Stage: Validate Rsyslog Configuration
✓ Package installed
✓ Service running
✓ Configuration valid
✓ Test message delivered

Stage: Generate Validation Report
Report saved to: reports/rsyslog-validation-qa-20231218.txt
```

**Screenshots:** `docs/screenshots/jenkins/rsyslog-validation/`

### 2. Logrotate Validation Pipeline

**File:** `jenkins/Jenkinsfile-logrotate-validation`

**Purpose:** Validates logrotate configuration and tests log rotation

**Parameters:**
- `ENVIRONMENT`: Target environment (qa/staging/production)
- `TARGET_HOSTS`: Target hosts or group (default: all)
- `RUN_TEST_ROTATION`: Run test log rotation (default: true)

**Stages:**
1. **Prepare Environment** - Set up workspace
2. **Validate Logrotate Configuration** - Run validation playbook
3. **Test Logrotate Dry Run** - Test configuration without actual rotation
4. **Check Rotated Logs** - Count existing rotated logs
5. **Verify Disk Space** - Check available disk space
6. **Test Rotation** - Perform actual test rotation
7. **Generate Validation Report** - Create detailed report

**Usage:**

1. **Create Jenkins Job:**
```groovy
// In Jenkins UI:
New Item > Pipeline
Name: logrotate-validation
Pipeline script from SCM
Script Path: jenkins/Jenkinsfile-logrotate-validation
```

2. **Run Pipeline:**
```bash
# Via Jenkins UI
Build with Parameters > Configure options > Build

# Via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080 build logrotate-validation \
  -p ENVIRONMENT=staging \
  -p RUN_TEST_ROTATION=true
```

3. **Expected Output:**
```
Stage: Validate Logrotate Configuration
✓ Package installed
✓ Configuration valid
✓ Cron configured

Stage: Test Rotation
✓ Test rotation successful
Found 15 rotated log files
Disk space: 75% available
```

**Screenshots:** `docs/screenshots/jenkins/logrotate-validation/`

### 3. Wildfly Deployment Pipeline

**File:** `jenkins/Jenkinsfile-wildfly-deployment`

**Purpose:** Deploys Java applications to Wildfly application server

**Parameters:**
- `ENVIRONMENT`: Deployment environment (qa/staging/production)
- `ARTIFACT_VERSION`: Version of artifact to deploy (default: latest)
- `WILDFLY_HOST`: Wildfly server hostname (default: wildfly)
- `WILDFLY_PORT`: Wildfly management port (default: 9990)
- `BACKUP_EXISTING`: Backup existing deployment (default: true)
- `RUN_HEALTH_CHECK`: Run health check after deployment (default: true)

**Stages:**
1. **Validate Parameters** - Check deployment parameters
2. **Download Artifact from Nexus** - Fetch WAR file from Nexus
3. **Backup Existing Deployment** - Backup current deployment
4. **Deploy to Wildfly** - Deploy application to server
5. **Wait for Deployment** - Allow deployment to stabilize
6. **Health Check** - Verify application is running
7. **Verify Deployment** - Check deployment status
8. **Generate Deployment Report** - Create detailed report

**Required Credentials:**
- `wildfly-admin-user`: Wildfly admin username
- `wildfly-admin-password`: Wildfly admin password
- `nexus-credentials`: Nexus repository credentials

**Usage:**

1. **Create Jenkins Job:**
```groovy
// In Jenkins UI:
New Item > Pipeline
Name: wildfly-deployment
Pipeline script from SCM
Script Path: jenkins/Jenkinsfile-wildfly-deployment
```

2. **Configure Credentials:**
```bash
# In Jenkins > Manage Jenkins > Credentials
Add:
- Username/Password: wildfly-admin-user / wildfly-admin-password
- Username/Password: nexus-credentials (for Nexus)
```

3. **Run Pipeline:**
```bash
# Via Jenkins UI
Build with Parameters > Select version and environment > Build

# Via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080 build wildfly-deployment \
  -p ENVIRONMENT=qa \
  -p ARTIFACT_VERSION=1.0.0 \
  -p WILDFLY_HOST=wildfly.company.com
```

4. **Expected Output:**
```
Stage: Download Artifact from Nexus
✓ Downloaded application-1.0.0.war (25MB)

Stage: Backup Existing Deployment
✓ Backup created: backups/app-20231218_153045.war

Stage: Deploy to Wildfly
✓ Application deployed successfully

Stage: Health Check
✓ HTTP 200 OK
✓ Application accessible

Stage: Generate Deployment Report
✓ Report: reports/deployment-report-qa-20231218_153045.txt
```

**Deployment Methods:**

The pipeline supports multiple deployment methods:

**Method 1: Wildfly CLI**
```bash
/opt/wildfly/bin/jboss-cli.sh --connect \
  --controller=wildfly:9990 \
  --command="deploy application.war --force"
```

**Method 2: Hot Deployment**
```bash
# Copy to deployments directory
cp application.war /opt/jboss/wildfly/standalone/deployments/
```

**Method 3: Using Deployment Script**
```bash
./scripts/deploy-to-wildfly.sh qa wildfly 9990
```

**Screenshots:** `docs/screenshots/jenkins/wildfly-deployment/`

## Pipeline Configuration

### Global Pipeline Libraries

Add shared pipeline libraries in Jenkins:

```groovy
// In Jenkinsfile
@Library('shared-pipeline-library') _

pipeline {
    agent any
    // ...
}
```

### Environment Variables

Configure in Jenkins > Manage Jenkins > Configure System:

```bash
NEXUS_URL=http://nexus:8081
ANSIBLE_HOST_KEY_CHECKING=false
ANSIBLE_FORCE_COLOR=true
```

### Credentials Configuration

Required credentials in Jenkins:

1. **wildfly-admin-user** (Username/Password)
   - Username: admin
   - Password: <wildfly-password>

2. **wildfly-admin-password** (Secret text)
   - Password: <wildfly-password>

3. **nexus-credentials** (Username/Password)
   - Username: <nexus-user>
   - Password: <nexus-password>

4. **config_env_secret** (Secret file)
   - File: config.env with environment variables

## Best Practices

### 1. Pipeline Naming
```groovy
// Use descriptive names
pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timestamps()
        timeout(time: 1, unit: 'HOURS')
    }
}
```

### 2. Error Handling
```groovy
post {
    failure {
        echo 'Pipeline failed'
        // Send notifications
        // Rollback if needed
    }
    always {
        // Clean workspace
        // Archive artifacts
    }
}
```

### 3. Approval Gates
```groovy
stage('Deploy to Production') {
    when {
        expression { params.ENVIRONMENT == 'production' }
    }
    steps {
        input message: 'Deploy to Production?', ok: 'Deploy'
        // Deployment steps
    }
}
```

### 4. Parallel Execution
```groovy
stage('Validation') {
    parallel {
        stage('Rsyslog') {
            steps {
                sh 'ansible-playbook validate-rsyslog.yml'
            }
        }
        stage('Logrotate') {
            steps {
                sh 'ansible-playbook validate-logrotate.yml'
            }
        }
    }
}
```

## Integration with Other Tools

### 1. Semaphore Integration
```groovy
stage('Trigger Semaphore Task') {
    steps {
        sh '''
            curl -X POST http://semaphore:3001/api/project/1/tasks \
                -H "Authorization: Bearer ${SEMAPHORE_TOKEN}" \
                -d '{"template_id": 1}'
        '''
    }
}
```

### 2. Grafana Annotations
```groovy
post {
    success {
        sh '''
            curl -X POST http://grafana:3000/api/annotations \
                -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
                -d '{
                    "text": "Deployment successful",
                    "tags": ["deployment", "success"]
                }'
        '''
    }
}
```

### 3. Slack Notifications
```groovy
post {
    always {
        slackSend(
            channel: '#deployments',
            color: currentBuild.result == 'SUCCESS' ? 'good' : 'danger',
            message: "Pipeline ${currentBuild.fullDisplayName} - ${currentBuild.result}"
        )
    }
}
```

## Monitoring and Metrics

### Pipeline Metrics

Jenkins collects metrics for:
- Build duration
- Success/failure rate
- Queue time
- Deployment frequency

Access metrics at:
- Jenkins Dashboard
- Prometheus: `jenkins_*` metrics
- Grafana: Jenkins dashboard

### Log Aggregation

Pipeline logs are forwarded to Loki:

```groovy
// Query in Grafana
{job="jenkins", pipeline="wildfly-deployment"}
```

## Troubleshooting

### Common Issues

#### 1. Ansible Connection Failures
```groovy
// Add debug output
environment {
    ANSIBLE_VERBOSE = '-vvv'
}
```

#### 2. Deployment Timeouts
```groovy
// Increase timeout
timeout(time: 2, unit: 'HOURS') {
    // Deployment steps
}
```

#### 3. Credential Issues
```bash
# Verify credentials in Jenkins
Manage Jenkins > Credentials > Test credential
```

#### 4. Docker Socket Permissions
```bash
# On Jenkins host
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## Security Considerations

### 1. Secrets Management
```groovy
// Use credentials binding
withCredentials([
    usernamePassword(
        credentialsId: 'wildfly-admin',
        usernameVariable: 'USER',
        passwordVariable: 'PASS'
    )
]) {
    // Use $USER and $PASS
}
```

### 2. Script Approval
```groovy
// In Jenkins > Manage Jenkins > In-process Script Approval
// Approve required methods
```

### 3. Pipeline Restrictions
```groovy
options {
    // Prevent concurrent builds
    disableConcurrentBuilds()
    // Limit build history
    buildDiscarder(logRotator(numToKeepStr: '30'))
}
```

## Pipeline Templates

### Basic Validation Pipeline
```groovy
pipeline {
    agent any
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['qa', 'staging', 'production'])
    }
    stages {
        stage('Validate') {
            steps {
                sh 'ansible-playbook validate.yml'
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'reports/**'
        }
    }
}
```

### Multi-Environment Deployment
```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            matrix {
                axes {
                    axis {
                        name 'ENVIRONMENT'
                        values 'qa', 'staging'
                    }
                }
                stages {
                    stage('Deploy to Environment') {
                        steps {
                            sh "deploy.sh ${ENVIRONMENT}"
                        }
                    }
                }
            }
        }
    }
}
```

## Testing Pipelines

### 1. Dry Run
```bash
# Test without executing
java -jar jenkins-cli.jar -s http://localhost:8080 replay-pipeline \
  rsyslog-validation \
  --dry-run
```

### 2. Syntax Validation
```groovy
// Use declarative linter
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                validateDeclarativePipeline()
            }
        }
    }
}
```

## Additional Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Ansible Integration](https://plugins.jenkins.io/ansible/)
- [Docker Integration](https://plugins.jenkins.io/docker-plugin/)
- [Wildfly Deployment](https://docs.wildfly.org/)
