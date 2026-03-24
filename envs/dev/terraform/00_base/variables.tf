variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "Región de GCP donde se desplegarán todos los recursos"
  type        = string
}

variable "environment" {
  type        = string
  description = "El nombre del entorno (sandbox, dev, prod...)"
  default     = "dev" # Le ponemos un valor por defecto seguro
}

variable "app_name" {
  type        = string
  description = "El nombre base de la aplicación o proyecto"
}