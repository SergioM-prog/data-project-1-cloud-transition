output "id" {
  value       = google_artifact_registry_repository.repo.id
  description = "El ID completo del repositorio"
}

output "name" {
  value       = google_artifact_registry_repository.repo.name
  description = "El nombre de la ruta del repositorio"
}