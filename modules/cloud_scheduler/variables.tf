variable "project_id" {
  description = "El ID del proyecto de GCP"
  type        = string
}

variable "region" {
  description = "La región donde se desplegarán los recursos"
  type        = string
}

variable "name" {
  description = "Nombre del job en Cloud Scheduler"
  type        = string
}

variable "description" {
  description = "Descripción de lo que hace este cron"
  type        = string
  default     = "Job programado por Terraform"
}

variable "schedule" {
  description = "Expresión cron (ej: '*/30 * * * *' para cada 30 minutos)"
  type        = string
}

variable "time_zone" {
  description = "Zona horaria para ejecutar el cron"
  type        = string
  default     = "Europe/Madrid" # Por defecto usamos la de España
}

variable "uri" {
  description = "La URL exacta a la que el Scheduler tiene que llamar (ej. la API de Cloud Run)"
  type        = string
}
variable "http_method" {
  description = "Método HTTP a utilizar (GET, POST, PUT...)"
  type        = string
  default     = "POST"
}
variable "service_account_email" {
  description = "Email de la Service Account que el Scheduler usará para autenticarse"
  type        = string
}
