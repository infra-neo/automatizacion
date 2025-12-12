#!/bin/bash
# Script to send notifications via email
# Usage: ./send-notification.sh <status> <environment> [message]

set -e

STATUS=$1
ENVIRONMENT=$2
MESSAGE=${3:-"Pipeline execution completed"}

# Email configuration
SMTP_HOST="${SMTP_HOST:-localhost}"
SMTP_PORT="${SMTP_PORT:-25}"
FROM_EMAIL="${FROM_EMAIL:-noreply@company.com}"
TO_EMAIL="${TO_EMAIL:-ops@company.com}"

# Slack webhook (optional)
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"

# Teams webhook (optional)
TEAMS_WEBHOOK="${TEAMS_WEBHOOK:-}"

# Color codes for status
case $STATUS in
    "success"|"SUCCESS")
        COLOR="good"
        EMOJI="✅"
        PRIORITY="low"
        ;;
    "failure"|"FAILED")
        COLOR="danger"
        EMOJI="❌"
        PRIORITY="high"
        ;;
    "warning"|"WARNING")
        COLOR="warning"
        EMOJI="⚠️"
        PRIORITY="medium"
        ;;
    *)
        COLOR="#439FE0"
        EMOJI="ℹ️"
        PRIORITY="low"
        ;;
esac

# Get additional information
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
BUILD_NUMBER="${BUILD_NUMBER:-N/A}"
GIT_COMMIT="${GIT_COMMIT:-N/A}"
JOB_NAME="${JOB_NAME:-Manual Execution}"

# Create HTML email body
create_html_email() {
    cat << EOF
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: $([ "$STATUS" = "success" ] && echo "#28a745" || echo "#dc3545"); 
                  color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f8f9fa; }
        .detail { margin: 10px 0; }
        .label { font-weight: bold; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #6c757d; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$EMOJI CI/CD Notification</h1>
            <h2>Status: $STATUS</h2>
        </div>
        <div class="content">
            <div class="detail">
                <span class="label">Environment:</span> $ENVIRONMENT
            </div>
            <div class="detail">
                <span class="label">Job Name:</span> $JOB_NAME
            </div>
            <div class="detail">
                <span class="label">Build Number:</span> $BUILD_NUMBER
            </div>
            <div class="detail">
                <span class="label">Timestamp:</span> $TIMESTAMP
            </div>
            <div class="detail">
                <span class="label">Host:</span> $HOSTNAME
            </div>
            <div class="detail">
                <span class="label">Git Commit:</span> $GIT_COMMIT
            </div>
            <div class="detail">
                <span class="label">Message:</span> $MESSAGE
            </div>
        </div>
        <div class="footer">
            <p>This is an automated notification from the CI/CD system.</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Send email notification
send_email() {
    local subject="[$STATUS] $ENVIRONMENT - $JOB_NAME"
    local html_body=$(create_html_email)
    
    echo "$html_body" | mail -s "$subject" \
        -a "Content-Type: text/html" \
        -a "From: $FROM_EMAIL" \
        -r "$FROM_EMAIL" \
        "$TO_EMAIL"
    
    echo "Email sent to $TO_EMAIL"
}

# Send Slack notification
send_slack() {
    if [ -n "$SLACK_WEBHOOK" ]; then
        local payload=$(cat <<EOF
{
    "attachments": [
        {
            "color": "$COLOR",
            "title": "$EMOJI CI/CD Notification",
            "fields": [
                {
                    "title": "Status",
                    "value": "$STATUS",
                    "short": true
                },
                {
                    "title": "Environment",
                    "value": "$ENVIRONMENT",
                    "short": true
                },
                {
                    "title": "Job",
                    "value": "$JOB_NAME",
                    "short": true
                },
                {
                    "title": "Build",
                    "value": "$BUILD_NUMBER",
                    "short": true
                },
                {
                    "title": "Message",
                    "value": "$MESSAGE",
                    "short": false
                }
            ],
            "footer": "CI/CD System",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
        
        curl -X POST -H 'Content-type: application/json' \
            --data "$payload" \
            "$SLACK_WEBHOOK"
        
        echo "Slack notification sent"
    fi
}

# Send Teams notification
send_teams() {
    if [ -n "$TEAMS_WEBHOOK" ]; then
        local payload=$(cat <<EOF
{
    "@type": "MessageCard",
    "@context": "https://schema.org/extensions",
    "summary": "CI/CD Notification",
    "themeColor": "$([ "$STATUS" = "success" ] && echo "28a745" || echo "dc3545")",
    "title": "$EMOJI CI/CD Notification - $STATUS",
    "sections": [
        {
            "facts": [
                {
                    "name": "Environment:",
                    "value": "$ENVIRONMENT"
                },
                {
                    "name": "Job:",
                    "value": "$JOB_NAME"
                },
                {
                    "name": "Build:",
                    "value": "$BUILD_NUMBER"
                },
                {
                    "name": "Timestamp:",
                    "value": "$TIMESTAMP"
                },
                {
                    "name": "Message:",
                    "value": "$MESSAGE"
                }
            ]
        }
    ]
}
EOF
)
        
        curl -X POST -H 'Content-type: application/json' \
            --data "$payload" \
            "$TEAMS_WEBHOOK"
        
        echo "Teams notification sent"
    fi
}

# Main execution
echo "=========================================="
echo "Sending notifications"
echo "Status: $STATUS"
echo "Environment: $ENVIRONMENT"
echo "=========================================="

send_email
send_slack
send_teams

echo "All notifications sent successfully"
