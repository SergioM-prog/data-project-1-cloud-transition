# =============================================================================
# Entorno DEV — punto de entrada de Terraform
# Llama a los módulos pasándoles las variables necesarias.
# =============================================================================

module "bigquery" {
  source = "../../modules/bigquery"
  region = var.region
  enable_deletion_protection = false  # Permite terraform destroy limpio
  dataset_id                 = "air_quality_dataset_${var.environment}"
  # Le pasamos la lista de tablas que queremos crear en este dataset
  tables = [
    {
      table_id    = "valencia_air"
      schema_path = "${path.module}/schemas/valencia_air.json"
    },
    {
      table_id    = "valencia_air2"
      schema_path = "${path.module}/schemas/valencia_air.json"
    }
  ]
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