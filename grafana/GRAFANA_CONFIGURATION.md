# Grafana Dashboard Configuration for CI/CD Monitoring

## Overview
This document describes Grafana dashboard configurations for monitoring CI/CD pipelines, deployments, and application health.

## Dashboard Structure

### 1. CI/CD Pipeline Metrics Dashboard

**Dashboard Name**: `cicd-pipeline-metrics`
**Data Source**: Prometheus

#### Panels

##### Build Success Rate
```json
{
  "title": "Build Success Rate",
  "type": "stat",
  "targets": [
    {
      "expr": "sum(rate(jenkins_builds_success_total[24h])) / sum(rate(jenkins_builds_total[24h])) * 100",
      "legendFormat": "Success Rate %"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "thresholds": {
        "steps": [
          { "value": 0, "color": "red" },
          { "value": 80, "color": "yellow" },
          { "value": 95, "color": "green" }
        ]
      }
    }
  }
}
```

##### Build Duration
```json
{
  "title": "Average Build Duration",
  "type": "graph",
  "targets": [
    {
      "expr": "avg(jenkins_build_duration_milliseconds{job=~\".*\"}) / 1000",
      "legendFormat": "{{job}}"
    }
  ],
  "yaxes": [
    {
      "format": "s",
      "label": "Duration"
    }
  ]
}
```

##### Deployment Frequency
```json
{
  "title": "Deployments by Environment",
  "type": "graph",
  "targets": [
    {
      "expr": "sum(rate(deployment_total[1h])) by (environment)",
      "legendFormat": "{{environment}}"
    }
  ]
}
```

##### Failed Builds
```json
{
  "title": "Recent Failed Builds",
  "type": "table",
  "targets": [
    {
      "expr": "jenkins_builds_failed_total",
      "instant": true,
      "format": "table"
    }
  ]
}
```

### 2. Application Performance Dashboard

**Dashboard Name**: `application-performance`
**Data Source**: Prometheus + Loki

#### Panels

##### HTTP Request Rate
```json
{
  "title": "HTTP Requests per Second",
  "type": "graph",
  "targets": [
    {
      "expr": "rate(http_requests_total[5m])",
      "legendFormat": "{{method}} {{path}}"
    }
  ]
}
```

##### Response Time
```json
{
  "title": "Response Time (95th percentile)",
  "type": "graph",
  "targets": [
    {
      "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
      "legendFormat": "p95"
    }
  ]
}
```

##### Error Rate
```json
{
  "title": "HTTP Error Rate",
  "type": "stat",
  "targets": [
    {
      "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100",
      "legendFormat": "Error Rate %"
    }
  ]
}
```

##### JVM Memory Usage
```json
{
  "title": "JVM Memory Usage",
  "type": "graph",
  "targets": [
    {
      "expr": "jvm_memory_used_bytes{area=\"heap\"}",
      "legendFormat": "Heap Used"
    },
    {
      "expr": "jvm_memory_max_bytes{area=\"heap\"}",
      "legendFormat": "Heap Max"
    }
  ]
}
```

### 3. Infrastructure Monitoring Dashboard

**Dashboard Name**: `infrastructure-health`
**Data Source**: Prometheus

#### Panels

##### CPU Usage
```json
{
  "title": "CPU Usage by Host",
  "type": "graph",
  "targets": [
    {
      "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
      "legendFormat": "{{instance}}"
    }
  ]
}
```

##### Memory Usage
```json
{
  "title": "Memory Usage",
  "type": "graph",
  "targets": [
    {
      "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
      "legendFormat": "{{instance}}"
    }
  ]
}
```

##### Disk Usage
```json
{
  "title": "Disk Usage",
  "type": "graph",
  "targets": [
    {
      "expr": "(node_filesystem_size_bytes{mountpoint=\"/\"} - node_filesystem_free_bytes{mountpoint=\"/\"}) / node_filesystem_size_bytes{mountpoint=\"/\"} * 100",
      "legendFormat": "{{instance}}"
    }
  ]
}
```

### 4. Security Scan Results Dashboard

**Dashboard Name**: `security-scan-results`
**Data Source**: Prometheus + SonarQube

#### Panels

##### Vulnerabilities by Severity
```json
{
  "title": "Vulnerabilities by Severity",
  "type": "bargauge",
  "targets": [
    {
      "expr": "sonarqube_vulnerabilities_total",
      "legendFormat": "{{severity}}"
    }
  ]
}
```

