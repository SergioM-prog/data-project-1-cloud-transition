# =============================================================================
# Entorno DEV — punto de entrada de Terraform
# Llama a los módulos pasándoles las variables necesarias.
# =============================================================================

# =============================================================================
# 1. DATA WAREHOUSE (BigQuery)
# =============================================================================

module "bigquery" {
  source = "../../../../modules/bigquery"
  region = var.region
  enable_deletion_protection = false  # Permite terraform destroy limpio
  dataset_id                 = "air_quality_dataset_${var.environment}"
  # Le pasamos la lista de tablas que queremos crear en este dataset
  tables = [
    {
      table_id    = "valencia_air"
      schema_path = "${path.module}/../../schemas/valencia_air.json"
    },
    # {
    #   table_id    = "valencia_air2"
    #   schema_path = "${path.module}/schemas/valencia_air.json"
    # }
  ]
}

# =============================================================================
# 2. DATA LAKE & STORAGE (Cloud Storage)
# =============================================================================

# Llamada 1: Creamos el Data Lake (Raw)
module "raw_bucket" {
  source                     = "../../../../modules/gcs"
  bucket_name                = "${var.project_id}-${var.app_name}-raw-${var.environment}"
  region                     = var.region
  enable_deletion_protection = false # Estamos en dev, queremos poder borrarlo
}

# Llamada 2: Creamos el Bucket Temporal (Dataflow)
module "temp_bucket" {
  source                     = "../../../../modules/gcs"
  bucket_name                = "${var.project_id}-${var.app_name}-temp-${var.environment}"
  region                     = var.region
  enable_deletion_protection = false # Estamos en dev, queremos poder borrarlo
}

# =============================================================================
# 3. IDENTITY (Service Accounts)
# =============================================================================

# Creamos la service account de ingestión
module "ingestion_sa" {
  source                     = "../../../../modules/service_account"
  account_id                 = "sa-ingestion-${var.environment}"
  display_name               = "Service Account para Script de Ingestion"
}

# Creamos la service account de scheduler
module "scheduler_sa" {
  source       = "../../../../modules/service_account"
  account_id   = "sa-scheduler-${var.environment}"
  display_name = "Cloud Scheduler SA para entorno ${var.environment}"
}

# =============================================================================
# 4. ACCESS MANAGEMENT (IAM Bindings)
# =============================================================================

# Asignamos permisos a la sa-ingestion sólo de escritura en el bucket siguiendo el principio de mínimo privilegio
resource "google_storage_bucket_iam_member" "ingestion_raw_access" {
  bucket = module.raw_bucket.bucket_name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${module.ingestion_sa.email}"
}

# Permisos a scheduler_sa para poder hacer la llamada HTTP para despertar al Cloud Run Job
resource "google_project_iam_member" "scheduler_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${module.scheduler_sa.email}"
}

# Permisos a scheduler_sa para poner inyectar las sa a los jobs
resource "google_project_iam_member" "scheduler_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${module.scheduler_sa.email}"
}


# =============================================================================
# 5. CONTAINERS (Artifact Registry)
# =============================================================================

# Creamos el repositorio para las imágenes Docker de Cloud Run
module "artifact_registry" {
  source        = "../../../../modules/artifact_registry"
  repository_id = "${var.app_name}-${var.environment}"
  region        = var.region
  description   = "Repositorio Docker para las imágenes del pipeline de Air Quality en ${var.environment}"
}