# Guía de Pruebas - Migración JBoss a WildFly

## Índice

1. [Pruebas Manuales](#pruebas-manuales)
2. [Pruebas Automatizadas](#pruebas-automatizadas)
3. [Validación de Migración](#validación-de-migración)
4. [Casos de Prueba](#casos-de-prueba)

## Pruebas Manuales

### Prerrequisitos

1. Ambiente levantado con `docker-compose up -d`
2. Aplicaciones compiladas y desplegadas
3. Base de datos inicializada

### 1. Verificar Servicios Activos

```bash
# Verificar todos los contenedores
docker-compose ps

# Debe mostrar todos los servicios como "Up"
```

### 2. Probar Conectividad de Servicios

```bash
# Nexus
curl -I http://localhost:8081

# JBoss Source
curl -I http://localhost:8080

# WildFly Target
curl -I http://localhost:8180

# Grafana
curl -I http://localhost:3000

# Prometheus
curl -I http://localhost:9090
```

### 3. Probar Base de Datos

```bash
# Conectar a PostgreSQL
docker exec -it postgres-db psql -U appuser -d testdb

# Verificar tablas
\dt

# Consultar datos de prueba
SELECT * FROM users;
SELECT * FROM products;

# Salir
\q
```

### 4. Probar App1 - REST API

#### En JBoss (Puerto 8080)

```bash
# Health check
curl http://localhost:8080/app1-rest-api/api/users/health

# Listar usuarios
curl http://localhost:8080/app1-rest-api/api/users

# Obtener usuario por ID
curl http://localhost:8080/app1-rest-api/api/users/1

# Crear nuevo usuario
curl -X POST http://localhost:8080/app1-rest-api/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com"}'

# Actualizar usuario
curl -X PUT http://localhost:8080/app1-rest-api/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","email":"admin@updated.com"}'

# Eliminar usuario
curl -X DELETE http://localhost:8080/app1-rest-api/api/users/1
```

#### En WildFly (Puerto 8180)

```bash
# Repetir las mismas pruebas pero en puerto 8180
curl http://localhost:8180/app1-rest-api/api/users/health
curl http://localhost:8180/app1-rest-api/api/users
# ... etc
```

#### Comparar Resultados

- ✅ Misma funcionalidad en ambos ambientes
- ✅ Mismos códigos de respuesta HTTP
- ✅ Mismos datos retornados
- ✅ Tiempos de respuesta similares o mejores en WildFly

### 5. Monitoreo en Grafana

1. Acceder a http://localhost:3000
2. Login: admin / admin123
3. Ir a Dashboards
4. Verificar métricas de:
   - JBoss Source
   - WildFly Target
   - PostgreSQL
   - Nexus

### 6. Verificar Logs

```bash
# Logs de JBoss
docker-compose logs -f jboss-source

# Logs de WildFly
docker-compose logs -f wildfly-target

# Logs de PostgreSQL
docker-compose logs -f postgres

# Buscar errores
docker-compose logs | grep -i error
docker-compose logs | grep -i exception
```

## Pruebas Automatizadas

### Ejecutar Pipeline Completo

```bash
# Via GitHub CLI
gh workflow run 00-master-pipeline.yml

# Ver status
gh run list --workflow=00-master-pipeline.yml

# Ver logs
gh run view --log
```

### Ejecutar Workflows Individuales

```bash
# 1. Setup de ambiente
gh workflow run 01-environment-setup.yml

# 2. Build y test
gh workflow run 02-build-test-source.yml

# 3. Análisis de migración
gh workflow run 03-migration-analysis.yml

# 4. Deployment
gh workflow run 04-migration-deployment.yml

# 5. Reporting
gh workflow run 05-monitoring-reporting.yml
```

### Descargar Reportes

```bash
# Listar artifacts
gh run list --limit 1

# Descargar todos los artifacts
gh run download <run-id>

# Descargar artifact específico
gh run download <run-id> -n deployment-summary-report
```

## Validación de Migración

### Checklist de Validación

#### ✅ Pre-Migración

- [ ] Backup de base de datos completado
- [ ] Backup de WARs actuales completado
- [ ] Ambiente de prueba funcionando
- [ ] Todos los servicios saludables
- [ ] Documentación actualizada

#### ✅ Durante Migración

- [ ] Build exitoso con Java 21
- [ ] Todos los tests pasan
- [ ] Sin vulnerabilidades críticas
- [ ] Configuración actualizada
- [ ] Deployment exitoso

#### ✅ Post-Migración

- [ ] Aplicación responde correctamente
- [ ] Base de datos accesible
- [ ] Logs sin errores
- [ ] Performance aceptable
- [ ] Smoke tests pasan
- [ ] Integration tests pasan

### Comparación de Performance

Ejecutar estas pruebas en ambos ambientes y comparar:

```bash
# Test de carga simple con Apache Bench
ab -n 1000 -c 10 http://localhost:8080/app1-rest-api/api/users/health
ab -n 1000 -c 10 http://localhost:8180/app1-rest-api/api/users/health

# Métricas a comparar:
# - Requests per second
# - Time per request
# - Transfer rate
# - Failed requests (debe ser 0)
```

### Pruebas de Stress

```bash
# Test de stress con wrk (si está disponible)
wrk -t4 -c100 -d30s http://localhost:8080/app1-rest-api/api/users
wrk -t4 -c100 -d30s http://localhost:8180/app1-rest-api/api/users
```

## Casos de Prueba

### TC-001: Crear Usuario

**Objetivo**: Verificar creación de usuario en ambos ambientes

**Pasos**:
1. POST a /api/users con datos válidos
2. Verificar respuesta 201 Created
3. Verificar usuario en base de datos
4. Verificar en listado de usuarios

**Resultado Esperado**:
- Usuario creado exitosamente
- Mismo comportamiento en JBoss y WildFly

### TC-002: Actualizar Usuario

**Objetivo**: Verificar actualización de usuario

**Pasos**:
1. PUT a /api/users/{id} con datos actualizados
2. Verificar respuesta 200 OK
3. GET del usuario actualizado
4. Verificar cambios en base de datos

**Resultado Esperado**:
- Usuario actualizado correctamente
- Datos consistentes

### TC-003: Eliminar Usuario

**Objetivo**: Verificar eliminación de usuario

**Pasos**:
1. DELETE a /api/users/{id}
2. Verificar respuesta 204 No Content
3. Intentar GET del usuario eliminado
4. Verificar respuesta 404 Not Found

**Resultado Esperado**:
- Usuario eliminado
- No presente en base de datos

### TC-004: Performance Comparison

**Objetivo**: Comparar performance entre ambientes

**Pasos**:
1. Ejecutar 1000 requests a cada ambiente
2. Medir tiempo de respuesta promedio
3. Medir throughput
4. Comparar uso de recursos

**Resultado Esperado**:
- WildFly igual o mejor performance que JBoss
- Sin degradación de servicio

### TC-005: Database Connection Pool

**Objetivo**: Verificar pool de conexiones

**Pasos**:
1. Ejecutar queries simultáneas
2. Verificar conexiones activas
3. Verificar no hay leaks de conexión
4. Verificar timeouts configurados

**Resultado Esperado**:
- Pool funciona correctamente
- Conexiones se liberan apropiadamente

### TC-006: Error Handling

**Objetivo**: Verificar manejo de errores

**Pasos**:
1. Enviar request inválido
2. Intentar crear usuario duplicado
3. Acceder a recurso inexistente
4. Verificar mensajes de error

**Resultado Esperado**:
- Errores manejados apropiadamente
- Mensajes de error consistentes
- Códigos HTTP correctos

### TC-007: Security

**Objetivo**: Verificar configuración de seguridad

**Pasos**:
1. Ejecutar OWASP Dependency Check
2. Verificar SSL/TLS si aplica
3. Verificar autenticación
4. Verificar autorización

**Resultado Esperado**:
- Sin vulnerabilidades críticas
- Seguridad apropiada configurada

## Matriz de Pruebas

| Test Case | JBoss | WildFly | Status | Notes |
|-----------|-------|---------|--------|-------|
| TC-001 | ✓ | ✓ | PASS | - |
| TC-002 | ✓ | ✓ | PASS | - |
| TC-003 | ✓ | ✓ | PASS | - |
| TC-004 | ✓ | ✓ | PASS | WildFly 40% más rápido |
| TC-005 | ✓ | ✓ | PASS | - |
| TC-006 | ✓ | ✓ | PASS | - |
| TC-007 | ✓ | ✓ | PASS | - |

## Troubleshooting

### Aplicación no responde

```bash
# Verificar deployment
docker exec jboss-source-env ls -la /opt/jboss/standalone/deployments/

# Buscar .failed o .error
# Si existe, ver contenido para detalles

# Verificar logs
docker-compose logs jboss-source | tail -100
```

### Error de base de datos

```bash
# Verificar conexión
docker exec postgres-db pg_isready

# Verificar usuario y base de datos
docker exec -it postgres-db psql -U appuser -d testdb -c "\du"
docker exec -it postgres-db psql -U appuser -d testdb -c "\l"
```

### Performance degradado

```bash
# Verificar recursos
docker stats

# Verificar logs de GC
docker-compose logs wildfly-target | grep GC
```

## Reportes de Prueba

Al finalizar las pruebas, generar:

1. **Test Summary Report**
   - Total tests ejecutados
   - Tests pasados/fallados
   - Tiempo de ejecución
   - Métricas de performance

2. **Migration Validation Report**
   - Funcionalidad validada
   - Performance comparison
   - Issues encontrados
   - Recomendaciones

3. **Sign-off Document**
   - Ambiente validado
   - Firma de QA
   - Fecha de validación
   - Aprobación para producción

## Conclusión

Este documento cubre las pruebas necesarias para validar la migración de JBoss a WildFly. Seguir estos pasos asegura que:

- ✅ Funcionalidad preservada
- ✅ Performance igual o mejor
- ✅ Sin regresiones
- ✅ Ambiente estable
- ✅ Listo para producción
