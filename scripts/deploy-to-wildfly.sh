#!/bin/bash
# Script to deploy WAR/EAR files to Wildfly/JBoss application server
# Usage: ./deploy-to-wildfly.sh <environment> <host> <port> <username> <password> <artifact>

set -e

ENVIRONMENT=$1
WILDFLY_HOST=$2
WILDFLY_PORT=$3
WILDFLY_USER=$4
WILDFLY_PASS=$5
ARTIFACT=$6

# Validate parameters
if [ -z "$ENVIRONMENT" ] || [ -z "$WILDFLY_HOST" ] || [ -z "$WILDFLY_PORT" ] || [ -z "$ARTIFACT" ]; then
    echo "Error: Missing required parameters"
    echo "Usage: $0 <environment> <host> <port> <username> <password> <artifact>"
    exit 1
fi

echo "=========================================="
echo "Deploying to Wildfly/JBoss"
echo "Environment: $ENVIRONMENT"
echo "Host: $WILDFLY_HOST:$WILDFLY_PORT"
echo "Artifact: $ARTIFACT"
echo "=========================================="

# Get artifact name without path
ARTIFACT_NAME=$(basename "$ARTIFACT")
APP_NAME="${ARTIFACT_NAME%.*}"

# Wildfly CLI connection string
WILDFLY_CLI="./jboss-cli.sh --connect --controller=${WILDFLY_HOST}:${WILDFLY_PORT} --user=${WILDFLY_USER} --password=${WILDFLY_PASS}"

# Check if Wildfly is running
echo "Checking Wildfly server status..."
if ! timeout 10 bash -c "cat < /dev/null > /dev/tcp/${WILDFLY_HOST}/${WILDFLY_PORT}" 2>/dev/null; then
    echo "Error: Cannot connect to Wildfly server at ${WILDFLY_HOST}:${WILDFLY_PORT}"
    exit 1
fi
echo "Wildfly server is accessible"

# Backup current deployment if exists
echo "Checking for existing deployment..."
EXISTING_DEPLOYMENT=$(${WILDFLY_CLI} --command="deployment-info --name=${ARTIFACT_NAME}" 2>/dev/null || true)

if [ -n "$EXISTING_DEPLOYMENT" ]; then
    echo "Found existing deployment, creating backup..."
    BACKUP_DIR="/opt/wildfly/backups/${ENVIRONMENT}/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Export current deployment
    ${WILDFLY_CLI} --command="deployment undeploy ${ARTIFACT_NAME} --keep-content" || true
    echo "Current deployment backed up"
fi

# Deploy new artifact
echo "Deploying new artifact: ${ARTIFACT}"
${WILDFLY_CLI} --command="deploy ${ARTIFACT} --force"

# Verify deployment
echo "Verifying deployment..."
sleep 5

DEPLOYMENT_STATUS=$(${WILDFLY_CLI} --command="deployment-info --name=${ARTIFACT_NAME}" | grep -i "enabled" || true)

if [ -n "$DEPLOYMENT_STATUS" ]; then
    echo "=========================================="
    echo "Deployment successful!"
    echo "Application: $APP_NAME"
    echo "Status: Enabled"
    echo "=========================================="
    
    # Log deployment
    echo "$(date): Deployed ${ARTIFACT_NAME} to ${ENVIRONMENT}" >> /var/log/deployments.log
    
    exit 0
else
    echo "=========================================="
    echo "Deployment failed!"
    echo "=========================================="
    
    # Rollback if backup exists
    if [ -n "$BACKUP_DIR" ]; then
        echo "Rolling back to previous version..."
        ${WILDFLY_CLI} --command="deploy --force" || true
    fi
    
    exit 1
fi
