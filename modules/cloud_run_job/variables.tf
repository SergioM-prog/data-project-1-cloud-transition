variable "project_id" {
  description = "El ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "La región donde se desplegarán los recursos"
  type        = string
}

variable "job_name" {
  description = "El nombre del Cloud Run Job"
  type        = string
}

variable "image_url" {
  description = "La URL completa de la imagen Docker en Artifact Registry"
  type        = string
}

variable "service_account_email" {
  description = "El email de la Service Account que ejecutará el Job"
  type        = string
}

variable "env_vars" {
  description = "Diccionario clave-valor con las variables de entorno para el contenedor"
  type        = map(string)
  default     = {}
}

variable "enable_deletion_protection" {
  description = "Si es true, bloquea el borrado accidental del job"
  type        = bool  
}