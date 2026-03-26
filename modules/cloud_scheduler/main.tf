# =============================================================================
# CLOUD SCHEDULER (Despertador Genérico)
# =============================================================================

resource "google_cloud_scheduler_job" "scheduler" {
  name        = var.name
  description = var.description
  schedule    = var.schedule
  time_zone   = var.time_zone
  project     = var.project_id
  region      = var.region

  http_target {
    http_method = var.http_method
    uri         = var.uri
    body        = var.body

    # Bloque dinámico: Solo se crea si enviamos un email
    dynamic "oauth_token" {
      for_each = var.service_account_email != "" ? [1] : []
      content {
        service_account_email = var.service_account_email
        scope                 = var.oauth_scope
      }
    }
  }
}
