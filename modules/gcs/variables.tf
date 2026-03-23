variable "region" {
  description = "Región de GCP donde se creará el bucket genérico"
  type        = string
}

# Se inyecta como variable en la llamada del módulo.
variable "bucket_name" {
  description = "El nombre globalmente único del bucket"
  type        = string
}

# Se inyecta como variable en la llamada del módulo.
variable "enable_deletion_protection" {
  description = "Si es true, bloquea el borrado accidental del dataset/tabla"
  type        = bool  
}