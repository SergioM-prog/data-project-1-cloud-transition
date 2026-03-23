output "email" {
  value       = google_service_account.service_account.email
  description = "El correo electrónico generado para la Service Account. Esencial para asignar permisos en bloques IAM."
}

output "id" {
  value       = google_service_account.service_account.id
  description = "El identificador completo (fully-qualified) de la Service Account."
}