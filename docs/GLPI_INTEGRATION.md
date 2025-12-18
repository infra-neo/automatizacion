# GLPI Integration Documentation

## Overview

GLPI (Gestionnaire Libre de Parc Informatique) is integrated into the infrastructure for IT asset management and inventory discovery. This document describes the setup, configuration, and integration with other systems.

## Architecture

```
┌─────────────────┐
│  Managed Hosts  │
│  (Servers)      │
└────────┬────────┘
         │ GLPI Agent
         │ (Inventory Data)
         ▼
┌─────────────────┐      ┌──────────────┐
│   GLPI Server   │◄────►│  MariaDB     │
│  (Port 8888)    │      │  Database    │
└────────┬────────┘      └──────────────┘
         │
         │ API/Reports
         ▼
┌─────────────────┐      ┌──────────────┐
│    Grafana      │◄────►│  Prometheus  │
│  (Dashboards)   │      │  (Metrics)   │
└─────────────────┘      └──────────────┘
```

## Installation and Setup

### 1. GLPI Server Deployment

The GLPI server is deployed via Docker Compose:

```yaml
# In docker/docker-compose.yml
glpi:
  image: diouxx/glpi:latest
  ports:
    - "8888:80"
  depends_on:
    - glpi-db

glpi-db:
  image: mariadb:10.11
  environment:
    - MYSQL_DATABASE=glpi
    - MYSQL_USER=glpi
    - MYSQL_PASSWORD=glpi
```

**Start GLPI:**
```bash
cd docker
docker-compose up -d glpi glpi-db
```

### 2. Initial GLPI Configuration

**Access GLPI:**
1. Navigate to http://localhost:8888
2. Select language
3. Accept license terms

**Database Configuration:**
- SQL Server: `glpi-db`
- SQL User: `glpi`
- SQL Password: `glpi`
- Database: `glpi`

**Default Credentials:**
- Super-Admin: `glpi/glpi`
- Admin: `tech/tech`
- Normal: `normal/normal`
- Post-only: `post-only/post-only`

**Important:** Change all default passwords immediately!

### 3. FusionInventory Plugin Installation

FusionInventory enables automatic inventory collection from GLPI agents.

**Install Plugin:**
1. Go to Setup > Plugins
2. Click "Install" on FusionInventory
3. Click "Enable" after installation
4. Configure plugin: Plugins > FusionInventory > Configuration

**Configuration:**
```
General:
- Server Path: /plugins/fusioninventory
- Agent Port: 62354

Inventory:
- Enable inventory: Yes
- Inventory frequency: 24 hours
- Store inventory data: Yes

Network Discovery:
- Enable: Yes
- Thread number: 4
```

### 4. GLPI Agent Deployment

Deploy GLPI agents to managed hosts using Ansible:

```bash
# Deploy to all hosts
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/glpi-agent/configure-glpi-agent.yml \
  -e "glpi_server=http://glpi:8888/plugins/fusioninventory"

# Deploy to specific group
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/glpi-agent/configure-glpi-agent.yml \
  --limit webservers \
  -e "glpi_server=http://glpi:8888/plugins/fusioninventory"
```

