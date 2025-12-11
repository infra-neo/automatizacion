#!/bin/bash
# Health check script for deployed applications
# Usage: ./health-check.sh <environment>

set -e

ENVIRONMENT=$1
MAX_RETRIES=5
RETRY_INTERVAL=10

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

# Load environment-specific configuration
case $ENVIRONMENT in
    "qa")
        APP_URL="${QA_APP_URL:-http://app-qa.company.com:8080}"
        HEALTH_ENDPOINT="/health"
        ;;
    "staging")
        APP_URL="${STAGING_APP_URL:-http://app-staging.company.com:8080}"
        HEALTH_ENDPOINT="/health"
        ;;
    "production")
        APP_URL="${PROD_APP_URL:-https://app.company.com}"
        HEALTH_ENDPOINT="/health"
        ;;
    *)
        echo "Unknown environment: $ENVIRONMENT"
        exit 1
        ;;
esac

echo "=========================================="
echo "Running health check for $ENVIRONMENT"
echo "URL: $APP_URL"
echo "=========================================="

# Function to check HTTP endpoint
check_http() {
    local url=$1
    local expected_status=${2:-200}
    
    echo "Checking $url ..."
    
    for i in $(seq 1 $MAX_RETRIES); do
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")
        
        if [ "$HTTP_STATUS" = "$expected_status" ]; then
            echo "✓ Health check passed (HTTP $HTTP_STATUS)"
            return 0
        else
            echo "⚠ Attempt $i/$MAX_RETRIES: HTTP $HTTP_STATUS (expected $expected_status)"
            if [ $i -lt $MAX_RETRIES ]; then
                sleep $RETRY_INTERVAL
            fi
        fi
    done
    
    echo "✗ Health check failed after $MAX_RETRIES attempts"
    return 1
}

# Function to check Wildfly management endpoint
check_wildfly() {
    local mgmt_host=$1
    local mgmt_port=$2
    
    echo "Checking Wildfly management interface..."
    
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${mgmt_host}/${mgmt_port}" 2>/dev/null; then
        echo "✓ Wildfly management interface is accessible"
        return 0
    else
        echo "✗ Wildfly management interface is not accessible"
        return 1
    fi
}

# Function to check database connectivity
check_database() {
    local db_host=$1
    local db_port=$2
    
    echo "Checking database connectivity..."
    
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/${db_host}/${db_port}" 2>/dev/null; then
        echo "✓ Database is accessible"
        return 0
    else
        echo "✗ Database is not accessible"
        return 1
    fi
}

# Main health checks
EXIT_CODE=0

# 1. Check application health endpoint
if ! check_http "${APP_URL}${HEALTH_ENDPOINT}"; then
    EXIT_CODE=1
fi

# 2. Check application root
if ! check_http "${APP_URL}/"; then
    EXIT_CODE=1
fi

# 3. Check response time
echo "Checking response time..."
RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null "${APP_URL}${HEALTH_ENDPOINT}")
echo "Response time: ${RESPONSE_TIME}s"

# Use awk for arithmetic comparison (more portable than bc)
RESPONSE_THRESHOLD=5
if awk -v rt="$RESPONSE_TIME" -v th="$RESPONSE_THRESHOLD" 'BEGIN {exit !(rt > th)}'; then
    echo "⚠ Warning: Response time is high (>${RESPONSE_TIME}s)"
fi

# 4. Check specific endpoints (if defined)
if [ -n "$ADDITIONAL_ENDPOINTS" ]; then
    IFS=',' read -ra ENDPOINTS <<< "$ADDITIONAL_ENDPOINTS"
    for endpoint in "${ENDPOINTS[@]}"; do
        if ! check_http "${APP_URL}${endpoint}"; then
            EXIT_CODE=1
        fi
    done
fi

echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ All health checks passed"
else
    echo "✗ Some health checks failed"
fi
echo "=========================================="

exit $EXIT_CODE
