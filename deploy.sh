#!/bin/bash
set -e  # Detener el script si cualquier comando falla

# =============================================================================
# CONFIGURACIÓN — definición del nombre de la aplicación (Single Source of Truth)
# =============================================================================

APP_NAME="air-quality"

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
REPO="$REGION-docker.pkg.dev/$PROJECT_ID/$APP_NAME-$ENV"


echo ""
echo "Entorno  : $ENV"
echo "Proyecto : $PROJECT_ID"
echo "Región   : $REGION"
echo "Repo     : $REPO"
echo ""
read -p "¿Continuar con el despliegue en este proyecto y región? (yes/no): " CONFIRM

# Validar la confirmación del usuario
if [ "$CONFIRM" != "yes" ]; then
  echo "Cancelado."
  exit 1
fi

# =============================================================================
# GENERAR terraform.tfvars dinámicamente en el entorno elegido
# =============================================================================

# Iteramos sobre las carpetas de las capas
for LAYER in 00_base 01_app; do
  cat > envs/$ENV/terraform/$LAYER/terraform.tfvars <<EOF
project_id      = "$PROJECT_ID"
region          = "$REGION"
environment     = "$ENV"
app_name        = "$APP_NAME"
EOF
  echo "✅ terraform.tfvars generado en envs/$ENV/terraform/$LAYER."
done

# =============================================================================
# FASE 0 — Activar APIs de GCP necesarias (idempotente)
# =============================================================================

echo ""
echo ">>> FASE 0: Activando APIs de GCP..."
gcloud services enable \
        bigquery.googleapis.com \
        artifactregistry.googleapis.com \
        run.googleapis.com \
        cloudscheduler.googleapis.com \
        dataflow.googleapis.com \
        --project=$PROJECT_ID


# =============================================================================
# FASE 1 — Terraform apply base
# =============================================================================

echo ""
echo ">>> FASE 1: Desplegando infraestructura base para el entorno '$ENV'..."
# Navegamos a la carpeta del entorno que ha elegido el usuario
cd envs/$ENV/terraform/00_base

terraform init -upgrade

# Validar la sintaxis (Fail Fast)
echo "-> Validando código Terraform..."
if ! terraform validate; then
    echo "❌ ERROR: La validación de Terraform ha fallado. Revisa tus archivos .tf"
    exit 1
fi
echo "✅ Terraform validado correctamente."

# Exportar el plan
terraform plan -out=main.tfplan
terraform apply main.tfplan

# Volvemos a la raíz (subimos cuatro niveles)
cd ../../../..

echo ""
echo "Fase 1 completada. Infraestructura base lista para el entorno '$ENV'."

# =============================================================================
# FASE 2 — Construcción y subida de la imagen Docker (CI/CD)
# =============================================================================

echo ""
echo ">>> FASE 2: Construyendo y subiendo imagen Docker a Artifact Registry..."

# Comprobar si docker está abierto (Comprobación pre-flight)
echo "-> Comprobando el estado de Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ ERROR: Docker no está en ejecución."
    echo "👉 Por favor, abre Docker Desktop"
    exit 1
fi
echo "✅ Docker está listo."

# Autenticar la terminal de Docker con Google Cloud
gcloud auth configure-docker $REGION-docker.pkg.dev --quiet

# --- VARIABLES DE IMÁGENES ---
IMAGE_URL_INGESTION="$REPO/ingestion:latest"
IMAGE_URL_TRANSFORM="$REPO/transformation:latest"
IMAGE_URL_DBT="$REPO/dbt:latest"
TEMPLATE_PATH="gs://$PROJECT_ID-$APP_NAME-temp-$ENV/templates/air-quality.json"

# 1. Imagen de Ingestión (Cloud Run)
echo "-> Construyendo imagen de INGESTIÓN..."
docker build -t $IMAGE_URL_INGESTION ./src/ingestion
docker push $IMAGE_URL_INGESTION

# 2. Imagen de Transformación (Dataflow)
echo "-> Construyendo imagen de TRANSFORMACIÓN..."
docker build -t $IMAGE_URL_TRANSFORM ./src/transformation
docker push $IMAGE_URL_TRANSFORM

# 3. Imagen de dbt (Cloud Run Job)
echo "-> Construyendo imagen de DBT..."
docker build -t $IMAGE_URL_DBT ./src/dbt
docker push $IMAGE_URL_DBT

echo "✅ Imagenes subidas con éxito!"

# =============================================================================
# FASE 2.5 — Construcción de la Flex Template de Dataflow - NUEVO
# =============================================================================
echo ""
echo ">>> FASE 2.5: Registrando Flex Template en Cloud Storage..."

gcloud dataflow flex-template build "$TEMPLATE_PATH" \
    --image "$IMAGE_URL_TRANSFORM" \
    --sdk-language "PYTHON" \
    --metadata-file "src/transformation/metadata.json" \
    --project="$PROJECT_ID"

echo "✅ Plantilla Dataflow generada en: $TEMPLATE_PATH"

echo ""
echo "Fase 2 completada. Imágenes Docker subidas a Artifact y lista para el entorno '$ENV'."

# =============================================================================
# FASE 3 — Terraform apply app
# =============================================================================

echo ""
echo ">>> FASE 3: Desplegando infraestructura app para el entorno '$ENV'..."
# Navegamos a la carpeta del entorno que ha elegido el usuario
cd envs/$ENV/terraform/01_app

terraform init -upgrade

# Validar la sintaxis (Fail Fast)
echo "-> Validando código Terraform..."
if ! terraform validate; then
    echo "❌ ERROR: La validación de Terraform ha fallado. Revisa tus archivos .tf"
    exit 1
fi
echo "✅ Terraform validado correctamente."

# Exportar el plan
terraform plan -out=main.tfplan
terraform apply main.tfplan

# Volvemos a la raíz (subimos cuatro niveles)
cd ../../../..

echo ""
echo "Fase 3 completada. Infraestructura app para el entorno '$ENV'."


# =============================================================================
# DESTROY OPCIONAL — Solo disponible en entorno dev
# =============================================================================

if [ "$ENV" = "dev" ]; then
  echo ""
  read -p "¿Quieres hacer un terraform destroy del entorno dev? (destroy/no): " DESTROY
  if [ "$DESTROY" = "destroy" ]; then
    echo ""
    echo ">>> Ejecutando terraform destroy para el entorno 'dev'..."
    cd envs/dev/terraform/01_app
    terraform destroy
    cd ../../../..
    cd envs/dev/terraform/00_base
    terraform destroy
    cd ../../../..
    echo ""
    echo "Destroy completado."
  else
    echo "Destroy cancelado."
  fi
fi