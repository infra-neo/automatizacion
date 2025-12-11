# Security Best Practices and Guidelines

## 🔐 Overview

This document outlines security best practices for the CI/CD infrastructure and application development.

## Table of Contents
1. [Secrets Management](#secrets-management)
2. [Access Control](#access-control)
3. [Code Security](#code-security)
4. [Infrastructure Security](#infrastructure-security)
5. [Deployment Security](#deployment-security)
6. [Monitoring and Auditing](#monitoring-and-auditing)

## Secrets Management

### ✅ DO
- **Always use Vault** for storing secrets
- **Rotate credentials** regularly (every 90 days minimum)
- **Use environment-specific secrets** (separate QA, Staging, Production)
- **Encrypt secrets** at rest and in transit
- **Limit secret access** to minimum required permissions

```bash
# Store secret in Vault
vault kv put secret/production/database \
  username="dbuser" \
  password="$(openssl rand -base64 32)"

# Retrieve in pipeline
DB_PASSWORD=$(vault kv get -field=password secret/production/database)
```

### ❌ DON'T
- **Never commit secrets** to Git
- **Never hardcode credentials** in code
- **Never log secrets** in console output
- **Never share secrets** via email or chat
- **Never use default passwords** in production

### Secret Scanning

Run before every commit:
```bash
./scripts/scan-secrets.sh --strict
```

Configure Git hooks:
```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
./scripts/scan-secrets.sh --strict
if [ $? -ne 0 ]; then
    echo "Secret detected! Commit aborted."
    exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

## Access Control

### Role-Based Access Control (RBAC)

#### Production Environment
- **Access**: implementacion group only
- **Approval**: Requires 2 senior members
- **MFA**: Mandatory for all production access
- **Audit**: All actions logged

#### Staging Environment
- **Access**: implementacion group
- **Approval**: Requires 1 member
- **MFA**: Recommended

#### QA Environment
- **Access**: developers, qa-team, implementacion
- **Approval**: Not required
- **MFA**: Optional

### SSH Access

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "user@company.com"

# Use SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Never commit private keys
echo "*.pem" >> .gitignore
echo "*.key" >> .gitignore
```

### VPN Requirements

Production access requires:
- Active VPN connection
- Valid certificate
- Multi-factor authentication
- Whitelisted IP address

## Code Security

### Static Application Security Testing (SAST)

#### SonarQube Integration
```xml
<properties>
  <!-- Fail build on critical issues -->
  <sonar.qualitygate.wait>true</sonar.qualitygate.wait>
</properties>
```

#### Security Rules
- No hardcoded secrets (squid:S2068)
- SQL injection prevention (squid:S3649)
- XSS prevention (squid:S5131)
- CSRF protection (squid:S4502)
- Secure random (squid:S2245)

### Dependency Scanning

#### OWASP Dependency Check
```xml
<plugin>
  <groupId>org.owasp</groupId>
  <artifactId>dependency-check-maven</artifactId>
  <configuration>
    <failBuildOnCVSS>7</failBuildOnCVSS>
    <suppressionFile>owasp-suppressions.xml</suppressionFile>
  </configuration>
</plugin>
```

#### Update Dependencies Regularly
```bash
# Check for updates
mvn versions:display-dependency-updates

# Update to latest
mvn versions:use-latest-releases
```

### Secure Coding Practices

#### Input Validation
```java
// DO: Validate and sanitize input
@NotNull
@Pattern(regexp = "[a-zA-Z0-9]+")
private String username;

// DON'T: Trust user input
String query = "SELECT * FROM users WHERE name = '" + userInput + "'"; // SQL Injection!
```

#### Parameterized Queries
```java
// DO: Use parameterized queries
String query = "SELECT * FROM users WHERE name = ?";
PreparedStatement stmt = connection.prepareStatement(query);
stmt.setString(1, username);

// DON'T: String concatenation
String query = "SELECT * FROM users WHERE name = '" + username + "'";
```

#### Secure Password Storage
```java
// DO: Use BCrypt or similar
BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
String hashedPassword = encoder.encode(plainPassword);

// DON'T: Plain text or MD5
String password = plainPassword; // NEVER!
String md5Hash = MD5.hash(password); // Broken algorithm!
```

## Infrastructure Security

### Container Security

#### Scan Docker Images
```bash
# Scan for vulnerabilities
docker scan jenkins:latest

# Use official images only
# FROM jenkins/jenkins:lts-jdk17
```

#### Run as Non-Root
```dockerfile
# In Dockerfile
USER jenkins

# Never run as root in production
```

#### Limit Resources
```yaml
# In docker-compose.yml
services:
  jenkins:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
```

### Network Security

#### Use Private Networks
```yaml
networks:
  cicd-network:
    driver: bridge
    internal: false  # Set to true for internal-only
```

#### Enable TLS/SSL
```yaml
# nginx configuration
server {
  listen 443 ssl;
  ssl_certificate /etc/nginx/certs/cert.pem;
  ssl_certificate_key /etc/nginx/certs/key.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
}
```

#### Firewall Rules
```bash
# Allow only necessary ports
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 443/tcp  # HTTPS
sudo ufw deny 8080/tcp  # Block direct Jenkins access
sudo ufw enable
```

### Vault Security

#### Seal/Unseal Process
```bash
# Initialize Vault (one time)
vault operator init -key-shares=5 -key-threshold=3

# Store unseal keys SEPARATELY and SECURELY
# - Key 1: Person A
# - Key 2: Person B
# - Key 3: Person C
# - Key 4: Secure backup location 1
# - Key 5: Secure backup location 2

# Unseal requires 3 of 5 keys
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
```

#### Vault Policies
```hcl
# Principle of least privilege
path "secret/data/production/*" {
  capabilities = ["read"]  # Read-only for most users
}

path "secret/data/production/database" {
  capabilities = ["read", "list"]
  denied_parameters = {
    "password" = []  # Specific restrictions
  }
}
```

## Deployment Security

### Pre-Deployment Checks

1. **Code Review**: All changes reviewed by peer
2. **Security Scan**: SonarQube and OWASP passed
3. **Secret Scan**: No hardcoded secrets
4. **Tests**: All tests passing
5. **Approval**: Required approvals obtained

### Deployment Process

```bash
# 1. Health check before deployment
./scripts/health-check.sh production

# 2. Create backup
./scripts/backup-production.sh

# 3. Deploy with monitoring
./scripts/deploy-to-wildfly.sh production

# 4. Verify deployment
./scripts/health-check.sh production

# 5. Rollback if failed
if [ $? -ne 0 ]; then
  ./scripts/rollback-deployment.sh
fi
```

### Production Checklist

- [ ] Code review approved
- [ ] All tests passing
- [ ] Security scans passed
- [ ] Backup created
- [ ] Rollback plan prepared
- [ ] Monitoring enabled
- [ ] Team notified
- [ ] Documentation updated

## Monitoring and Auditing

### Audit Logging

#### Enable Audit Logs
```yaml
# Vault audit log
vault audit enable file file_path=/var/log/vault/audit.log

# Jenkins audit log
# Install Audit Trail plugin

# GitLab audit events
# Settings → Audit Events
```

#### Review Logs Regularly
```bash
# Daily review of critical events
grep "authentication.*failed" /var/log/vault/audit.log
grep "deployment.*production" /var/log/cicd/audit.log
grep "secrets.*accessed" /var/log/vault/audit.log
```

### Security Monitoring

#### Alerts to Configure
- Failed authentication attempts (>5 in 5 minutes)
- Unauthorized access attempts
- Secret access from unknown IPs
- Deployment to production
- Critical vulnerabilities detected
- Vault sealed unexpectedly

#### Log Retention
- **Production**: 90 days minimum
- **Staging**: 30 days
- **QA**: 7 days
- **Audit logs**: 1 year (compliance requirement)

### Incident Response

#### Security Incident Detected

1. **Immediate Actions**:
   - Isolate affected systems
   - Revoke compromised credentials
   - Enable additional logging
   - Notify security team

2. **Investigation**:
   - Review audit logs
   - Identify scope of breach
   - Document timeline
   - Preserve evidence

3. **Remediation**:
   - Patch vulnerabilities
   - Rotate all secrets
   - Update security policies
   - Implement additional controls

4. **Post-Incident**:
   - Conduct root cause analysis
   - Update procedures
   - Train team
   - Improve monitoring

## Compliance

### Data Protection
- Encrypt data at rest (AES-256)
- Encrypt data in transit (TLS 1.2+)
- Implement data retention policies
- Regular security audits

### Access Reviews
- Quarterly review of user access
- Remove inactive accounts
- Validate group memberships
- Audit privileged access

### Penetration Testing
- Annual penetration tests
- Quarterly vulnerability scans
- Regular security assessments
- Bug bounty program (optional)

## Security Checklist

### Daily
- [ ] Review failed authentication logs
- [ ] Check security alerts
- [ ] Verify backup completion

### Weekly
- [ ] Review access logs
- [ ] Update security rules
- [ ] Check for new vulnerabilities

### Monthly
- [ ] Rotate non-critical secrets
- [ ] Review user access
- [ ] Update dependencies
- [ ] Security training

### Quarterly
- [ ] Rotate critical secrets
- [ ] Access review and cleanup
- [ ] Penetration testing
- [ ] Policy updates

### Annually
- [ ] Full security audit
- [ ] Update security policies
- [ ] Disaster recovery drill
- [ ] Compliance review

## Resources

### Security Tools
- OWASP Dependency Check
- SonarQube
- GitLeaks
- TruffleHog
- Vault

### Documentation
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

### Training
- Security awareness training
- Secure coding practices
- Incident response procedures

## Contact

**Security Team**: security@company.com  
**Emergency**: +1-XXX-XXX-XXXX  
**Incident Reporting**: incidents@company.com

---

**Remember**: Security is everyone's responsibility!
