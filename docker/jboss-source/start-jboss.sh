#!/bin/bash

echo "Starting JBoss EAP (Source Environment)..."

# Add admin user
${JBOSS_HOME}/bin/add-user.sh ${JBOSS_USER:-admin} ${JBOSS_PASS:-admin123} --silent

# Start JBoss in standalone mode
exec ${JBOSS_HOME}/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0
