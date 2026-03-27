# =============================================================================
# TRIGGER INGESTION
# =============================================================================

module "ingestion_trigger" {
  source = "../../../../modules/cloud_scheduler"

  project_id  = var.project_id
  region      = var.region
  name        = "air-quality-ingestion-trigger-${var.environment}"
  description = "Despierta la ingesta de datos de Valencia"
  schedule    = "*/30 * * * *"
  
  uri         = "https://${var.region}-run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/air-quality-ingestion-${var.environment}:run"
  
  # Le pasamos los parámetros opcionales
  body                  = base64encode(jsonencode({}))
  service_account_email = data.terraform_remote_state.base.outputs.scheduler_sa_email
}



# =============================================================================
# 4. TRIGGER DBT
# =============================================================================

module "dbt_trigger" {
  source = "../../../../modules/cloud_scheduler"

  project_id  = var.project_id
  region      = var.region
  name        = "${var.app_name}-dbt-trigger-${var.environment}"
  description = "Ejecuta dbt cada hora para transformar los datos de calidad del aire"
  schedule    = "0 * * * *"

  # La ingesta termina a las y45; dbt arranca a la hora en punto (margen de 15 min)
  uri = "https://${var.region}-run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${var.app_name}-dbt-runner-${var.environment}:run"

  body                  = base64encode(jsonencode({}))
  service_account_email = data.terraform_remote_state.base.outputs.scheduler_sa_email
}

# -----------------------------------------------------------------------------
# 2. TRIGGER DATAFLOW
# -----------------------------------------------------------------------------
module "dataflow_trigger" {
  source = "../../../../modules/cloud_scheduler"

  project_id  = var.project_id
  region      = var.region
  name        = "air-quality-dataflow-trigger-${var.environment}"
  description = "Despierta el Cloud Run que ejecuta el comando gcloud de Dataflow"
  schedule    = "45 * * * *"
  
  # Llamamos a Cloud Run en lugar de a Dataflow directamente
  uri         = "https://${var.region}-run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/air-quality-dataflow-launcher-${var.environment}:run"
  
  # Parámetros opcionales que el módulo ahora acepta
  body                  = base64encode(jsonencode({}))
  service_account_email = data.terraform_remote_state.base.outputs.scheduler_sa_email
}