output "dataset_id" {
  description = "ID del dataset de BigQuery"
  value       = google_bigquery_dataset.air_quality_dataset.dataset_id
}

output "table_id" {
  description = "ID de la tabla de BigQuery"
  value       = google_bigquery_table.valencia_air.table_id
}
