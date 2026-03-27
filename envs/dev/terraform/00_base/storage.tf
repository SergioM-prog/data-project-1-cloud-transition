# =============================================================================
# 2. DATA LAKE & STORAGE (Cloud Storage)
# =============================================================================

# Bucket Data Lake (Raw)
module "raw_bucket" {
  source                     = "../../../../modules/gcs"
  bucket_name                = "${var.project_id}-${var.app_name}-raw-${var.environment}"
  region                     = var.region
  enable_deletion_protection = false # Estamos en dev, queremos poder borrarlo
}

# Bucket Temporal (Dataflow)
module "temp_bucket" {
  source                     = "../../../../modules/gcs"
  bucket_name                = "${var.project_id}-${var.app_name}-temp-${var.environment}"
  region                     = var.region
  enable_deletion_protection = false # Estamos en dev, queremos poder borrarlo
}