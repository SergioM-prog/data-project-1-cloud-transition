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
  name        = "air-quality-trigger-${var.environment}"
  description = "Despierta la ingesta de datos de Valencia"
  schedule    = "*/30 * * * *"
  
  uri         = "https://${var.region}-run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/air-quality-ingestion-${var.environment}:run"
  
  # Le pasamos los parámetros opcionales
  body                  = base64encode(jsonencode({}))
  service_account_email = data.terraform_remote_state.base.outputs.scheduler_sa_email
}


# -----------------------------------------------------------------------------
# 1. EL "PROXY"
# -----------------------------------------------------------------------------
resource "google_cloud_run_v2_job" "dataflow_launcher" {
  name     = "air-quality-dataflow-launcher-${var.environment}"
  location = var.region
  project  = var.project_id
  deletion_protection = false

  template {
    template {
      # Usa la cuenta de Scheduler, que ya tiene permisos de administrador de Dataflow
      service_account = data.terraform_remote_state.base.outputs.scheduler_sa_email
      
      containers {
        image = "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
        command = ["/bin/bash", "-c"]
        
        # UNA SOLA LÍNEA SIN SALTOS. Sino da error el job de dataflow porque ejecuta los comandos uno a uno si están en diferentes filas
        args = ["gcloud dataflow flex-template run \"air-quality-batch-$(date +%s)\" --template-file-gcs-location=\"gs://${var.project_id}-${var.app_name}-temp-${var.environment}/templates/air-quality.json\" --region=\"${var.region}\" --service-account-email=\"${data.terraform_remote_state.base.outputs.dataflow_sa_email}\" --staging-location=\"gs://${var.project_id}-${var.app_name}-temp-${var.environment}/staging\" --parameters=\"input=gs://${var.project_id}-${var.app_name}-raw-${var.environment}/raw/Valencia,output=${var.project_id}:air_quality_dataset_${var.environment}.valencia_air,temp_location=gs://${var.project_id}-${var.app_name}-temp-${var.environment}/staging\""]      
        }
    }
  }
}

# -----------------------------------------------------------------------------
# 2. EL DESPERTADOR (Llama al Proxy a las y 45)
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