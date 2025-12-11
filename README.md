# JBoss to WildFly Migration - Automated Test Environment

## 🎯 Descripción del Proyecto

Este proyecto implementa un **ambiente completo de pruebas automatizadas** para simular y ejecutar el proceso de migración de aplicaciones Java desde JBoss EAP 6.4 (Java 1.7) hacia WildFly 31 (Java 21), utilizando GitHub Actions como plataforma de CI/CD.

## 🏗️ Arquitectura del Sistema

### Ambientes de Prueba

El proyecto incluye **dos ambientes completos** corriendo en contenedores Docker:

#### 🔴 Ambiente Origen (Legacy)
- **Servidor**: JBoss EAP 6.4 / WildFly 10
- **Java**: OpenJDK 1.7
- **Base OS**: Red Hat UBI 7
- **Puerto**: 8080 (HTTP), 9990 (Management)

#### 🟢 Ambiente Destino (Moderno)
- **Servidor**: WildFly 31
- **Java**: OpenJDK 21
- **Base OS**: Red Hat UBI 9
- **Puerto**: 8180 (HTTP), 9991 (Management)

### 📦 Infraestructura de Soporte

| Servicio | Propósito | Puerto |
|----------|-----------|--------|
| **Nexus Repository** | Repositorio local de dependencias Maven | 8081 |
| **PostgreSQL** | Base de datos para aplicaciones | 5432 |
| **Prometheus** | Recolección de métricas | 9090 |
| **Grafana** | Dashboards y visualización | 3000 |
| **SonarQube** | Análisis de calidad de código | 9000 |

## 📱 Aplicaciones de Prueba

Se incluyen **5 aplicaciones Java** para validar diferentes aspectos de la migración:

1. **App1 - REST API** (`app1-rest-api`)
   - API RESTful con JAX-RS
   - Persistencia JPA con PostgreSQL
   - CRUD de usuarios

2. **App2 - JMS Messaging** (`app2-jms`)
   - Mensajería asíncrona
   - Procesamiento de colas
   - ActiveMQ integration

3. **App3 - EJB** (`app3-ejb`)
   - Enterprise Java Beans
   - Transacciones distribuidas
   - Business logic layer

4. **App4 - JSF Web** (`app4-web-jsf`)
   - Interfaz web con JavaServer Faces
   - Managed beans
   - Web forms

5. **App5 - Batch Processing** (`app5-batch`)
   - Procesamiento por lotes
   - Batch jobs
   - Scheduled tasks

## 🔄 Pipeline de Migración

### Workflow Principal: Master Pipeline

```bash
# Ejecutar pipeline completo
gh workflow run 00-master-pipeline.yml
```

El pipeline ejecuta 5 stages automatizados:

### Stage 1: Environment Setup
**Workflow**: `01-environment-setup.yml`

- ✅ Inicializa todos los contenedores Docker
- ✅ Configura Nexus con repositorios Maven
- ✅ Inicializa base de datos PostgreSQL
- ✅ Verifica health de todos los servicios
- 📄 Genera reporte de ambiente

### Stage 2: Build and Test (Source)
**Workflow**: `02-build-test-source.yml`

- ✅ Compila aplicaciones con Java 1.7
- ✅ Ejecuta unit tests
- ✅ Análisis de calidad con SonarQube
- ✅ Escaneo de seguridad (OWASP)
- ✅ Genera reportes de dependencias
- 📄 Reporte de compilación

### Stage 3: Migration Analysis
**Workflow**: `03-migration-analysis.yml`

- ✅ Ejecuta JBoss Migration Toolkit (Windup)
- ✅ Analiza compatibilidad de APIs
- ✅ Identifica cambios necesarios
- ✅ Estima esfuerzo de migración
- ✅ Genera plan de migración
- 📄 Reporte de análisis detallado

### Stage 4: Migration and Deployment
**Workflow**: `04-migration-deployment.yml`

