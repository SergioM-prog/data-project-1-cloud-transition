variable "account_id" {
  description = "El ID único técnico de la Service Account (ej. 'sa-ingestion-dev'). Solo admite minúsculas, números y guiones (máx. 30 caracteres)."
  type = string
}

variable "display_name" {
  description = "Nombre amigable y descriptivo que se mostrará en la interfaz web de GCP (ej. 'SA para Ingesta de Datos de Calidad del Aire')."
  type = string
}