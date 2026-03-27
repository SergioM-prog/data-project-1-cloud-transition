# =============================================================================
# 1. DATA WAREHOUSE (BigQuery)
# =============================================================================

# CAPA BRONZE: Datos crudos (Ingesta vía Dataflow)
module "bigquery_bronze" {
  source                     = "../../../../modules/bigquery"
  region                     = var.region
  enable_deletion_protection = false 
  dataset_id                 = "air_quality_bronze_${var.environment}"
  
  tables = [
    {
      table_id    = "valencia_air"
      schema_path = "${path.module}/../../schemas/valencia_air.json"
    }
  ]
}

# CAPA SILVER: Datos limpios y normalizados (Gestionado por dbt)
module "bigquery_silver" {
  source                     = "../../../../modules/bigquery"
  region                     = var.region
  enable_deletion_protection = false 
  dataset_id                 = "air_quality_silver_${var.environment}"
  tables                     = [] # dbt creará las tablas/vistas aquí
}

# CAPA GOLD: Agregados y analítica (Gestionado por dbt)
module "bigquery_gold" {
  source                     = "../../../../modules/bigquery"
  region                     = var.region
  enable_deletion_protection = false 
  dataset_id                 = "air_quality_gold_${var.environment}"
  tables                     = [] # dbt creará las tablas finales aquí
}