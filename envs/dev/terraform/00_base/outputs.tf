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

output "scheduler_sa_email" {
  description = "Email de la Service Account que ejecuta el Job de ingestion"
  value       = module.scheduler_sa.email
}

output "bq_dataset_id" {
  description = "ID del dataset Bronze de BigQuery"
  value       = module.bigquery_bronze.dataset_id
}

output "dataflow_sa_email" {
  description = "Email de la Service Account que ejecuta Dataflow"
  value       = module.dataflow_sa.email
}

output "dbt_sa_email" {
  description = "Email de la Service Account que ejecuta dbt"
  value       = module.dbt_sa.email
}

output "silver_dataset_id" {
  description = "ID del dataset Silver (staging dbt)"
  value       = module.bigquery_silver.dataset_id
}

output "gold_dataset_id" {
  description = "ID del dataset Gold (marts dbt)"
  value       = module.bigquery_gold.dataset_id
}