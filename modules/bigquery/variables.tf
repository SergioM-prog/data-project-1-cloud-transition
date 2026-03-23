variable "region" {
  description = "Región de GCP donde se creará el dataset de BigQuery"
  type        = string
}

# Se inyecta como variable en la llamada del módulo.
variable "enable_deletion_protection" {
  description = "Si es true, bloquea el borrado accidental del dataset/tabla"
  type        = bool  
}

variable "dataset_id" {
  description = "El nombre del dataset de BigQuery"
  type        = string
}

variable "tables" {
  description = "Lista de tablas a crear con sus esquemas"
  type = list(object({
    table_id    = string
    schema_path = string
  }))
  default = []
}