# =============================================================================
# Entorno DEV — punto de entrada de Terraform
# Llama a los módulos pasándoles las variables necesarias.
# =============================================================================

module "bigquery" {
  source = "../../modules/bigquery"
  region = var.region
  environment                = "dev"
  enable_deletion_protection = false  # Permite terraform destroy limpio
}

# Llamada 1: Creamos el Data Lake (Raw)
module "raw_bucket" {
  source                     = "../../modules/gcs"
  bucket_name                = "${var.project_id}-air-quality-raw-${var.environment}"
  region                     = var.region
  enable_deletion_protection = false # Estamos en dev, queremos poder borrarlo
}

# Llamada 2: Creamos el Bucket Temporal (Dataflow)
module "temp_bucket" {
  source                     = "../../modules/gcs"
  bucket_name                = "${var.project_id}-air-quality-temp-${var.environment}"
  region                     = var.region
  enable_deletion_protection = false # Estamos en dev, queremos poder borrarlo
}