# Ansible Playbooks Documentation

## Overview

This document describes the Ansible playbooks available for configuration and validation of system services, focusing on rsyslog, logrotate, GLPI, and Zabbix integration.

## Available Playbooks

### 1. Rsyslog Configuration and Validation

#### Configure Rsyslog (`ansible-blueprints/rsyslog/configure-rsyslog.yml`)

Configures centralized logging using rsyslog across all managed hosts.

**Features:**
- Installs and enables rsyslog service
- Configures remote log server forwarding
- Sets up local log rotation policies
- Configures custom application logging
- Handles SELinux and firewall rules
- Validates configuration syntax

**Usage:**
```bash
# Basic usage
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/rsyslog/configure-rsyslog.yml

# With custom variables
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/rsyslog/configure-rsyslog.yml \
  -e "central_log_server=syslog.company.com" \
  -e "central_log_port=514" \
  -e "log_protocol=tcp"

# Target specific hosts
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/rsyslog/configure-rsyslog.yml \
  --limit webservers
```

**Variables:**
- `central_log_server`: Central syslog server address (default: syslog.company.com)
- `central_log_port`: Syslog server port (default: 514)
- `log_protocol`: Protocol to use - tcp or udp (default: tcp)
- `local_log_retention_days`: Days to keep local logs (default: 30)

**Tags:**
- `install`: Package installation only
- `config`: Configuration tasks only
- `validate`: Validation tasks only
- `service`: Service management only

#### Validate Rsyslog (`ansible-blueprints/rsyslog/validate-rsyslog.yml`)

Validates rsyslog installation, configuration, and functionality.

**Features:**
- Verifies package installation
- Checks service status (running and enabled)
- Validates configuration syntax
- Tests log message delivery
- Checks disk space for logs
- Analyzes error logs
- Generates validation reports

**Usage:**
```bash
# Full validation
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/rsyslog/validate-rsyslog.yml

# Validation with specific tags
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/rsyslog/validate-rsyslog.yml \
  --tags check,validate
```

**Output:**
- Console validation summary
- Detailed reports in `reports/rsyslog-validation-<hostname>-<date>.txt`

### 2. Logrotate Configuration and Validation

#### Configure Logrotate (`ansible-blueprints/logrotate/configure-logrotate.yml`)

Manages log rotation policies for system and application logs.

**Features:**
- Installs logrotate package
- Configures system log rotation
- Sets up application-specific rotation policies
- Configures Wildfly/JBoss log rotation
- Configures Jenkins log rotation
- Configures Docker container log rotation
- Sets up cron job for automatic rotation
- Creates comprehensive documentation

**Usage:**
```bash
# Basic usage
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/logrotate/configure-logrotate.yml

# With custom settings
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/logrotate/configure-logrotate.yml \
  -e "log_rotation_count=7" \
  -e "max_size=200M" \
  -e "compress=true"

# Configure specific services
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/logrotate/configure-logrotate.yml \
  -e "configure_wildfly=true" \
  -e "configure_jenkins=true"
```

**Variables:**
- `log_rotation_days`: Days between rotations (default: 7)
- `log_rotation_count`: Number of rotations to keep (default: 4)
- `max_size`: Maximum log file size before rotation (default: 100M)
- `compress`: Enable compression of rotated logs (default: true)
- `configure_wildfly`: Configure Wildfly logs (default: true)
- `configure_jenkins`: Configure Jenkins logs (default: true)
- `configure_docker_logs`: Configure Docker container logs (default: true)

**Tags:**
- `install`: Package installation
- `config`: Configuration tasks
- `test`: Test configuration
- `validate`: Validation tasks
- `docs`: Documentation generation

#### Validate Logrotate (`ansible-blueprints/logrotate/validate-logrotate.yml`)

Validates logrotate installation and configuration.

**Features:**
- Verifies package installation
- Checks configuration file existence
- Validates configuration syntax
- Tests dry run rotation
- Checks existing rotated logs
- Verifies disk space
- Performs test rotation
- Checks cron configuration
- Generates validation reports

**Usage:**
```bash
# Full validation
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/logrotate/validate-logrotate.yml

# Skip cleanup
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/logrotate/validate-logrotate.yml \
  --skip-tags cleanup
```

**Output:**
- Console validation summary
- Detailed reports in `reports/logrotate-validation-<hostname>-<date>.txt`

### 3. GLPI Agent Configuration

#### Configure GLPI Agent (`ansible-blueprints/glpi-agent/configure-glpi-agent.yml`)

Sets up GLPI agent for inventory management and reporting.

**Features:**
- Installs GLPI agent from official repositories
- Configures GLPI server connection
- Sets up inventory collection intervals
- Enables inventory modules
- Configures logging
- Creates monitoring cron jobs
- Sets up log rotation for agent logs
- Verifies connectivity to GLPI server
- Generates configuration reports

**Usage:**
```bash
# Basic usage
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/glpi-agent/configure-glpi-agent.yml

# With custom GLPI server
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/glpi-agent/configure-glpi-agent.yml \
  -e "glpi_server=https://glpi.company.com/plugins/fusioninventory" \
  -e "glpi_interval=24"
```

