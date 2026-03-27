# Leemos el estado de la capa base
data "terraform_remote_state" "base" {
  backend = "local"
  config = {
    path = "../00_base/terraform.tfstate"
  }
}