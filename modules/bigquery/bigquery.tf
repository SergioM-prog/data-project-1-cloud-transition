# =============================================================================
# BigQuery — Dataset y Tabla del Data Warehouse
# =============================================================================

resource "google_bigquery_dataset" "air_quality_dataset" {
  # Nombramos el dataset dinámicamente: ej. air_quality_dataset_dev
  dataset_id                 = "air_quality_dataset_${var.environment}"
  location                   = var.region
  delete_contents_on_destroy = !var.enable_deletion_protection
}

resource "google_bigquery_table" "valencia_air" {
  dataset_id          = google_bigquery_dataset.air_quality_dataset.dataset_id
  table_id            = "valencia_air"
  deletion_protection = var.enable_deletion_protection

  schema = jsonencode([
    { name = "objectid",     type = "INTEGER", mode = "REQUIRED" },
    { name = "fiwareid",     type = "STRING",  mode = "NULLABLE" },
    { name = "nombre",       type = "STRING",  mode = "NULLABLE" },
    { name = "direccion",    type = "STRING",  mode = "NULLABLE" },
    { name = "tipozona",     type = "STRING",  mode = "NULLABLE" },
    { name = "tipoemisio",   type = "STRING",  mode = "NULLABLE" },
    { name = "calidad_am",   type = "STRING",  mode = "NULLABLE" },
    { name = "fecha_carg",   type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "parametros",   type = "STRING",  mode = "NULLABLE" },
    { name = "mediciones",   type = "STRING",  mode = "NULLABLE" },
    { name = "so2",          type = "FLOAT",   mode = "NULLABLE" },
    { name = "no2",          type = "FLOAT",   mode = "NULLABLE" },
    { name = "o3",           type = "FLOAT",   mode = "NULLABLE" },
    { name = "co",           type = "FLOAT",   mode = "NULLABLE" },
    { name = "pm10",         type = "FLOAT",   mode = "NULLABLE" },
    { name = "pm25",         type = "FLOAT",   mode = "NULLABLE" },
    { name = "geo_shape",    type = "STRING",  mode = "NULLABLE" },
    { name = "geo_point_2d", type = "STRING",  mode = "NULLABLE" }
  ])
}
