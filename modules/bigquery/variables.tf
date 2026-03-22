variable "region" {
  description = "Región de GCP donde se creará el dataset de BigQuery"
  type        = string
}

# Se inyecta como variable en la llamada del módulo.
variable "environment" {
  description = "El nombre del entorno (dev, prod, etc.) para nombrar los recursos"
  type        = string
}

# Se inyecta como variable en la llamada del módulo.
variable "enable_deletion_protection" {
  description = "Si es true, bloquea el borrado accidental del dataset/tabla"
  type        = bool  
}