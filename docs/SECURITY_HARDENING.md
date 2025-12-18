# Security Hardening Guide

## Overview

This document provides security hardening recommendations for the infrastructure automation platform.

## ⚠️ Critical Security Actions

### Before First Use

1. **Change All Default Passwords**
   ```bash
   # Generate secure passwords
   openssl rand -base64 32
   
   # Services requiring password changes:
   - Jenkins admin
   - Semaphore admin
   - GLPI all default accounts
   - Grafana admin
   - Nexus admin
   - SonarQube admin
   - PostgreSQL users
   - MariaDB users
   - Wildfly admin
   ```

2. **Configure Environment Variables**
   ```bash
   # Copy example env file
   cp docker/.env.example docker/.env
   
   # Generate Semaphore encryption key
   openssl rand -base64 32
   
   # Update .env with secure values
   # NEVER commit .env to version control
   ```

3. **Set Up Vault Properly**
   ```bash
   # DO NOT use dev mode in production
   # Initialize Vault with proper seal keys
   # Store seal keys securely offline
   # Use proper authentication methods
   ```

## Docker Services Security

### 1. Semaphore

**Critical:**
- Generate unique encryption key: `openssl rand -base64 32`
- Store in environment variable, NOT in docker-compose.yml
- Change default admin password immediately
- Use Key Store for all sensitive data (SSH keys, passwords)

**Configuration:**
```yaml
environment:
  - SEMAPHORE_ACCESS_KEY_ENCRYPTION=${SEMAPHORE_ACCESS_KEY}  # From .env
  - SEMAPHORE_ADMIN_PASSWORD=${SEMAPHORE_ADMIN_PASSWORD}     # From .env
```

**Key Store Usage:**
- SSH Keys → Store as "SSH" type
- Passwords → Store as "Password" type
- API Tokens → Store as "Password" type
- Never use plain environment variables for secrets

### 2. GLPI

**Critical:**
- Change ALL default account passwords
- Delete or disable unused default accounts
- Enable strong password policy
- Integrate with LDAP/AD if possible

**Default Accounts to Secure:**
```
After installation:
1. Login with default super-admin
2. Change password immediately
3. Create new admin account
4. Disable/delete original default accounts
5. Configure password policy
```

**Database Security:**
```yaml
environment:
  - MYSQL_ROOT_PASSWORD=${GLPI_ROOT_PASSWORD}  # From .env, not hardcoded
  - MYSQL_PASSWORD=${GLPI_DB_PASSWORD}         # From .env
```

### 3. Wildfly

**Security Checklist:**
- [ ] Change admin console password
- [ ] Restrict management interface to localhost or specific IPs
- [ ] Enable SSL/TLS on management port
- [ ] Configure security realms
- [ ] Set up proper user roles

**Configuration:**
```yaml
environment:
  - WILDFLY_USER=${WILDFLY_ADMIN_USER}
  - WILDFLY_PASS=${WILDFLY_ADMIN_PASSWORD}  # From .env
```

### 4. Jenkins

**Critical:**
- [ ] Change admin password after first login
- [ ] Enable security (Authorization Strategy)
- [ ] Configure proper user permissions
- [ ] Use Credentials Plugin for secrets
- [ ] Enable CSRF protection

**Credentials Management:**
- Store in Jenkins Credentials Manager
- Use Vault integration for sensitive data
- Never hardcode in Jenkinsfiles
- Use credential bindings in pipelines

### 5. Grafana

**Security:**
- [ ] Change admin password
- [ ] Configure authentication (LDAP/OAuth)
- [ ] Set up user roles and permissions
- [ ] Enable SSL/TLS
- [ ] Configure anonymous access (disable for production)

## Ansible Playbook Security

### 1. Zabbix Agent Configuration

**Fixed Security Issues:**
```yaml
# BEFORE (insecure):
disable_gpg_check: yes

# AFTER (secure):
- name: Import Zabbix GPG key
  rpm_key:
    state: present
    key: https://repo.zabbix.com/RPM-GPG-KEY-ZABBIX-A14FE591

- name: Add Zabbix repository
  yum:
    disable_gpg_check: no  # GPG check enabled
```

**Best Practices:**
- Always verify GPG signatures
- Import official GPG keys before adding repositories
- Use official repository URLs only
- Verify package integrity

### 2. Credentials in Playbooks

**DO:**
```yaml
# Use Ansible Vault for sensitive data
ansible-vault encrypt_string 'password123' --name 'db_password'

# Use variables from vault
vars_files:
  - vault.yml

# Use environment variables
environment:
  DB_PASSWORD: "{{ lookup('env', 'DB_PASSWORD') }}"
```

**DON'T:**
```yaml
# Never hardcode credentials
vars:
  db_password: "password123"  # BAD!
```

## Network Security

### 1. Firewall Configuration

**Docker Host:**
```bash
# Allow only necessary ports
ufw allow 80/tcp    # Nginx
ufw allow 443/tcp   # Nginx SSL
ufw allow 22/tcp    # SSH (restrict to specific IPs)

# Deny all other incoming by default
ufw default deny incoming
ufw enable
```

### 2. Docker Network Isolation

```yaml
# Services are isolated in cicd-network
# Only expose necessary ports externally
# Use internal hostnames for service-to-service communication
```

### 3. Restrict Management Interfaces

```bash
# Wildfly management - bind to localhost only
command: /opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 -bmanagement 127.0.0.1

# Or use reverse proxy with authentication
```

## SSL/TLS Configuration

### 1. Nginx Reverse Proxy

```nginx
server {
    listen 443 ssl;
    server_name automation.company.com;
    
    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location /jenkins {
        proxy_pass http://jenkins:8080;
    }
    
    location /grafana {
        proxy_pass http://grafana:3000;
    }
}
```

