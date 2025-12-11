#!/bin/bash

# Script to setup and start the complete migration environment

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   JBoss to WildFly Migration Environment Setup                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker is installed: $(docker --version)"
echo "✅ Docker Compose is installed: $(docker-compose --version)"
echo ""

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p reports/{migration,metrics,comparison,executive,pipeline}
mkdir -p backups
echo "✅ Directories created"
echo ""

# Start services
echo "🚀 Starting Docker services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
echo "   This may take 2-3 minutes..."
echo ""

# Wait for Nexus
echo "   Waiting for Nexus Repository..."
timeout 180 bash -c 'until curl -sf http://localhost:8081/ > /dev/null 2>&1; do sleep 5; done' && echo "   ✅ Nexus is ready" || echo "   ⚠️  Nexus timeout (may still be starting)"

# Wait for PostgreSQL
echo "   Waiting for PostgreSQL..."
timeout 60 bash -c 'until docker exec postgres-db pg_isready -U appuser > /dev/null 2>&1; do sleep 2; done' && echo "   ✅ PostgreSQL is ready" || echo "   ⚠️  PostgreSQL timeout"

# Wait for JBoss
echo "   Waiting for JBoss Source..."
timeout 180 bash -c 'until curl -sf http://localhost:8080/ > /dev/null 2>&1; do sleep 10; done' && echo "   ✅ JBoss Source is ready" || echo "   ⚠️  JBoss timeout (may still be starting)"

# Wait for WildFly
echo "   Waiting for WildFly Target..."
timeout 180 bash -c 'until curl -sf http://localhost:8180/ > /dev/null 2>&1; do sleep 10; done' && echo "   ✅ WildFly Target is ready" || echo "   ⚠️  WildFly timeout (may still be starting)"

echo ""
echo "✅ Environment setup complete!"
echo ""

# Display service status
echo "════════════════════════════════════════════════════════════════"
echo "📊 Service Status"
echo "════════════════════════════════════════════════════════════════"
docker-compose ps
echo ""

# Display access information
echo "════════════════════════════════════════════════════════════════"
echo "🌐 Access URLs"
echo "════════════════════════════════════════════════════════════════"
echo "JBoss Source (Java 1.7):"
echo "  - Application: http://localhost:8080"
echo "  - Management:  http://localhost:9990"
echo "  - Credentials: admin / admin123"
echo ""
echo "WildFly Target (Java 21):"
echo "  - Application: http://localhost:8180"
echo "  - Management:  http://localhost:9991"
echo "  - Credentials: admin / admin123"
echo ""
echo "Nexus Repository:"
echo "  - URL: http://localhost:8081"
echo "  - Credentials: admin / (see container logs for initial password)"
echo ""
echo "Grafana Dashboards:"
echo "  - URL: http://localhost:3000"
echo "  - Credentials: admin / admin123"
echo ""
echo "Prometheus Metrics:"
echo "  - URL: http://localhost:9090"
echo ""
echo "SonarQube:"
echo "  - URL: http://localhost:9000"
echo "  - Credentials: admin / admin"
echo ""
echo "PostgreSQL Database:"
echo "  - Host: localhost:5432"
echo "  - Database: testdb"
echo "  - Credentials: appuser / apppass123"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📝 Next Steps"
echo "════════════════════════════════════════════════════════════════"
echo "1. Build applications:"
echo "   cd sample-apps/app1-rest-api && mvn clean package"
echo ""
echo "2. Deploy to JBoss:"
echo "   docker cp target/app1-rest-api.war jboss-source-env:/opt/jboss/standalone/deployments/"
echo ""
echo "3. Deploy to WildFly:"
echo "   docker cp target/app1-rest-api.war wildfly-target-env:/opt/jboss/wildfly/standalone/deployments/"
echo ""
echo "4. Test applications:"
echo "   curl http://localhost:8080/app1-rest-api/api/users/health"
echo "   curl http://localhost:8180/app1-rest-api/api/users/health"
echo ""
echo "5. View logs:"
echo "   docker-compose logs -f jboss-source"
echo "   docker-compose logs -f wildfly-target"
echo ""
echo "6. Stop environment:"
echo "   docker-compose down"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ Setup complete! Environment is ready for testing."
echo "════════════════════════════════════════════════════════════════"
