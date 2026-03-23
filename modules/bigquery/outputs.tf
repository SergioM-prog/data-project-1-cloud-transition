output "dataset_id" {
  description = "ID del dataset de BigQuery"
  value       = google_bigquery_dataset.dataset.dataset_id
}

output "table_ids" {
  # Como 'tables' es un bucle (for_each), extraemos una lista con todos los IDs de las tablas creadas
  value       = [for t in google_bigquery_table.tables : t.table_id]
  description = "Lista de los IDs de las tablas creadas en el dataset"
}
