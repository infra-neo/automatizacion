#!/bin/bash
# Script para automatizar el proceso en Red Hat
# Ejecuta el proceso principal de automatización

# Cargar variables de entorno desde archivo seguro (si existe)
if [ -f "../config.env" ]; then
    source ../config.env
fi

# Activar entorno virtual si existe (opcional)
if [ -f "../venv/bin/activate" ]; then
    source ../venv/bin/activate
fi

# Ejecutar el proceso principal
python3 main.py "$@"

# Guardar el código de salida
echo "Proceso finalizado con código $?"
