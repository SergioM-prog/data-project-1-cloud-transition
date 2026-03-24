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
    PROJECT_ID = var.project_id
    RAW_BUCKET = data.terraform_remote_state.base.outputs.raw_bucket_name
    API_URL    = var.valencia_api_url
    ENV        = var.environment
  }
}
