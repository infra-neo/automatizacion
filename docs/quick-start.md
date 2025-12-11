# Quick Start Guide - Migración JBoss a WildFly

## 🚀 Inicio Rápido (5 minutos)

### Paso 1: Clonar y Preparar (1 min)

```bash
# Clonar el repositorio
git clone https://github.com/infra-neo/automatizacion.git
cd automatizacion

# Dar permisos de ejecución
chmod +x scripts/*.sh
```

### Paso 2: Levantar Ambiente (2 min)

```bash
# Opción A: Usando el script automático
./scripts/setup-environment.sh

# Opción B: Manual con Docker Compose
docker-compose up -d
```

**Esperar 2-3 minutos** mientras los servicios se inicializan.

### Paso 3: Verificar Servicios (1 min)

```bash
# Verificar que todos estén corriendo
docker-compose ps

# Probar conectividad
curl http://localhost:8080  # JBoss
curl http://localhost:8180  # WildFly
curl http://localhost:8081  # Nexus
curl http://localhost:3000  # Grafana
```

### Paso 4: Compilar Aplicaciones (1 min)

```bash
# Compilar App1
cd sample-apps/app1-rest-api
mvn clean package -DskipTests
cd ../..
```

### Paso 5: Probar (30 seg)

```bash
# Desplegar en JBoss
docker cp sample-apps/app1-rest-api/target/app1-rest-api.war \
  jboss-source-env:/opt/jboss/standalone/deployments/

# Esperar 10 segundos y probar
sleep 10
curl http://localhost:8080/app1-rest-api/api/users/health

# Desplegar en WildFly
docker cp sample-apps/app1-rest-api/target/app1-rest-api.war \
  wildfly-target-env:/opt/jboss/wildfly/standalone/deployments/

# Probar
sleep 10
curl http://localhost:8180/app1-rest-api/api/users/health
```

## ✅ ¡Listo!

Tu ambiente de pruebas está funcionando. Ahora puedes:

### Ver Interfaces Web

- **Grafana**: http://localhost:3000 (admin/admin123)
- **Nexus**: http://localhost:8081
- **JBoss Admin**: http://localhost:9990 (admin/admin123)
- **WildFly Admin**: http://localhost:9991 (admin/admin123)

### Ejecutar Pipeline Completo

```bash
# Si tienes GitHub CLI instalado
gh workflow run 00-master-pipeline.yml
```

### Probar APIs

```bash
# Listar usuarios
curl http://localhost:8080/app1-rest-api/api/users
curl http://localhost:8180/app1-rest-api/api/users

# Crear usuario
curl -X POST http://localhost:8080/app1-rest-api/api/users \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com"}'
```

## 🛑 Detener Ambiente

```bash
# Detener servicios
docker-compose down

# Limpiar todo (incluyendo volúmenes)
docker-compose down -v
```

## 📚 Siguiente Paso

Lee la [Guía de Pruebas](testing-guide.md) para casos de prueba completos.

## ❓ Problemas Comunes

### Puerto ya en uso

```bash
# Verificar qué está usando el puerto
lsof -i :8080
lsof -i :8180

# Detener el proceso o cambiar puertos en docker-compose.yml
```

### Servicios no inician

```bash
# Ver logs
docker-compose logs -f

# Reiniciar servicio específico
docker-compose restart jboss-source
```

### No hay espacio en disco

```bash
# Limpiar imágenes no usadas
docker system prune -a

# Ver uso de espacio
docker system df
```

---

**¡Todo listo para migración!** 🎉
