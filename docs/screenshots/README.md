# Screenshots Directory

This directory contains screenshots documenting the execution and results of various automation tasks, configurations, and monitoring dashboards.

## Directory Structure

```
screenshots/
├── ansible/           # Ansible playbook executions
├── jenkins/           # Jenkins pipeline runs
├── semaphore/         # Semaphore UI and task executions
├── docker/           # Docker services and containers
├── glpi/             # GLPI inventory and configuration
└── grafana/          # Grafana dashboards and metrics
```

## Screenshot Guidelines

### Naming Convention

Screenshots should follow this naming pattern:
```
<category>-<component>-<action>-<optional-detail>.png
```

Examples:
- `ansible-rsyslog-config-successful.png`
- `jenkins-pipeline-wildfly-deployment-qa.png`
- `semaphore-task-execution-logrotate.png`
- `glpi-inventory-computer-details.png`
- `grafana-dashboard-infrastructure-overview.png`

### What to Capture

#### Ansible Playbook Executions
- [ ] Rsyslog configuration playbook start
- [ ] Rsyslog configuration successful completion
- [ ] Rsyslog validation execution
- [ ] Rsyslog validation summary
- [ ] Logrotate configuration execution
- [ ] Logrotate validation results
- [ ] GLPI agent deployment
- [ ] Zabbix agent configuration
- [ ] Generated validation reports

#### Jenkins Pipelines
- [ ] Pipeline configuration view
- [ ] Rsyslog validation pipeline execution
- [ ] Pipeline stages progress
- [ ] Console output showing success
- [ ] Logrotate validation results
- [ ] Wildfly deployment pipeline
- [ ] Deployment success notification
- [ ] Pipeline artifacts and reports
- [ ] Build history

#### Semaphore UI
- [ ] Dashboard overview
- [ ] Project configuration
- [ ] Task template list
- [ ] Task execution in progress
- [ ] Real-time output stream
- [ ] Successful task completion
- [ ] Task history
- [ ] Environment configuration
- [ ] Inventory management

#### Docker Services
- [ ] Docker Compose services list
- [ ] Service logs (key services)
- [ ] Container resource usage
- [ ] Network configuration
- [ ] Volume management
- [ ] Service health checks
- [ ] Stack overview

#### GLPI
- [ ] Initial setup wizard
- [ ] Database configuration
- [ ] FusionInventory plugin setup
- [ ] Agent list view
- [ ] Computer inventory details
- [ ] Hardware specifications
- [ ] Software inventory
- [ ] Network information
- [ ] Inventory reports
- [ ] Dashboard overview

#### Grafana
- [ ] Data sources configuration
- [ ] Infrastructure monitoring dashboard
- [ ] Prometheus metrics graphs
- [ ] Loki log viewer
- [ ] GLPI inventory metrics
- [ ] Rsyslog monitoring panel
- [ ] Wildfly metrics
- [ ] Alert rules configuration
- [ ] Dashboard list

## How to Contribute Screenshots

### 1. Execute Task
Run the automation task or access the service you want to document.

### 2. Capture Screenshot
- Use full-screen captures for dashboards
- Crop to relevant content for specific features
- Ensure text is readable (minimum 1920x1080)
- Hide sensitive information (IPs, passwords, tokens)

### 3. Annotate if Necessary
- Add arrows or highlights for key elements
- Include brief text annotations
- Use consistent annotation style

### 4. Save Screenshot
```bash
# Save to appropriate directory
cp screenshot.png docs/screenshots/ansible/rsyslog-config-successful.png
```

### 5. Add Description
Update the corresponding README.md in the subdirectory with:
- Screenshot filename
- Brief description
- What it demonstrates
- Related documentation

## Tools for Screenshots

### Linux
```bash
# Using gnome-screenshot
gnome-screenshot -f output.png

# Using scrot
scrot screenshot.png

# Using import (ImageMagick)
import screenshot.png
```

### macOS
```bash
# Full screen
Cmd + Shift + 3

# Selected area
Cmd + Shift + 4
```

### Annotation Tools
- **GIMP** - Full image editing
- **Inkscape** - Vector annotations
- **Pinta** - Simple editing
- **Flameshot** - Screenshot with annotations

## Screenshot Specifications

- **Format:** PNG (for quality) or JPG (for smaller size)
- **Resolution:** Minimum 1920x1080
- **Compression:** Optimize for web (max 500KB per image)
- **Color:** Full color, maintain readability
- **Annotations:** Red arrows/boxes for highlighting

## Privacy and Security

### DO NOT INCLUDE:
- ❌ Real IP addresses (use 192.168.1.x or blur)
- ❌ Passwords or API keys
- ❌ Sensitive company data
- ❌ Personal information
- ❌ Internal system details

### Safe to Include:
- ✅ UI layouts and navigation
- ✅ Configuration options (with dummy values)
- ✅ Success/failure messages
- ✅ System metrics (anonymized)
- ✅ Log entries (sanitized)

## Example Screenshot Descriptions

### Good Description
```markdown
## Ansible Rsyslog Configuration Execution

**File:** `ansible-rsyslog-config-execution.png`

**Description:** Shows successful execution of rsyslog configuration playbook across 5 hosts. All tasks completed successfully as indicated by the green "ok" status. The validation task at the end confirms configuration syntax is correct.

**Key Points:**
- All 5 hosts responded
- 0 failures
- Configuration validated
- Execution time: 45 seconds

**Related:** See ANSIBLE_PLAYBOOKS.md section on Rsyslog Configuration
```

### Bad Description
```markdown
Screenshot of rsyslog thing working
```

## Screenshot Checklist

Before committing screenshots:
- [ ] Image is clear and readable
- [ ] Sensitive information removed/blurred
- [ ] Filename follows naming convention
- [ ] Saved in correct directory
- [ ] Description added to README
- [ ] File size optimized (< 500KB)
- [ ] Related documentation linked

## Maintenance

### Updating Screenshots
- Review screenshots quarterly
- Update when UI changes significantly
- Replace outdated versions
- Keep old versions in archive/

### Archive Old Screenshots
```bash
mkdir -p docs/screenshots/archive/$(date +%Y%m)
mv old-screenshot.png docs/screenshots/archive/202312/
```

## Questions?

If you have questions about screenshot requirements or contributions:
1. Review existing screenshots for examples
2. Check documentation style guide
3. Contact the documentation team
