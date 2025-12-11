#!/bin/bash
# Script to scan for hardcoded secrets in code
# Uses multiple tools to detect sensitive data

set -e

STRICT_MODE=${1:-""}
EXIT_CODE=0

echo "=========================================="
echo "Scanning for Hardcoded Secrets"
echo "=========================================="

# Create temporary directory for reports
REPORT_DIR="/tmp/secret-scan-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

# 1. Scan for common secret patterns
echo "1. Scanning for common secret patterns..."
SECRET_PATTERNS=(
    "password\s*=\s*['\"][^'\"]{3,}['\"]"
    "api[_-]?key\s*=\s*['\"][^'\"]{10,}['\"]"
    "secret\s*=\s*['\"][^'\"]{10,}['\"]"
    "token\s*=\s*['\"][^'\"]{10,}['\"]"
    "private[_-]?key"
    "BEGIN RSA PRIVATE KEY"
    "BEGIN PRIVATE KEY"
    "aws_access_key_id"
    "aws_secret_access_key"
    "-----BEGIN CERTIFICATE-----"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r -i -E "$pattern" --exclude-dir={.git,target,node_modules,build,dist} . > "$REPORT_DIR/pattern-matches.txt" 2>/dev/null; then
        echo "WARNING: Found potential secrets matching pattern: $pattern"
        EXIT_CODE=1
    fi
done

# 2. Check for common secret file types
echo "2. Checking for secret files..."
FORBIDDEN_EXTENSIONS=("*.pem" "*.key" "*.p12" "*.jks" "*.keystore" "*.pfx")

for ext in "${FORBIDDEN_EXTENSIONS[@]}"; do
    if find . -type f -name "$ext" -not -path "./.git/*" | grep -q .; then
        echo "WARNING: Found secret files with extension: $ext"
        find . -type f -name "$ext" -not -path "./.git/*" >> "$REPORT_DIR/secret-files.txt"
        EXIT_CODE=1
    fi
done

# 3. Check for hardcoded IPs and URLs
echo "3. Checking for hardcoded IPs and database URLs..."
if grep -r -E "jdbc:.*://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" --exclude-dir={.git,target,node_modules} --include="*.java" --include="*.properties" . > "$REPORT_DIR/hardcoded-ips.txt" 2>/dev/null; then
    echo "WARNING: Found hardcoded database IPs"
    EXIT_CODE=1
fi

# 4. Check for common credential variable names
echo "4. Checking for suspicious variable assignments..."
CREDENTIAL_VARS=("DB_PASSWORD" "DATABASE_PASSWORD" "ADMIN_PASSWORD" "ROOT_PASSWORD" "API_SECRET")

for var in "${CREDENTIAL_VARS[@]}"; do
    if grep -r -E "${var}\s*=\s*['\"][^'\"]+['\"]" --exclude-dir={.git,target,node_modules} --include="*.java" --include="*.sh" . > /dev/null 2>&1; then
        echo "WARNING: Found hardcoded credential: $var"
        EXIT_CODE=1
    fi
done

# 5. Check for Base64 encoded secrets (common obfuscation attempt)
echo "5. Checking for Base64 encoded data..."
# Break into multiple commands for better readability
grep -r -E "[A-Za-z0-9+/]{40,}={0,2}" \
    --exclude-dir={.git,target,node_modules} \
    --include="*.java" \
    --include="*.properties" . > "$REPORT_DIR/base64-raw.txt" 2>/dev/null || true

if [ -f "$REPORT_DIR/base64-raw.txt" ]; then
    # Filter out false positives
    grep -v "import\|package\|comment" "$REPORT_DIR/base64-raw.txt" > "$REPORT_DIR/base64-data.txt" || true
    if [ -s "$REPORT_DIR/base64-data.txt" ]; then
        echo "INFO: Found potential Base64 encoded data (review required)"
        # Don't fail on this, just warn
    fi
    rm -f "$REPORT_DIR/base64-raw.txt"
fi

# 6. Use gitleaks if available
if command -v gitleaks &> /dev/null; then
    echo "6. Running gitleaks scan..."
    if ! gitleaks detect --source . --report-path "$REPORT_DIR/gitleaks-report.json" --no-git; then
        echo "WARNING: gitleaks found potential secrets"
        EXIT_CODE=1
    fi
else
    echo "6. gitleaks not installed, skipping..."
fi

# 7. Use truffleHog if available
if command -v trufflehog &> /dev/null; then
    echo "7. Running truffleHog scan..."
    if ! trufflehog filesystem . --json > "$REPORT_DIR/trufflehog-report.json" 2>/dev/null; then
        echo "WARNING: truffleHog found potential secrets"
        EXIT_CODE=1
    fi
else
    echo "7. truffleHog not installed, skipping..."
fi

# Generate summary report
echo "=========================================="
echo "Scan Summary"
echo "=========================================="

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ No secrets detected"
    echo "Report saved to: $REPORT_DIR"
else
    echo "✗ Potential secrets detected!"
    echo "Review the following reports:"
    ls -lh "$REPORT_DIR"
    
    if [ "$STRICT_MODE" == "--strict" ]; then
        echo ""
        echo "STRICT MODE: Failing build due to detected secrets"
        exit 1
    else
        echo ""
        echo "WARNING MODE: Please review and remove any hardcoded secrets"
        echo "To fail the build on secrets, use: $0 --strict"
    fi
fi

exit $EXIT_CODE
