# =============================================================================
# MÓDULO GENÉRICO GCS — Crea un único bucket seguro
# =============================================================================

resource "google_storage_bucket" "bucket" {
  name                        = var.bucket_name
  location                    = var.region
  force_destroy               = !var.enable_deletion_protection
  uniform_bucket_level_access = true
}