### 2. Generate Self-Signed Certificates (Dev Only)

```bash
# For development
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/certs/key.pem \
  -out nginx/certs/cert.pem

# For production, use Let's Encrypt or proper CA
```

## Secrets Management with Vault

### 1. Initialize Vault Properly

```bash
# Start Vault in production mode
docker-compose up -d vault

# Initialize (first time only)
docker exec -it vault vault operator init

# Save unseal keys securely OFFLINE
# Save root token securely

# Unseal Vault (requires 3 of 5 keys)
docker exec -it vault vault operator unseal <key1>
docker exec -it vault vault operator unseal <key2>
docker exec -it vault vault operator unseal <key3>
```

### 2. Store Secrets in Vault

```bash
# Store database password
vault kv put secret/database/prod password="secure_password"

# Store API keys
vault kv put secret/api/nexus username="admin" password="secure_password"

# Retrieve in Ansible
- name: Get DB password from Vault
  set_fact:
    db_password: "{{ lookup('hashi_vault', 'secret=secret/database/prod:password') }}"
```

### 3. Jenkins Vault Integration

```groovy
// Jenkinsfile
withVault([
    vaultUrl: 'http://vault:8200',
    vaultCredentialId: 'vault-token'
]) {
    env.DB_PASSWORD = vault.read('secret/database/prod').password
}
```

## Access Control

### 1. SSH Key Management

```bash
# Generate dedicated SSH key for Ansible
ssh-keygen -t ed25519 -C "ansible@automation" -f ~/.ssh/ansible_key

# Restrict key usage
cat >> ~/.ssh/config << EOF
Host automation-*
    User ansible
    IdentityFile ~/.ssh/ansible_key
    StrictHostKeyChecking yes
EOF

# Set proper permissions
chmod 600 ~/.ssh/ansible_key
chmod 644 ~/.ssh/ansible_key.pub
```

### 2. Sudo Configuration

```bash
# On managed hosts, create ansible user with limited sudo
cat > /etc/sudoers.d/ansible << EOF
ansible ALL=(ALL) NOPASSWD: /usr/bin/systemctl, /usr/bin/apt, /usr/bin/yum
EOF

chmod 440 /etc/sudoers.d/ansible
```

### 3. Service Accounts

- Create dedicated service accounts for each tool
- Use principle of least privilege
- Rotate credentials regularly
- Audit access logs

## Monitoring and Auditing

### 1. Enable Audit Logging

```yaml
# All services should log authentication attempts
# Configure log forwarding to centralized logging

# Loki aggregates logs
# Set up alerts for:
- Failed login attempts
- Privilege escalations
- Configuration changes
- Deployment activities
```

### 2. Grafana Alerts

```yaml
# Alert on suspicious activities
- Multiple failed logins
- Unauthorized access attempts
- Service disruptions
- Certificate expiration
```

### 3. Regular Audits

```bash
# Weekly security checks
./scripts/security-audit.sh

# Check for:
- Default passwords
- Weak configurations
- Outdated packages
- Exposed services
- Unpatched vulnerabilities
```

## Backup and Recovery

### 1. Backup Strategy

```bash
# Daily backups of critical data
./scripts/backup-volumes.sh

# Backup Vault seal keys (offline, encrypted)
# Backup database dumps (encrypted)
# Backup configurations
```

### 2. Encryption at Rest

```bash
# Encrypt backup files
openssl enc -aes-256-cbc -salt -in backup.tar.gz -out backup.tar.gz.enc

# Decrypt when needed
openssl enc -aes-256-cbc -d -in backup.tar.gz.enc -out backup.tar.gz
```

## Compliance

### 1. Regular Updates

```bash
# Update Docker images monthly
docker-compose pull
docker-compose up -d

# Update OS packages
apt update && apt upgrade -y  # Debian/Ubuntu
yum update -y                  # RHEL/CentOS
```

### 2. Security Scanning

```bash
# Scan Docker images
docker scan jenkins/jenkins:lts

# Run vulnerability assessments
# Use SonarQube for code security
# Enable dependency checking
```

### 3. Documentation

- Document all security configurations
- Maintain incident response plan
- Keep inventory of credentials
- Regular security training

## Security Checklist

### Initial Setup
- [ ] Change all default passwords
- [ ] Configure .env file with secure values
- [ ] Set up Vault properly (not dev mode)
- [ ] Configure SSL/TLS certificates
- [ ] Set up firewall rules
- [ ] Configure network isolation

### Service Configuration
- [ ] Jenkins: Security enabled, credentials in Vault
- [ ] Semaphore: Encryption key set, Key Store configured
- [ ] GLPI: Default accounts secured/disabled
- [ ] Grafana: Authentication configured
- [ ] Wildfly: Admin interface secured
- [ ] All databases: Strong passwords

### Ongoing Maintenance
- [ ] Regular password rotation (quarterly)
- [ ] Security updates applied monthly
- [ ] Audit logs reviewed weekly
- [ ] Backup tested monthly
- [ ] Vulnerability scans quarterly
- [ ] Security training annual

## Incident Response

### 1. Suspected Breach

```bash
# Immediate actions:
1. Isolate affected systems
2. Change all passwords
3. Review audit logs
4. Check for unauthorized changes
5. Restore from clean backup if needed
```

### 2. Contact Information

- Security Team: security@company.com
- Incident Response: incident@company.com
- On-Call: +1-XXX-XXX-XXXX

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Ansible Security Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#best-practices-for-variables-and-vaults)
- [Vault Security Model](https://www.vaultproject.io/docs/internals/security)
