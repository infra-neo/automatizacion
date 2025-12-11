#!/bin/bash

echo "Starting WildFly (Target Environment)..."

# Add admin user
${WILDFLY_HOME}/bin/add-user.sh ${WILDFLY_USER:-admin} ${WILDFLY_PASS:-admin123} --silent

# Start WildFly in standalone mode
exec ${WILDFLY_HOME}/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0
