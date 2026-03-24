# =============================================================================
# CLOUD RUN JOB (Trabajador Serverless Batch)
# =============================================================================

resource "google_cloud_run_v2_job" "job" {
  name     = var.job_name
  location = var.region
  project  = var.project_id
  deletion_protection = var.enable_deletion_protection

  template {
    template {
      # Service Account que usará el contenedor
      service_account = var.service_account_email
      
      # Configuraciones de resiliencia y tiempo
      max_retries = 1
      timeout     = "300s" # 5 minutos máximo por ejecución

      containers {
        # La imagen Docker de Artifact Registry
        image = var.image_url

        # Inyección dinámica de variables de entorno
        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
  }
}
