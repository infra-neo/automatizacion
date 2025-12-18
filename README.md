# 🚀 Automatización e Infraestructura CI/CD Completa

## 📋 Descripción General

Este repositorio contiene una **infraestructura CI/CD completa y lista para producción** para aplicaciones Java (Maven, JBoss/Wildfly) con integración de herramientas industriales estándar y mejores prácticas de seguridad.

### Características Principales

✅ **CI/CD Completo**: GitLab CI/CD + Jenkins + Semaphore con pipelines automatizados  
✅ **Gestión de Secretos**: HashiCorp Vault para manejo seguro de credenciales  
✅ **Repositorio de Artefactos**: Nexus separado por ambientes (QA, Staging, Production)  
✅ **Análisis de Código**: SonarQube con escaneo de seguridad y calidad  
✅ **Monitoreo**: Grafana + Prometheus + Loki para métricas y logs  
✅ **Automatización**: Ansible blueprints para rsyslog, logrotate, GLPI, Zabbix  
✅ **Gestión de Inventario**: GLPI con FusionInventory para asset management  
✅ **Servidor de Aplicaciones**: Wildfly para despliegue de aplicaciones Java  
✅ **Ansible UI**: Semaphore para gestión visual de playbooks  
✅ **Seguridad**: Escaneo de secretos, OWASP Dependency Check, análisis SAST  
✅ **Notificaciones**: Email, Slack, Teams integrados  
✅ **Docker**: Infraestructura completa containerizada  

## 🏗️ Arquitectura

### Ambientes Soportados
- **QA**: Desarrollo y pruebas de calidad
- **Staging**: Validación pre-producción
- **Production**: Ambiente productivo (altamente seguro)

### Herramientas Integradas
- **GitLab**: Control de versiones y orquestación CI/CD
- **Jenkins**: Automatización de builds y despliegues
- **Semaphore**: UI web para gestión de Ansible
- **Nexus**: Gestión de artefactos Maven por ambiente
- **SonarQube**: Análisis de calidad y seguridad de código
- **HashiCorp Vault**: Gestión centralizada de secretos
- **Grafana**: Dashboards de monitoreo
- **Loki**: Agregación de logs
- **Prometheus**: Recolección de métricas
- **Ansible**: Gestión de configuración
- **GLPI**: Sistema de gestión de inventario IT
- **Wildfly**: Servidor de aplicaciones Java EE
- **Zabbix**: Monitoreo de infraestructura (agente)

## 📁 Estructura del Repositorio

```
automatizacion/
├── .gitlab-ci.yml              # Pipeline GitLab CI/CD
├── ansible-blueprints/         # Blueprints Ansible
│   ├── rsyslog/               # Configuración y validación rsyslog
│   ├── logrotate/             # Configuración y validación logrotate
│   ├── glpi-agent/           # Agente GLPI para inventario
│   ├── zabbix/               # Agente Zabbix para monitoreo
│   ├── process-monitoring/    # Monitoreo de procesos
│   └── disk-monitoring/       # Monitoreo de disco
├── config-repos/              # Configuraciones por ambiente
│   ├── qa/
│   ├── staging/
│   └── production/
├── docker/                    # Docker Compose
├── gitlab/                    # Configuración GitLab
├── jenkins/                   # Pipelines Jenkins
├── nexus/                     # Configuración Nexus
├── vault/                     # Configuración Vault
├── grafana/                   # Dashboards Grafana
├── loki/                      # Configuración Loki
├── scripts/                   # Scripts de utilidad
├── docs/                      # Documentación completa
└── notifications/             # Plantillas de notificaciones
```

## 🚀 Inicio Rápido

### Requisitos Previos
- Docker y Docker Compose
- Git
- JDK 17 o 18
- Maven 3.9+
- Ansible 2.9+

### 1. Clonar Repositorio
```bash
git clone https://github.com/infra-neo/automatizacion.git
cd automatizacion
```

### 2. Iniciar Infraestructura CI/CD
```bash
cd docker
docker-compose up -d
```

### 3. Acceder a las Herramientas

Después de iniciar, accede a:

- **Jenkins**: http://localhost:8080
- **Semaphore**: http://localhost:3001 (admin/admin)
- **Nexus**: http://localhost:8081
- **SonarQube**: http://localhost:9000
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Vault**: http://localhost:8200
- **GLPI**: http://localhost:8888
- **Wildfly**: http://localhost:8090 (Management: 9990)

### 4. Configuración Inicial

Ver [Documentación Completa](docs/README_COMPLETE.md) para configuración detallada.

## 🔐 Seguridad

### Gestión de Secretos
Todos los datos sensibles se almacenan en **HashiCorp Vault**:
```bash
# Almacenar secreto
vault kv put secret/qa/database password="secret123"

# Recuperar en pipeline
vault kv get -field=password secret/qa/database
```

### Escaneo de Seguridad
- **Escaneo de secretos**: Previene commits con datos sensibles
- **SonarQube**: Análisis estático de seguridad
- **OWASP Dependency Check**: Escaneo de vulnerabilidades
- **GitLab Secret Detection**: Detección automática de secretos

