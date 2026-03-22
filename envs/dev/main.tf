# =============================================================================
# Entorno DEV — punto de entrada de Terraform
# Llama a los módulos pasándoles las variables necesarias.
# =============================================================================

module "bigquery" {
  source = "../../modules/bigquery"
  region = var.region
  environment                = "dev"
  enable_deletion_protection = false  # Permite terraform destroy limpio
}
