# =============================================================================
# BigQuery — Dataset y Tabla del Data Warehouse
# =============================================================================

resource "google_bigquery_dataset" "dataset" {
  # Nombramos el dataset dinámicamente: ej. air_quality_dataset_dev
  dataset_id                 = var.dataset_id
  location                   = var.region
  delete_contents_on_destroy = !var.enable_deletion_protection
}

resource "google_bigquery_table" "tables" {
  # Convertimos la lista en un mapa para que Terraform pueda iterar
  for_each = { for t in var.tables : t.table_id => t }

  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = each.value.table_id
  
  # Leemos el archivo JSON directamente desde la ruta que le pasemos
  schema              = file(each.value.schema_path)
  
  deletion_protection = var.enable_deletion_protection
}