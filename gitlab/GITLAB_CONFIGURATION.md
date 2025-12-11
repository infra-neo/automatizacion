# GitLab Repository Configuration

## Branch Strategy

### Protected Branches

#### Main Branch (main)
- **Protection Level**: Fully Protected
- **Merge Request Required**: Yes
- **Code Owners Approval Required**: Yes
- **Allow Force Push**: No
- **Allowed to Merge**: Maintainers only
- **Allowed to Push**: No one

#### Development Branch (develop)
- **Protection Level**: Protected
- **Merge Request Required**: Yes
- **Allow Force Push**: No
- **Allowed to Merge**: Developers + Maintainers
- **Allowed to Push**: No one

#### QA Branch (qa)
- **Protection Level**: Protected
- **Merge Request Required**: Yes
- **Allow Force Push**: No
- **Allowed to Merge**: Developers + QA Team + Maintainers
- **Allowed to Push**: No one
- **Deployment**: Automatic to QA environment (manual trigger)

#### Staging Branch (staging)
- **Protection Level**: Protected
- **Merge Request Required**: Yes
- **Code Review Required**: 1 approval minimum
- **Allow Force Push**: No
- **Allowed to Merge**: "implementacion" group only
- **Allowed to Push**: No one
- **Deployment**: Manual to Staging environment

#### Production Branch (production)
- **Protection Level**: Fully Protected
- **Merge Request Required**: Yes
- **Code Review Required**: 2 approvals minimum
- **Allow Force Push**: No
- **Allowed to Merge**: "implementacion" group only (senior members)
- **Allowed to Push**: No one
- **Deployment**: Manual to Production environment (with approval)
- **Deployment Approvals**: Required from at least 2 senior members

## Access Control Lists (ACLs)

### Groups and Permissions

#### 1. implementacion (Implementation Group)
**Members**: Senior DevOps Engineers, Release Managers
**Permissions**:
- Full access to all branches
- Can merge to staging and production
- Can deploy to staging and production
- Can manage CI/CD variables
- Can manage protected branches

**GitLab Role**: Maintainer

#### 2. developers (Development Group)
**Members**: Software Developers
**Permissions**:
- Read/Write access to feature branches
- Can create merge requests to develop, qa
- Can merge to develop and qa (with approval)
- Cannot deploy to production
- Cannot access production secrets

**GitLab Role**: Developer

#### 3. qa-team (QA Team Group)
**Members**: QA Engineers, Testers
**Permissions**:
- Read access to all branches
- Can deploy to QA environment
- Can trigger QA pipelines
- Can approve QA-related merge requests

**GitLab Role**: Reporter + specific QA deployment role

#### 4. operators (Operations Group)
**Members**: System Administrators, Support Engineers
**Permissions**:
- Read access to all branches
- Can view CI/CD pipelines
- Can access logs and monitoring
- Cannot modify code or deploy

**GitLab Role**: Reporter

### Repository Settings in GitLab

```yaml
# .gitlab/CODEOWNERS
# This file defines code ownership and required approvals

# Global owners
* @implementacion

# Specific path owners
/config-repos/production/ @implementacion
/vault/ @implementacion
/jenkins/production/ @implementacion
/ansible-blueprints/ @implementacion @operators

# CI/CD configuration
/.gitlab-ci.yml @implementacion
/Jenkinsfile @implementacion
```

## Branch Workflow

### Feature Development Flow
1. Developer creates feature branch from `develop`
2. Developer commits changes to feature branch
3. Developer creates merge request to `develop`
4. Automated CI/CD pipeline runs (build, test, security scan)
5. Code review by peer developer
6. Merge to `develop` after approval

### QA Flow
1. Create merge request from `develop` to `qa`
2. CI/CD pipeline builds and packages
3. Manual deployment to QA environment
4. QA team performs testing
5. If approved, proceed to staging

### Staging Flow
1. Create merge request from `qa` to `staging`
2. Requires approval from "implementacion" group member
3. CI/CD pipeline runs all tests and security scans
4. Manual deployment to staging environment
5. Integration testing and UAT
6. If approved, proceed to production

### Production Flow
1. Create merge request from `staging` to `production`
2. Requires 2 approvals from "implementacion" group senior members
3. CI/CD pipeline runs complete test suite and security scans
4. Manual deployment to production (requires separate approval)
5. Post-deployment verification
6. Automated notification to stakeholders

## CI/CD Variables Configuration

### Protected Variables (only available in protected branches)