**Variables:**
- `glpi_server`: GLPI server URL (default: https://glpi.company.com/plugins/fusioninventory)
- `glpi_interval`: Inventory interval in hours (default: 24)
- `glpi_debug`: Enable debug logging (default: false)

**Output:**
- Agent reports in `reports/glpi-<hostname>-<date>.txt`

### 4. Zabbix Agent Configuration

#### Configure Zabbix Agent (`ansible-blueprints/zabbix/configure-zabbix-agent.yml`)

Sets up Zabbix agent for monitoring and inventory discovery.

**Features:**
- Installs Zabbix agent from official repositories
- Configures Zabbix server connection
- Sets up active and passive checks
- Configures custom user parameters
- Creates custom monitoring scripts
- Configures firewall rules
- Handles SELinux policies
- Validates agent connectivity
- Generates configuration reports

**Usage:**
```bash
# Basic usage
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/zabbix/configure-zabbix-agent.yml

# With custom Zabbix server
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/zabbix/configure-zabbix-agent.yml \
  -e "zabbix_server=zabbix.company.com" \
  -e "zabbix_agent_port=10050"

# Enable remote commands (use with caution)
ansible-playbook -i ansible/inventories/production/hosts \
  ansible-blueprints/zabbix/configure-zabbix-agent.yml \
  -e "enable_remote_commands=1"
```

**Variables:**
- `zabbix_server`: Zabbix server address (default: zabbix.company.com)
- `zabbix_server_port`: Zabbix server port (default: 10051)
- `zabbix_agent_port`: Zabbix agent port (default: 10050)
- `zabbix_agent_version`: Agent version to install (default: 6.0)
- `enable_remote_commands`: Enable remote command execution (default: 0)
- `agent_timeout`: Agent timeout in seconds (default: 3)

**Output:**
- Configuration reports in `reports/zabbix-agent-<hostname>-<date>.txt`

## Inventory Management

### Inventory Files

Inventories are organized by environment:

```
ansible/inventories/
├── qa/
│   └── hosts
├── staging/
│   └── hosts
└── production/
    └── hosts
```

### Example Inventory File

```ini
[all:vars]
ansible_user=ansible
ansible_become=yes
ansible_python_interpreter=/usr/bin/python3

[webservers]
web1.company.com
web2.company.com

[databases]
db1.company.com
db2.company.com

[monitoring]
monitor.company.com

[glpi]
glpi.company.com

[zabbix]
zabbix.company.com
```

## Best Practices

### 1. Pre-execution Checks
```bash
# Check syntax
ansible-playbook --syntax-check playbook.yml

# Dry run
ansible-playbook --check playbook.yml

# List tasks
ansible-playbook --list-tasks playbook.yml
```

### 2. Using Tags
```bash
# Run only installation tasks
ansible-playbook playbook.yml --tags install

# Skip validation
ansible-playbook playbook.yml --skip-tags validate
```

### 3. Limiting Hosts
```bash
# Single host
ansible-playbook -i inventory playbook.yml --limit host1.company.com

# Group of hosts
ansible-playbook -i inventory playbook.yml --limit webservers

# Multiple groups
ansible-playbook -i inventory playbook.yml --limit webservers:databases
```

### 4. Verbose Output
```bash
# Basic verbose
ansible-playbook -v playbook.yml

# More verbose
ansible-playbook -vv playbook.yml

# Maximum verbose
ansible-playbook -vvv playbook.yml
```

## Troubleshooting

### Common Issues

#### 1. Connection Failures
```bash
# Test connectivity
ansible all -i inventory -m ping

# Check SSH
ansible all -i inventory -m shell -a "hostname"
```

#### 2. Permission Issues
```bash
# Verify sudo access
ansible all -i inventory -m shell -a "whoami" --become

# Check sudoers configuration
ansible all -i inventory -m shell -a "sudo -l" --become
```

#### 3. Package Installation Failures
```bash
# Update package cache
ansible all -i inventory -m apt -a "update_cache=yes" --become

# Check repository configuration
ansible all -i inventory -m shell -a "apt-cache policy rsyslog" --become
```

## Reports and Output

All playbooks generate detailed reports stored in the `reports/` directory:

- **Rsyslog validation**: `reports/rsyslog-validation-<hostname>-<date>.txt`
- **Logrotate validation**: `reports/logrotate-validation-<hostname>-<date>.txt`
- **GLPI configuration**: `reports/glpi-<hostname>-<date>.txt`
- **Zabbix configuration**: `reports/zabbix-agent-<hostname>-<date>.txt`

Reports include:
- Configuration summary
- Service status
- Validation results
- Test outcomes
- Error logs
- Recommendations

## Integration with CI/CD

These playbooks are integrated with:

### Jenkins Pipelines
- `Jenkinsfile-rsyslog-validation`
- `Jenkinsfile-logrotate-validation`
- `Jenkinsfile-wildfly-deployment`

### Semaphore Tasks
- Configure Rsyslog
- Validate Rsyslog
- Configure Logrotate
- Validate Logrotate
- Configure GLPI Agent
- Configure Zabbix Agent
- Full System Configuration
- Full System Validation

See `JENKINS_PIPELINES.md` and `SEMAPHORE_WORKFLOWS.md` for details.

## Screenshots

Screenshots of playbook executions are available in:
- `docs/screenshots/ansible/rsyslog-config.png`
- `docs/screenshots/ansible/rsyslog-validation.png`
- `docs/screenshots/ansible/logrotate-config.png`
- `docs/screenshots/ansible/logrotate-validation.png`
- `docs/screenshots/ansible/glpi-config.png`
- `docs/screenshots/ansible/zabbix-config.png`

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review playbook documentation
3. Check logs in `/var/log/`
4. Review generated reports in `reports/`
5. Contact the infrastructure team
