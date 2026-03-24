# Leemos el estado de la capa base
data "terraform_remote_state" "base" {
  backend = "local"
  config = {
    path = "../00_base/terraform.tfstate"
  }
}

# =============================================================================
# 1. CLOUD RUN JOBS
# =============================================================================

module "ingestion_job" {
  source = "../../../../modules/cloud_run_job"

  project_id = var.project_id
  region     = var.region
  job_name   = "${var.app_name}-ingestion-${var.environment}"
  enable_deletion_protection = false  # Permite terraform destroy limpio
  
  # Construimos la misma URL a la que subimos la imagen en el deploy.sh
  image_url  = "${var.region}-docker.pkg.dev/${var.project_id}/${var.app_name}-${var.environment}/ingestion:latest"
  
  # Usamos la Service Account ingestion_sa creada
  service_account_email = data.terraform_remote_state.base.outputs.ingestion_sa_email

  # Variables de entorno que leerá el código de python
  env_vars = {
    API_URL         = var.valencia_api_url
    RAW_BUCKET_NAME = data.terraform_remote_state.base.outputs.raw_bucket_name
    CITY            = "Valencia" 
  }
}

# =============================================================================
# 2. SCHEDULER
# =============================================================================

module "ingestion_trigger" {
  source = "../../../../modules/cloud_scheduler"

  project_id  = var.project_id
  region      = var.region
  name        = "${var.app_name}-trigger-${var.environment}"
  description = "Despierta la ingesta de datos de Valencia"
  schedule    = var.schedule
  uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${module.ingestion_job.job_name}:run"

  # EL CAPATAZ: Esta cuenta es la que hace la llamada HTTP para despertar al Job
  service_account_email = data.terraform_remote_state.base.outputs.scheduler_sa_email
}