- ✅ Backup de deployment actual
- ✅ Compila con Java 21 para WildFly
- ✅ Deploy automático a WildFly
- ✅ Smoke tests
- ✅ Integration tests
- ✅ Performance tests
- ✅ Security scanning
- ✅ Versionamiento de artefactos
- 📄 Reporte de deployment

### Stage 5: Monitoring and Reporting
**Workflow**: `05-monitoring-reporting.yml`

- ✅ Recolección de métricas de Prometheus
- ✅ Actualización de dashboards Grafana
- ✅ Comparación de ambientes
- ✅ Análisis de ROI
- 📄 Executive Summary

## 🚀 Inicio Rápido

### Prerrequisitos

- Docker & Docker Compose
- Git
- GitHub account (para workflows)

### 1. Clonar el Repositorio

```bash
git clone https://github.com/infra-neo/automatizacion.git
cd automatizacion
```

### 2. Iniciar Ambiente Local

```bash
# Levantar todos los servicios
docker-compose up -d

# Verificar estado
docker-compose ps

# Ver logs
docker-compose logs -f
```

### 3. Acceder a los Servicios

Una vez iniciados los contenedores:

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| JBoss Management | http://localhost:9990 | admin / admin123 |
| WildFly Management | http://localhost:9991 | admin / admin123 |
| Nexus Repository | http://localhost:8081 | admin / admin123 |
| Grafana | http://localhost:3000 | admin / admin123 |
| Prometheus | http://localhost:9090 | - |
| SonarQube | http://localhost:9000 | admin / admin |

### 4. Compilar y Desplegar Aplicaciones

```bash
# Compilar app1
cd sample-apps/app1-rest-api
mvn clean package

# Copiar WAR a JBoss
docker cp target/app1-rest-api.war jboss-source-env:/opt/jboss/standalone/deployments/

# Copiar WAR a WildFly
docker cp target/app1-rest-api.war wildfly-target-env:/opt/jboss/wildfly/standalone/deployments/
```

### 5. Probar Aplicaciones

```bash
# Probar en JBoss (puerto 8080)
curl http://localhost:8080/app1-rest-api/api/users/health

# Probar en WildFly (puerto 8180)
curl http://localhost:8180/app1-rest-api/api/users/health

# Listar usuarios
curl http://localhost:8080/app1-rest-api/api/users
```

## 🔧 Estructura del Proyecto

```
automatizacion/
├── .github/
│   └── workflows/              # GitHub Actions workflows
│       ├── 00-master-pipeline.yml
│       ├── 01-environment-setup.yml
│       ├── 02-build-test-source.yml
│       ├── 03-migration-analysis.yml
│       ├── 04-migration-deployment.yml
│       └── 05-monitoring-reporting.yml
├── docker/
│   ├── jboss-source/          # JBoss EAP 6.4 container
│   │   ├── Dockerfile
│   │   ├── standalone.xml
│   │   └── start-jboss.sh
│   ├── wildfly-target/        # WildFly 31 container
│   │   ├── Dockerfile
│   │   ├── standalone.xml
│   │   └── start-wildfly.sh
│   ├── database/
│   │   └── init/              # SQL initialization scripts
│   └── monitoring/
│       ├── prometheus.yml
│       └── grafana/
├── sample-apps/
│   ├── app1-rest-api/         # REST API application
│   ├── app2-jms/              # JMS messaging app
│   ├── app3-ejb/              # EJB application
│   ├── app4-web-jsf/          # JSF web app
│   └── app5-batch/            # Batch processing
├── scripts/                    # Utility scripts
├── reports/                    # Generated reports
└── docker-compose.yml         # Orchestration file
```

## 📊 Reportes Generados

Cada ejecución del pipeline genera múltiples reportes:

1. **Environment Setup Report**
   - Estado de servicios
   - Configuración de red
   - Health checks

2. **Build Report**
   - Resultados de compilación
   - Cobertura de tests
   - Dependencias utilizadas

3. **Migration Analysis Report**
   - Análisis de compatibilidad
   - Issues identificados
   - Plan de migración
   - Estimación de esfuerzo

