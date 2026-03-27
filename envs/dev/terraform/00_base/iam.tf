# =============================================================================
# 1. INGESTION: IDENTIDAD Y PERMISOS
# =============================================================================

#------------Service Account----------

# Creamos la service account de ingestión
module "ingestion_sa" {
  source                     = "../../../../modules/service_account"
  account_id                 = "sa-ingestion-${var.environment}"
  display_name               = "Service Account para Script de Ingestion"
}

#------------Permisos------------------

# Asignamos permisos a la sa-ingestion sólo de escritura en el bucket siguiendo el principio de mínimo privilegio
resource "google_storage_bucket_iam_member" "ingestion_raw_access" {
  bucket = module.raw_bucket.bucket_name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${module.ingestion_sa.email}"
}

# =============================================================================
# 2. SCHEDULER: IDENTIDAD Y PERMISOS
# =============================================================================

#------------Service Account----------

# Creamos la service account de scheduler
module "scheduler_sa" {
  source       = "../../../../modules/service_account"
  account_id   = "sa-scheduler-${var.environment}"
  display_name = "Cloud Scheduler SA para entorno ${var.environment}"
}

#------------Permisos------------------

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

# Le damos permiso al Scheduler para que pueda lanzar Jobs de Dataflow
resource "google_project_iam_member" "scheduler_dataflow_admin" {
  project = var.project_id
  role    = "roles/dataflow.admin"
  member  = "serviceAccount:${module.scheduler_sa.email}"
}

# Permite al agente de servicio de Cloud Scheduler generar tokens OAuth
# en nombre de sa-scheduler. Sin esto, las llamadas HTTP salen sin token → 401.
resource "google_service_account_iam_member" "scheduler_token_creator" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${module.scheduler_sa.email}"
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudscheduler.iam.gserviceaccount.com"
}

# =============================================================================
# 3. DATAFLOW: IDENTIDAD Y PERMISOS (El Analista)
# =============================================================================

#------------Service Account----------

# Creamos la Service Account de Dataflow
module "dataflow_sa" {
  source       = "../../../../modules/service_account"
  account_id   = "sa-dataflow-${var.environment}"
  display_name = "Service Account para ejecución de Dataflow"
}

#------------Permisos------------------

# Permiso core para que Dataflow levante los workers
resource "google_project_iam_member" "dataflow_worker" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${module.dataflow_sa.email}"
}

# Permiso para leer los archivos del bucket RAW (Lectura)
resource "google_storage_bucket_iam_member" "dataflow_raw_viewer" {
  bucket = module.raw_bucket.bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.dataflow_sa.email}"
}

# Permiso para usar el bucket TEMP (Admin)
resource "google_storage_bucket_iam_member" "dataflow_temp_admin" {
  bucket = module.temp_bucket.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.dataflow_sa.email}"
}

# Permisos para que Dataflow pueda crear trabajos en BigQuery y escribir datos
resource "google_project_iam_member" "dataflow_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${module.dataflow_sa.email}"
}

# Permisos para 
resource "google_bigquery_dataset_iam_member" "dataflow_bq_data_editor" {
  dataset_id = module.bigquery_bronze.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${module.dataflow_sa.email}"
}

# Permiso para que Dataflow pueda descargar la imagen Docker desde Artifact Registry
resource "google_project_iam_member" "dataflow_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${module.dataflow_sa.email}"
}

# =============================================================================
# 4. DBT: IDENTIDAD Y PERMISOS
# =============================================================================

#------------Service Account----------

module "dbt_sa" {
  source       = "../../../../modules/service_account"
  account_id   = "sa-dbt-${var.environment}"
  display_name = "Service Account para ejecución de dbt"
}

#------------Permisos------------------

# Ejecutar consultas en BigQuery (requerido para cualquier operación dbt)
resource "google_project_iam_member" "dbt_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.user"
  member  = "serviceAccount:${module.dbt_sa.email}"
}

# Leer datos del dataset Bronze (fuente: tabla valencia_air escrita por Dataflow)
resource "google_bigquery_dataset_iam_member" "dbt_bronze_viewer" {
  dataset_id = module.bigquery_bronze.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${module.dbt_sa.email}"
}

# Crear y actualizar vistas en Silver (capa staging)
resource "google_bigquery_dataset_iam_member" "dbt_silver_editor" {
  dataset_id = module.bigquery_silver.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${module.dbt_sa.email}"
}

# Crear y actualizar tablas en Gold (capa marts)
resource "google_bigquery_dataset_iam_member" "dbt_gold_editor" {
  dataset_id = module.bigquery_gold.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${module.dbt_sa.email}"
}