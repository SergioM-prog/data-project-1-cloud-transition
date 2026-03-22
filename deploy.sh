#!/bin/bash
set -e  # Detener el script si cualquier comando falla

# =============================================================================
# SELECCIÓN DE ENTORNO
# =============================================================================

echo ""
echo "========================================"
echo "  Air Quality Valencia                  "
echo "  Despliegue de Serverless Pipeline     "
echo "========================================"
echo ""
read -p "¿Qué entorno quieres desplegar? (ej: dev, prod): " ENV

# Validar que el usuario ha introducido un valor
if [ -z "$ENV" ]; then
  echo "Error: Debes especificar un entorno."
  exit 1
fi

# Validar que la carpeta del entorno existe
if [ ! -d "envs/$ENV" ]; then
  echo "Error: El entorno 'envs/$ENV' no existe. Crea la carpeta primero."
  exit 1
fi

# =============================================================================
# CONFIGURACIÓN — se lee del perfil activo de gcloud
# =============================================================================

PROJECT_ID=$(gcloud config get-value project)
REGION=$(gcloud config get-value compute/region)
REPO="$REGION-docker.pkg.dev/$PROJECT_ID/air-quality"

echo ""
echo "Entorno  : $ENV"
echo "Proyecto : $PROJECT_ID"
echo "Región   : $REGION"
echo "Repo     : $REPO"
echo ""
read -p "¿Continuar con el despliegue en este proyecto y región? (s/n): " CONFIRM

# Validar la confirmación del usuario
if [ "$CONFIRM" != "s" ]; then
  echo "Cancelado."
  exit 1
fi

# =============================================================================
# GENERAR terraform.tfvars dinámicamente en el entorno elegido
# =============================================================================

cat > envs/$ENV/terraform.tfvars <<EOF
project_id = "$PROJECT_ID"
region     = "$REGION"
EOF

echo "terraform.tfvars generado en envs/$ENV/."

# =============================================================================
# FASE 0 — Activar APIs de GCP necesarias (idempotente)
# =============================================================================

echo ""
echo ">>> FASE 0: Activando APIs de GCP..."
gcloud services enable bigquery.googleapis.com --project=$PROJECT_ID

# =============================================================================
# FASE 1 — Terraform apply
# =============================================================================

echo ""
echo ">>> FASE 1: Desplegando infraestructura base para el entorno '$ENV'..."
# Navegamos a la carpeta del entorno que ha elegido el usuario
cd envs/$ENV

terraform init -upgrade
terraform apply

# Volvemos a la raíz (subimos dos niveles)
cd ../..

echo ""
echo "Fase 1 completada. Infraestructura base lista para el entorno '$ENV'."