**Agent Configuration Variables:**
- `glpi_server`: GLPI server URL (default: https://glpi.company.com/plugins/fusioninventory)
- `glpi_interval`: Inventory interval in hours (default: 24)
- `glpi_debug`: Enable debug logging (default: false)

### 5. Verify Agent Registration

**Check in GLPI:**
1. Navigate to Plugins > FusionInventory > Agents
2. Verify agents are listed
3. Check last contact time
4. Review inventory data

**Force Manual Inventory:**
```bash
# On managed host
glpi-agent --server http://glpi:8888/plugins/fusioninventory --force

# Via Ansible
ansible all -i inventory -m shell \
  -a "glpi-agent --server http://glpi:8888/plugins/fusioninventory --force" \
  --become
```

## Inventory Management

### Asset Categories

GLPI tracks the following asset types:

1. **Computer Inventory:**
   - Hardware specifications (CPU, RAM, Disk)
   - Operating system details
   - Installed software
   - Network interfaces
   - Serial numbers

2. **Network Equipment:**
   - Switches, routers
   - Firewalls
   - Access points
   - Configuration details

3. **Software:**
   - Installed applications
   - Versions
   - Licenses
   - Installation dates

4. **Peripherals:**
   - Printers
   - Monitors
   - External devices

### Viewing Inventory

**Access Inventory:**
1. Navigate to Assets > Computers
2. Click on hostname to view details
3. Tabs available:
   - Main information
   - Components (Hardware)
   - Volumes (Disks)
   - Software
   - Network ports
   - History

**Export Inventory:**
```
Actions > Export > Select format (CSV, PDF, XML)
```

### Automated Discovery

**Network Discovery:**
1. Go to Plugins > FusionInventory > Network discovery
2. Create new IP range
3. Configure discovery options:
   - IP range: 192.168.1.0/24
   - SNMP credentials
   - Discovery schedule

**Agent-based Discovery:**
Agents automatically discover and report:
- Running processes
- Installed software
- System services
- Network connections
- Storage volumes

## Integration with Other Systems

### 1. Grafana Integration

Create Grafana dashboards to visualize GLPI inventory data.

**Setup MySQL Data Source in Grafana:**

```yaml
# In Grafana UI
Configuration > Data Sources > Add MySQL

Name: GLPI-MySQL
Host: glpi-db:3306
Database: glpi
User: glpi
Password: glpi
```

**Example Dashboard Queries:**

**Total Computers:**
```sql
SELECT COUNT(*) as count
FROM glpi_computers
WHERE is_deleted = 0 AND is_template = 0
```

**Computers by OS:**
```sql
SELECT 
    os.name as os_name,
    COUNT(*) as count
FROM glpi_computers c
JOIN glpi_operatingsystems os ON c.operatingsystems_id = os.id
WHERE c.is_deleted = 0
GROUP BY os.name
ORDER BY count DESC
```

**Software Installations:**
```sql
SELECT 
    s.name as software,
    COUNT(DISTINCT si.computers_id) as installs
FROM glpi_softwares s
JOIN glpi_softwareversions sv ON sv.softwares_id = s.id
JOIN glpi_items_softwareversions si ON si.softwareversions_id = sv.id
GROUP BY s.name
ORDER BY installs DESC
LIMIT 10
```

**Recent Inventory Updates:**
```sql
SELECT 
    c.name as hostname,
    c.last_inventory_update,
    TIMESTAMPDIFF(HOUR, c.last_inventory_update, NOW()) as hours_ago
FROM glpi_computers c
WHERE c.is_deleted = 0
ORDER BY c.last_inventory_update DESC
LIMIT 20
```

**Storage Usage:**
```sql
SELECT 
    c.name as hostname,
    SUM(d.totalsize) / 1024 as total_gb,
    SUM(d.freesize) / 1024 as free_gb,
    ((SUM(d.totalsize) - SUM(d.freesize)) / SUM(d.totalsize) * 100) as used_percent
FROM glpi_computers c
JOIN glpi_items_disks id ON id.items_id = c.id AND id.itemtype = 'Computer'
JOIN glpi_disks d ON d.id = id.disks_id
WHERE c.is_deleted = 0
GROUP BY c.name
ORDER BY used_percent DESC
```

**Create Dashboard:**
1. Create new dashboard in Grafana
2. Add panel with MySQL query
3. Configure visualization (Gauge, Graph, Table)
4. Set refresh interval
5. Save dashboard

### 2. Prometheus Metrics Export

Export GLPI metrics to Prometheus for monitoring.

**Install GLPI Exporter:**
```bash
# Custom exporter script
cat > /usr/local/bin/glpi-exporter.sh << 'EOF'
#!/bin/bash
# GLPI Metrics Exporter for Prometheus

# Database connection
DB_HOST="glpi-db"
DB_USER="glpi"
DB_PASS="glpi"
DB_NAME="glpi"

# Export metrics
echo "# HELP glpi_computers_total Total number of computers"
echo "# TYPE glpi_computers_total gauge"
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -N -e \
  "SELECT COUNT(*) FROM glpi_computers WHERE is_deleted=0" | \
  awk '{print "glpi_computers_total " $1}'

echo "# HELP glpi_inventory_age_hours Age of oldest inventory in hours"
echo "# TYPE glpi_inventory_age_hours gauge"
mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -N -e \
  "SELECT TIMESTAMPDIFF(HOUR, MIN(last_inventory_update), NOW()) FROM glpi_computers WHERE is_deleted=0" | \
  awk '{print "glpi_inventory_age_hours " $1}'
EOF

chmod +x /usr/local/bin/glpi-exporter.sh
```

**Configure in Prometheus:**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'glpi'
    static_configs:
      - targets: ['glpi:8888']
    metrics_path: '/metrics'
    scrape_interval: 5m
```

### 3. API Integration

GLPI provides a REST API for integration with other systems.

**Enable API:**
1. Setup > General > API
2. Enable REST API
3. Configure API clients
4. Generate API tokens

**API Examples:**

**Get All Computers:**
```bash
curl -X GET \
  'http://localhost:8888/apirest.php/Computer' \
  -H 'Session-Token: YOUR_SESSION_TOKEN' \
  -H 'App-Token: YOUR_APP_TOKEN'
```

**Get Specific Computer:**
```bash
curl -X GET \
  'http://localhost:8888/apirest.php/Computer/1' \
  -H 'Session-Token: YOUR_SESSION_TOKEN' \
  -H 'App-Token: YOUR_APP_TOKEN'
```

**Search Computers:**
```bash
curl -X GET \
  'http://localhost:8888/apirest.php/search/Computer?criteria[0][field]=1&criteria[0][searchtype]=contains&criteria[0][value]=web' \
  -H 'Session-Token: YOUR_SESSION_TOKEN'
```

**Python Integration Example:**
```python
import requests

class GLPIClient:
    def __init__(self, url, app_token, user_token):
        self.url = url
        self.app_token = app_token
        self.user_token = user_token
        self.session_token = None
    
    def init_session(self):
        headers = {
            'App-Token': self.app_token,
            'Authorization': f'user_token {self.user_token}'
        }
        response = requests.get(f'{self.url}/initSession', headers=headers)
        self.session_token = response.json()['session_token']
    
    def get_computers(self):
        headers = {
            'App-Token': self.app_token,
            'Session-Token': self.session_token
        }
        response = requests.get(f'{self.url}/Computer', headers=headers)
        return response.json()
    
    def kill_session(self):
        headers = {
            'App-Token': self.app_token,
            'Session-Token': self.session_token
        }
        requests.get(f'{self.url}/killSession', headers=headers)

# Usage
client = GLPIClient(
    'http://localhost:8888/apirest.php',
    'YOUR_APP_TOKEN',
    'YOUR_USER_TOKEN'
)
client.init_session()
computers = client.get_computers()
print(f"Found {len(computers)} computers")
client.kill_session()
```

## Reports and Analytics

### Built-in Reports

GLPI provides various built-in reports:

1. **Assets > Reports > Hardware Inventory**
   - Complete hardware inventory
   - Export to CSV/PDF

2. **Assets > Reports > Software Inventory**
   - Installed software by computer
   - License compliance

3. **Assets > Reports > Network Inventory**
   - Network equipment
   - Port usage
   - IP addresses

4. **Plugins > FusionInventory > Status**
   - Agent status
   - Last contact
   - Inventory statistics

### Custom Reports

Create custom reports using the search engine:

1. Navigate to Assets > Computers
2. Configure search criteria
3. Add display columns
4. Save search
5. Export results

**Example: Expiring Warranties**
```
Criteria:
- Warranty end date < Today + 30 days
- Status = In use

Display:
- Name
- Serial number
- Warranty end date
- Manufacturer
```

## Maintenance and Best Practices

### 1. Regular Database Maintenance

```bash
# Optimize GLPI database
docker exec glpi-db mysqlcheck -u glpi -pglpi --optimize glpi

# Backup database
docker exec glpi-db mysqldump -u glpi -pglpi glpi > glpi_backup_$(date +%Y%m%d).sql
```

### 2. Agent Health Monitoring

Create alerts for:
- Agents not reporting (> 48 hours)
- Failed inventory updates
- Agent version mismatches

```bash
# Check agent status via Ansible
ansible-playbook -i inventory \
  ansible-blueprints/glpi-agent/configure-glpi-agent.yml \
  --tags verify
```

### 3. Data Cleanup

Regularly clean up:
- Deleted computers (> 90 days)
- Old logs
- Unused software entries

```sql
-- In GLPI database
DELETE FROM glpi_computers WHERE is_deleted = 1 AND date_mod < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

### 4. Performance Tuning

**Database Optimization:**
```sql
-- Add indexes for common queries
CREATE INDEX idx_last_inventory ON glpi_computers(last_inventory_update);
CREATE INDEX idx_deleted ON glpi_computers(is_deleted, is_template);
```

**GLPI Configuration:**
- Enable caching
- Optimize FusionInventory settings
- Limit log retention

## Troubleshooting

### Common Issues

#### 1. Agent Not Reporting

**Check agent status:**
```bash
systemctl status glpi-agent
journalctl -u glpi-agent -n 50
```

**Test connectivity:**
```bash
glpi-agent --server http://glpi:8888/plugins/fusioninventory --debug
```

**Fix:**
- Verify GLPI server URL
- Check firewall rules
- Verify FusionInventory plugin is enabled

#### 2. Incomplete Inventory

**Possible causes:**
- Insufficient permissions
- Missing dependencies
- Agent timeout

**Solution:**
```bash
# Run with verbose logging
glpi-agent --server http://glpi:8888/plugins/fusioninventory --debug --force

# Check agent logs
tail -f /var/log/glpi-agent/glpi-agent.log
```

#### 3. Database Connection Issues

**Check database:**
```bash
docker exec glpi-db mysql -u glpi -pglpi -e "SELECT 1"
```

**Verify configuration:**
```bash
docker exec glpi cat /var/www/html/glpi/config/config_db.php
```

## Security Considerations

### 1. Authentication

- Change all default passwords
- Enable LDAP/AD integration
- Implement MFA if available
- Regular password rotation

### 2. Access Control

Configure appropriate permissions:
- Super-Admin: Infrastructure team only
- Admin: IT administrators
- Tech: Support team
- Normal: End users (limited)

### 3. API Security

- Use strong API tokens
- Rotate tokens regularly
- Limit API access by IP
- Monitor API usage

### 4. Data Protection

- Regular database backups
- Encrypt sensitive data
- Secure agent communication (HTTPS)
- Audit log monitoring

## Screenshots and Examples

Screenshots are available in:
- `docs/screenshots/glpi/initial-setup/`
- `docs/screenshots/glpi/inventory-view/`
- `docs/screenshots/glpi/reports/`
- `docs/screenshots/glpi/fusioninventory-config/`
- `docs/screenshots/glpi/api-usage/`

## Additional Resources

- [GLPI Official Documentation](https://glpi-project.org/documentation/)
- [FusionInventory Plugin](https://fusioninventory.org/)
- [GLPI API Documentation](https://github.com/glpi-project/glpi/blob/master/apirest.md)
- [GLPI Agent Documentation](https://glpi-agent.readthedocs.io/)
