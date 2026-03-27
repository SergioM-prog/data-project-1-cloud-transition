# =============================================================================
# 1. CONTAINERS (Artifact Registry)
# =============================================================================

# Creamos el repositorio para las imágenes Docker de Cloud Run
module "artifact_registry" {
  source        = "../../../../modules/artifact_registry"
  repository_id = "${var.app_name}-${var.environment}"
  region        = var.region
  description   = "Repositorio Docker para las imágenes del pipeline de Air Quality en ${var.environment}"
}
