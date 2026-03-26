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

variable "valencia_api_url" {
  description = "URL de la API de calidad del aire de Valencia"
  type        = string
  default     = "https://valencia.opendatasoft.com/api/explore/v2.1/catalog/datasets/estacions-contaminacio-atmosferiques-estaciones-contaminacion-atmosfericas/records?limit=20" 
}

variable "schedule" {
  description = "Frecuencia de ejecución del job de ingesta"
  type        = string
  default     = "*/30 * * * *" # Cada 30 minutos por defecto
}