4. **Deployment Summary**
   - Pasos de deployment
   - Resultados de tests
   - Métricas de performance

5. **Executive Summary**
   - Overview del proyecto
   - ROI y beneficios
   - Recomendaciones
   - Next steps

## 🎯 Características Principales

### ✅ Ambiente Sin Internet

- Nexus actúa como proxy/mirror de Maven Central
- Todas las dependencias se cachean localmente
- Simula ambiente corporativo real sin acceso a internet

### ✅ CI/CD Completo

- Pipeline totalmente automatizado
- Build, test, deploy en un solo comando
- Integración continua con GitHub Actions

### ✅ Monitoreo en Tiempo Real

- Métricas de aplicación con Prometheus
- Dashboards visuales con Grafana
- Comparación de ambientes

### ✅ Análisis de Migración

- JBoss Migration Toolkit (Windup)
- Detección automática de incompatibilidades
- Generación de plan de trabajo

### ✅ Testing Completo

- Unit tests
- Integration tests
- Performance tests
- Security scanning
- Smoke tests

### ✅ Gestión de Dependencias

- Nexus Repository Manager
- Repositorio local de JARs
- Control de versiones

## 🔐 Seguridad

- Escaneo OWASP Dependency Check
- Análisis de vulnerabilidades
- OWASP ZAP para pentesting
- SonarQube para code quality

## 📈 Métricas y KPIs

El sistema monitorea:

- **Performance**: Response time, throughput
- **Resources**: CPU, memoria, disco
- **Application**: Request rate, error rate
- **Database**: Connections, query time
- **JVM**: Heap, GC, threads

## 🛠️ Comandos Útiles

### Docker

```bash
# Ver logs de un servicio
docker-compose logs -f jboss-source

# Reiniciar un servicio
docker-compose restart wildfly-target

# Acceder a un contenedor
docker exec -it jboss-source-env bash

# Detener todo
docker-compose down

# Limpiar volúmenes
docker-compose down -v
```

### Maven

```bash
# Compilar sin tests
mvn clean package -DskipTests

# Solo tests
mvn test

# Con repositorio Nexus
mvn clean install -s settings.xml
```

### PostgreSQL

```bash
# Conectar a la base de datos
docker exec -it postgres-db psql -U appuser -d testdb

# Ver tablas
\dt

# Salir
\q
```

## 🐛 Troubleshooting

### Nexus no inicia

```bash
# Aumentar memoria para Nexus
docker-compose stop nexus
# Editar docker-compose.yml: aumentar -Xmx512m a -Xmx1024m
docker-compose up -d nexus
```

### JBoss/WildFly no despliega

```bash
# Verificar logs
docker-compose logs jboss-source

# Verificar deployment directory
docker exec jboss-source-env ls -la /opt/jboss/standalone/deployments/
```

### Base de datos no conecta

```bash
# Verificar que PostgreSQL esté corriendo
docker-compose ps postgres

# Verificar conexión
docker exec postgres-db pg_isready -U appuser
```

## 📚 Documentación Adicional

- [JBoss Migration Guide](docs/jboss-migration-guide.md)
- [Nexus Configuration](docs/nexus-setup.md)
- [Monitoring Setup](docs/monitoring-guide.md)
- [Application Development](docs/app-development.md)

## 🤝 Contribuciones

Este es un proyecto de demostración para ambiente de pruebas de migración.

## 📝 Licencia

Este proyecto es de uso educativo y demostración.

## 👥 Autor

Equipo de Automatización - infra-neo

---

## 🎓 Resumen Ejecutivo

Este proyecto demuestra una **solución completa end-to-end** para:

1. ✅ Simular ambientes reales de producción sin internet
2. ✅ Automatizar el proceso completo de migración JBoss → WildFly
3. ✅ Validar compatibilidad y funcionamiento
4. ✅ Generar reportes detallados de análisis y deployment
5. ✅ Monitorear y comparar ambientes
6. ✅ Proveer métricas de ROI y beneficios

**Status**: ✅ Listo para pruebas

**Última actualización**: 2025-12-11