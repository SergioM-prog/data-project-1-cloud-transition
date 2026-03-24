# =============================================================================
# CLOUD SCHEDULER (Despertador Genérico)
# =============================================================================

resource "google_cloud_scheduler_job" "scheduler" {
  name        = var.name
  description = var.description
  schedule    = var.schedule
  time_zone   = var.time_zone
  region      = var.region
  project     = var.project_id

  http_target {
    http_method = var.http_method
    uri         = var.uri

    # Autenticación: El Scheduler usa una Service Account para identificarse 
    # ante el servicio de destino (ej. Cloud Run) y demostrar que tiene permiso.
    oauth_token {
      service_account_email = var.service_account_email
    }
  }
}