### Control de Acceso

#### Grupo "implementacion"
- Acceso completo a todos los ambientes
- Puede desplegar a staging y producción
- Gestiona secretos y configuraciones

#### Grupo "developers"
- Acceso a ambiente QA
- Crea merge requests
- No puede desplegar a producción

## 📊 Monitoreo y Logs

### Grafana Dashboards
- Métricas de pipelines CI/CD
- Performance de aplicaciones
- Salud de infraestructura
- Resultados de escaneos de seguridad

### Loki - Agregación de Logs
```logql
# Ver logs de aplicación
{job="application", environment="production"}

# Filtrar errores
{job="application"} |= "ERROR"

# Logs de despliegue
{job="cicd"} |= "deployment"
```

## 🤖 Automatización con Ansible

### Blueprints Disponibles

```bash
# Configuración y Validación de Servicios
ansible-playbook ansible-blueprints/rsyslog/configure-rsyslog.yml
ansible-playbook ansible-blueprints/rsyslog/validate-rsyslog.yml
ansible-playbook ansible-blueprints/logrotate/configure-logrotate.yml
ansible-playbook ansible-blueprints/logrotate/validate-logrotate.yml

# Gestión de Inventario
ansible-playbook ansible-blueprints/glpi-agent/configure-glpi-agent.yml
ansible-playbook ansible-blueprints/zabbix/configure-zabbix-agent.yml

# Monitoreo de Sistema
ansible-playbook ansible-blueprints/process-monitoring/monitor-processes.yml
ansible-playbook ansible-blueprints/disk-monitoring/monitor-disk-space.yml
```

## 🏭 Despliegue a Producción

### Requisitos
1. Aprobación de 2 miembros del grupo "implementacion"
2. Todas las pruebas pasando
3. Escaneos de seguridad aprobados
4. Code review completado
5. Validación en staging exitosa

### Proceso
```bash
# 1. Merge a branch de producción
git checkout production
git merge staging
git push origin production

# 2. Pipeline crea paquete de despliegue
# 3. Aprobación manual requerida
# 4. Despliegue automatizado con rollback
# 5. Verificación post-despliegue
# 6. Notificación a stakeholders
```

## 📖 Documentación Completa

### Guías de Implementación
- [Guía de Implementación Completa](docs/IMPLEMENTATION_GUIDE.md) - **NUEVO**
- [Guía Completa Original](docs/README_COMPLETE.md)
- [Inicio Rápido](docs/QUICKSTART.md)

### Ansible y Automatización
- [Documentación de Playbooks Ansible](docs/ANSIBLE_PLAYBOOKS.md) - **NUEVO**
- [Pipelines de Jenkins](docs/JENKINS_PIPELINES.md) - **NUEVO**

### Servicios Docker
- [Servicios Docker](docs/DOCKER_SERVICES.md) - **NUEVO**
- [Docker Setup Original](docker/README.md)

### Integración y Monitoreo
- [Integración GLPI](docs/GLPI_INTEGRATION.md) - **NUEVO**
- [Configuración Grafana](grafana/GRAFANA_CONFIGURATION.md)
- [Configuración Loki](loki/LOKI_CONFIGURATION.md)

### Configuraciones Específicas
- [Configuración GitLab](gitlab/GITLAB_CONFIGURATION.md)
- [Configuración Nexus](nexus/NEXUS_CONFIGURATION.md)
- [Configuración Vault](vault/VAULT_CONFIGURATION.md)
- [Configuración SonarQube](sonarqube/SONARQUBE_CONFIGURATION.md)

### Otros
- [Seguridad](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Screenshots](docs/screenshots/README.md) - **NUEVO**

## 🛠️ Scripts de Utilidad

```bash
# Despliegue a Wildfly
./scripts/deploy-to-wildfly.sh <environment> <host> <port>

# Escaneo de secretos
./scripts/scan-secrets.sh

# Health check
./scripts/health-check.sh <environment>

# Enviar notificación
./scripts/send-notification.sh <status> <environment>
```

## 📧 Notificaciones

Notificaciones automáticas configuradas para:
- ✅ Build exitoso/fallido
- 🚀 Despliegues (QA, Staging, Production)
- 🔒 Vulnerabilidades de seguridad
- ⚠️ Fallos en quality gate
- 📊 Reportes diarios

## 🔄 Backup y Recuperación

### Backups Automatizados
- **Nexus**: Artefactos de producción (90 días retención)
- **Vault**: Secretos (backups encriptados)
- **Grafana**: Dashboards y configuraciones
- **Repositorios**: Configuraciones por ambiente

## 👥 Contribución

1. Crear feature branch desde `develop`
2. Realizar cambios y commits
3. Crear merge request a `develop`
4. Pipeline CI/CD ejecuta automáticamente
5. Code review por peer developer
6. Merge después de aprobación

## 📞 Soporte

- Issues: Crear en GitLab
- Contacto: equipo infra-neo
- Documentación: Ver carpeta `docs/`

## 📄 Licencia

Uso interno - Propiedad de la empresa

---

**Desarrollado por infra-neo** | CI/CD Completo para Java/Maven/Wildfly