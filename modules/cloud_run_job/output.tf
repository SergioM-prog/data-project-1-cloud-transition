output "job_name" {
  description = "El nombre del Cloud Run Job creado"
  value       = google_cloud_run_v2_job.job.name
}