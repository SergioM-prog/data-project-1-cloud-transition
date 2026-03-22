#!/bin/bash
set -e  # Detener el script si cualquier comando falla

# =============================================================================
# CONFIGURACIÓN — se lee del perfil activo de gcloud
# =============================================================================

PROJECT_ID=$(gcloud config get-value project)
REGION=$(gcloud config get-value compute/region)
REPO="$REGION-docker.pkg.dev/$PROJECT_ID/air-quality"

echo ""
echo "Proyecto : $PROJECT_ID"
echo "Región   : $REGION"
echo "Repo     : $REPO"
echo ""
read -p "¿Continuar con el despliegue en este proyecto y región? (s/n): " CONFIRM
[ "$CONFIRM" != "s" ] && echo "Cancelado." && exit 1

# =============================================================================
# GENERAR terraform.tfvars
# =============================================================================

cat > envs/dev/terraform.tfvars <<EOF
project_id = "$PROJECT_ID"
region     = "$REGION"
EOF

echo "terraform.tfvars generado."

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
echo ">>> FASE 1: Desplegando infraestructura base..."
cd envs/dev
terraform init -upgrade
terraform apply

cd ../..

echo ""
echo "Fase 1 completada. Infraestructura base lista."