#### QA Environment Variables
- `WILDFLY_QA_HOST`
- `WILDFLY_QA_PORT`
- `WILDFLY_QA_ADMIN_USER`
- `WILDFLY_QA_ADMIN_PASSWORD` (masked)
- `NEXUS_QA_CREDENTIALS` (masked)

#### Staging Environment Variables
- `WILDFLY_STAGING_HOST`
- `WILDFLY_STAGING_PORT`
- `WILDFLY_STAGING_ADMIN_USER`
- `WILDFLY_STAGING_ADMIN_PASSWORD` (masked)
- `NEXUS_STAGING_CREDENTIALS` (masked)

#### Production Environment Variables (Protected + Hidden)
- `WILDFLY_PROD_HOST` (protected)
- `WILDFLY_PROD_PORT` (protected)
- `WILDFLY_PROD_ADMIN_USER` (protected)
- `WILDFLY_PROD_ADMIN_PASSWORD` (masked + protected)
- `NEXUS_PROD_CREDENTIALS` (masked + protected)
- `VAULT_TOKEN` (masked + protected)

### Shared Variables
- `NEXUS_BASE_URL`
- `SONARQUBE_URL`
- `SONARQUBE_TOKEN` (masked)
- `VAULT_ADDRESS`
- `NOTIFICATION_EMAIL`

## GitLab Runner Configuration

### Runners for Different Environments

#### Shared Runners (for build/test)
- Tag: `docker`
- Used for: build, test, security-scan stages
- Environment: Containerized
- No access to production secrets

#### QA Deployment Runner
- Tag: `deployment`
- Used for: QA deployments
- Environment: QA network access
- Access to QA credentials only

#### Staging Deployment Runner
- Tag: `deployment`
- Used for: Staging deployments
- Environment: Staging network access
- Access to staging credentials only

#### Production Deployment Runner
- Tag: `production-deployment`
- Used for: Production deployments only
- Environment: Production network (isolated)
- Access to production credentials only
- **Restricted to "implementacion" group members**

## Merge Request Templates

Create the following file: `.gitlab/merge_request_templates/default.md`

```markdown
## Description
<!-- Describe your changes in detail -->

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Configuration change
- [ ] Documentation update

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No sensitive data in code
- [ ] Tests added/updated
- [ ] All tests passing
- [ ] Security scan passed

## Target Environment
- [ ] QA
- [ ] Staging
- [ ] Production

## Related Issues
<!-- Link to related issues -->

## Screenshots (if applicable)
<!-- Add screenshots here -->
```

## Security Policies

### Secret Scanning
- GitLab Secret Detection enabled
- Pre-receive hooks prevent commits with secrets
- CI/CD pipeline fails if secrets detected

### Vulnerability Scanning
- Container scanning enabled for Docker images
- Dependency scanning enabled for Maven projects
- SAST (Static Application Security Testing) enabled

### Compliance
- Audit logs enabled for all deployments
- Approval rules enforced for production
- Deployment freeze during maintenance windows

## Notifications

### Email Notifications
- Pipeline failures → Development team
- QA deployments → QA team
- Staging deployments → Stakeholders
- Production deployments → All teams + Management

### Chat Notifications (Slack/Teams)
- #dev-notifications: All pipeline events
- #qa-notifications: QA-related events
- #prod-deployments: Production deployments only (restricted channel)

## Repository Mirroring

### Mirror to Internal GitLab
```bash
# Setup repository mirroring for backup and compliance
# In GitLab: Settings → Repository → Mirroring repositories
Mirror URL: https://internal-gitlab.company.com/infra-neo/automatizacion.git
Direction: Push
Authentication: Password
```

## Disaster Recovery

### Backup Strategy
- Automated daily backups of repository
- Configuration files backed up to secure storage
- Production deployment artifacts retained for 90 days

### Recovery Procedures
1. Restore from GitLab backup
2. Verify branch structure and permissions
3. Restore CI/CD variables from Vault
4. Test pipeline functionality
5. Notify teams of restoration

## Best Practices

1. **Never commit secrets** - Always use Vault or CI/CD variables
2. **Use feature branches** - Never commit directly to protected branches
3. **Write meaningful commit messages** - Follow conventional commits
4. **Tag releases** - Use semantic versioning (v1.0.0)
5. **Review code thoroughly** - All code must be reviewed before merge
6. **Test before merge** - Ensure all tests pass
7. **Document changes** - Update relevant documentation
8. **Small, focused commits** - One logical change per commit
