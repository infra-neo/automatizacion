# Automatización End-to-End: API → SFTP → Email

## Descripción
Este proyecto automatiza la descarga diaria de archivos desde una API, los sube a un servidor SFTP y envía una notificación por correo electrónico. Incluye scripts en Python, Bash, Ansible y un blueprint para Semaphore CI/CD.

## Estructura del Proyecto

```
automation/           # Código Python principal y tests
ansible/              # Playbooks, roles y plantillas para despliegue
semaphore-blueprint.json  # Blueprint para CI/CD en Semaphore
README.md             # Este archivo
```

## Variables de Entorno
Configura las siguientes variables en tu entorno o en el archivo `.env`:

- `API_URL`, `API_CLIENT_ID`, `API_CLIENT_SECRET`
- `SFTP_HOST`, `SFTP_USER`, `SFTP_PRIVATE_KEY`
- `EMAIL_TO`, `EMAIL_FROM`, `EMAIL_SMTP`, `EMAIL_USER`, `EMAIL_PASSWORD`

## Despliegue con Ansible
1. Edita los archivos de inventario y variables en `ansible/inventories/production/` y `group_vars/all.yml`.
2. Personaliza las plantillas `.env.j2`, `run_manual.sh.j2`, y `run_daily.sh.j2` si es necesario.
3. Ejecuta:
	```bash
	ansible-playbook -i ansible/inventories/production/hosts ansible/playbooks/deploy_automation.yml
	```

## Ejecución Manual
En el servidor, ejecuta:
```bash
/opt/automation/run_manual.sh YYYY-MM-DD YYYY-MM-DD
```

## Ejecución Diaria (Automática)
El cron configurado ejecutará `/opt/automation/run_daily.sh` todos los días a las 2:00 AM.

## CI/CD con Semaphore
1. Sube el repositorio a tu proyecto en Semaphore.
2. Importa el archivo `semaphore-blueprint.json` como blueprint.
3. Configura las variables de entorno en Semaphore según la sección anterior.

## Pruebas
Incluye un placeholder en `automation/test_main.py`. Agrega tus tests según sea necesario.

## Contacto
infra-neo