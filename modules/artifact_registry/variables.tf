variable "repository_id" {
  description = "El ID del repositorio"
  type        = string
}

variable "region" {
  description = "La región donde se alojará el repositorio"
  type        = string
}

variable "description" {
  description = "Descripción del repositorio"
  type        = string
  default     = "Repositorio de imágenes Docker"
}