##### Code Coverage
```json
{
  "title": "Code Coverage",
  "type": "stat",
  "targets": [
    {
      "expr": "sonarqube_coverage_percentage",
      "legendFormat": "Coverage %"
    }
  ]
}
```

##### Technical Debt
```json
{
  "title": "Technical Debt",
  "type": "stat",
  "targets": [
    {
      "expr": "sonarqube_technical_debt_minutes",
      "legendFormat": "Minutes"
    }
  ]
}
```

## Alert Rules

### Critical Alerts

#### High Build Failure Rate
```yaml
- alert: HighBuildFailureRate
  expr: sum(rate(jenkins_builds_failed_total[1h])) / sum(rate(jenkins_builds_total[1h])) > 0.3
  for: 15m
  labels:
    severity: critical
  annotations:
    summary: "High build failure rate detected"
    description: "Build failure rate is {{ $value | humanizePercentage }}"
```

#### Production Deployment Failed
```yaml
- alert: ProductionDeploymentFailed
  expr: deployment_status{environment="production",status="failed"} > 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Production deployment failed"
    description: "Deployment to production failed for {{ $labels.job }}"
```

#### High Error Rate
```yaml
- alert: HighErrorRate
  expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.05
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High error rate detected"
    description: "Error rate is {{ $value | humanizePercentage }}"
```

#### Critical Vulnerability Detected
```yaml
- alert: CriticalVulnerability
  expr: sonarqube_vulnerabilities_total{severity="CRITICAL"} > 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Critical vulnerability detected"
    description: "{{ $value }} critical vulnerabilities found in {{ $labels.project }}"
```

## Notification Channels

### Email Notifications
```yaml
contact_points:
  - name: email-ops
    email_configs:
      - to: ops@company.com
        from: grafana@company.com
        smarthost: smtp.company.com:587
        auth_username: grafana@company.com
        auth_password: ${SMTP_PASSWORD}
```

### Slack Notifications
```yaml
contact_points:
  - name: slack-alerts
    slack_configs:
      - api_url: ${SLACK_WEBHOOK_URL}
        channel: '#alerts'
        title: 'Grafana Alert'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}'
```

### Teams Notifications
```yaml
contact_points:
  - name: teams-alerts
    webhook_configs:
      - url: ${TEAMS_WEBHOOK_URL}
        send_resolved: true
```

## Dashboard JSON Templates

### Export Command
```bash
# Export dashboard
curl -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  "http://grafana.company.com/api/dashboards/uid/cicd-pipeline-metrics" \
  > dashboard-export.json

# Import dashboard
curl -X POST -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @dashboard-export.json \
  "http://grafana.company.com/api/dashboards/db"
```

## Provisioning Configuration

### Dashboard Provisioning
File: `grafana/provisioning/dashboards/dashboards.yml`
```yaml
apiVersion: 1

providers:
  - name: 'CI/CD Dashboards'
    orgId: 1
    folder: 'CI/CD'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

### Data Source Provisioning
File: `grafana/provisioning/datasources/datasources.yml`
```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    
  - name: SonarQube
    type: sonarqube-datasource
    access: proxy
    url: http://sonarqube:9000
    secureJsonData:
      token: ${SONARQUBE_TOKEN}
```

## User Management

### Create Admin User
```bash
docker exec -it grafana grafana-cli admin reset-admin-password newpassword
```

### Create API Key
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"name":"ci-cd-integration","role":"Editor"}' \
  http://admin:password@grafana.company.com/api/auth/keys
```

## Backup and Restore

### Backup Grafana
```bash
#!/bin/bash
# Backup Grafana dashboards and configuration

BACKUP_DIR="/backup/grafana/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup dashboards
curl -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  "http://grafana.company.com/api/search?type=dash-db" | \
  jq -r '.[] | .uid' | \
  while read uid; do
    curl -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
      "http://grafana.company.com/api/dashboards/uid/${uid}" \
      > "${BACKUP_DIR}/${uid}.json"
  done

# Backup configuration
tar czf ${BACKUP_DIR}/grafana-config.tar.gz /etc/grafana/
```

### Restore Grafana
```bash
#!/bin/bash
# Restore Grafana dashboards

BACKUP_DIR=$1

for dashboard in ${BACKUP_DIR}/*.json; do
  curl -X POST -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
    -H "Content-Type: application/json" \
    -d @${dashboard} \
    "http://grafana.company.com/api/dashboards/db"
done
```
