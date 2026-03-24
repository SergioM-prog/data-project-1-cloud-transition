# =============================================================================
# OUTPUTS DE LA INFRAESTRUCTURA BASE (Para consumir vía Remote State)
# =============================================================================

output "raw_bucket_name" {
  description = "Nombre del bucket RAW donde aterrizan los datos"
  value       = module.raw_bucket.bucket_name 
}

output "temp_bucket_name" {
  description = "Nombre del bucket temporal"
  value       = module.temp_bucket.bucket_name
}

output "ingestion_sa_email" {
  description = "Email de la Service Account que ejecuta el Job de ingestion"
  value       = module.ingestion_sa.email
}

output "bq_dataset_id" {
  description = "ID del dataset de BigQuery"
  value       = module.bigquery.dataset_id
}