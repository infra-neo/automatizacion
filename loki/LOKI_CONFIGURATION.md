# Loki Logging Configuration

## Overview
Loki is used for centralized log aggregation and querying across all environments.

## Loki Configuration

### loki-config.yml
```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 1h
  max_chunk_age: 1h
  chunk_target_size: 1048576
  chunk_retain_period: 30s
  max_transfer_retries: 0

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/boltdb-shipper-active
    cache_location: /loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /loki/chunks

compactor:
  working_directory: /loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 32

chunk_store_config:
  max_look_back_period: 0s

table_manager:
  retention_deletes_enabled: true
  retention_period: 720h  # 30 days

ruler:
  storage:
    type: local
    local:
      directory: /loki/rules
  rule_path: /loki/rules-temp
  alertmanager_url: http://alertmanager:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
```

## Promtail Configuration

### promtail-config.yml
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  # Jenkins logs
  - job_name: jenkins
    static_configs:
      - targets:
          - localhost
        labels:
          job: jenkins
          environment: ${ENVIRONMENT}
          __path__: /var/log/jenkins/*.log

  # Application logs
  - job_name: application
    static_configs:
      - targets:
          - localhost
        labels:
          job: application
          environment: ${ENVIRONMENT}
          __path__: /var/log/wildfly/*.log

  # System logs
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: system
          environment: ${ENVIRONMENT}
          __path__: /var/log/*.log

  # CI/CD pipeline logs
  - job_name: cicd
    static_configs:
      - targets:
          - localhost
        labels:
          job: cicd
          environment: ${ENVIRONMENT}
          __path__: /var/log/cicd/*.log

  # Audit logs
  - job_name: audit
    static_configs:
      - targets:
          - localhost
        labels:
          job: audit
          environment: ${ENVIRONMENT}
          __path__: /var/log/audit/*.log
```

## LogQL Queries

### Common Queries

#### View All Logs for Environment
```logql
{environment="production"}
```

#### Filter by Job
```logql
{job="application"} |= "ERROR"
```

#### Count Errors in Last Hour
```logql
count_over_time({job="application"} |= "ERROR" [1h])
```

#### Failed Deployments
```logql
{job="cicd"} |= "deployment" |= "failed"
```

#### Performance Issues
```logql
{job="application"} |~ "took [0-9]+ms" | regexp "took (?P<duration>[0-9]+)ms" | duration > 1000
```

#### Security Events
```logql
{job="audit"} |= "authentication" |= "failed"
```

### Advanced Queries

#### Rate of Errors
```logql
rate({job="application"} |= "ERROR" [5m])
```

#### Top 10 Error Messages
```logql
topk(10, count_over_time({job="application"} |= "ERROR" [1h]))
```

#### Deployment Timeline
```logql
{job="cicd"} |= "deployment" | json | line_format "{{.timestamp}} - {{.environment}} - {{.status}}"
```

## Alert Rules

### loki-rules.yml
```yaml
groups:
  - name: cicd_alerts
    interval: 1m
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate({job="application"} |= "ERROR" [5m])) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High error rate detected"
          description: "Error rate is above threshold"

      - alert: DeploymentFailed
        expr: |
          count_over_time({job="cicd"} |= "deployment" |= "failed" [5m]) > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Deployment failure detected"
          description: "A deployment has failed"

      - alert: SecurityBreach
        expr: |
          count_over_time({job="audit"} |= "authentication" |= "failed" [5m]) > 5
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Multiple failed authentication attempts"
          description: "Possible security breach detected"

      - alert: HighMemoryUsage
        expr: |
          count_over_time({job="application"} |= "OutOfMemoryError" [5m]) > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Out of memory error detected"
          description: "Application experiencing memory issues"
```

## Integration with Grafana

### Add Loki Data Source
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${GRAFANA_API_KEY}" \
  -d '{
    "name": "Loki",
    "type": "loki",
    "url": "http://loki:3100",
    "access": "proxy",
    "isDefault": false
  }' \
  http://grafana:3000/api/datasources
```

### Explore Logs in Grafana
1. Navigate to Explore
2. Select Loki data source
3. Enter LogQL query
4. View results in log panel

## Log Retention

### Retention Policy
```yaml
# In loki-config.yml
table_manager:
  retention_deletes_enabled: true
  retention_period: 720h  # 30 days for all environments

# Environment-specific retention
limits_config:
  per_tenant_override_config: /etc/loki/overrides.yml
```

### overrides.yml
```yaml
overrides:
  production:
    retention_period: 2160h  # 90 days
  staging:
    retention_period: 720h   # 30 days
  qa:
    retention_period: 168h   # 7 days
```

## Log Parsing and Processing

### Parse JSON Logs
```logql
{job="application"} | json | line_format "{{.level}} - {{.message}}"
```

### Extract Fields with Regex
```logql
{job="application"} | regexp "User (?P<user>[a-zA-Z0-9]+) logged in"
```

### Filter by Parsed Field
```logql
{job="application"} | json | severity="ERROR"
```

## Performance Tuning

### Optimization Tips
1. Use label selectors efficiently
2. Limit time range for queries
3. Use filters before parsing
4. Index important labels
5. Configure appropriate retention

### Query Performance
```logql
# Good - Filter first, then parse
{job="application"} |= "ERROR" | json

# Bad - Parse all logs first
{job="application"} | json | severity="ERROR"
```

## Backup and Restore

### Backup Script
```bash
#!/bin/bash
BACKUP_DIR="/backup/loki/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# Backup chunks and index
tar czf $BACKUP_DIR/loki-data.tar.gz /loki/

# Backup configuration
cp /etc/loki/loki-config.yml $BACKUP_DIR/
```

### Restore Script
```bash
#!/bin/bash
BACKUP_DIR=$1

# Stop Loki
systemctl stop loki

# Restore data
tar xzf $BACKUP_DIR/loki-data.tar.gz -C /

# Restore configuration
cp $BACKUP_DIR/loki-config.yml /etc/loki/

# Start Loki
systemctl start loki
```

## Monitoring Loki

### Metrics to Monitor
- `loki_ingester_chunks_created_total`
- `loki_ingester_chunks_stored_total`
- `loki_request_duration_seconds`
- `loki_panic_total`

### Prometheus Scrape Config
```yaml
scrape_configs:
  - job_name: loki
    static_configs:
      - targets:
          - loki:3100
```

## Security

### Enable Authentication
```yaml
# loki-config.yml
auth_enabled: true

# Configure multi-tenancy
server:
  http_listen_port: 3100
  grpc_listen_port: 9096
```

### TLS Configuration
```yaml
server:
  http_tls_config:
    cert_file: /etc/loki/tls/cert.pem
    key_file: /etc/loki/tls/key.pem
  grpc_tls_config:
    cert_file: /etc/loki/tls/cert.pem
    key_file: /etc/loki/tls/key.pem
```
