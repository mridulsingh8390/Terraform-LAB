output "cluster_name" {
  value = google_container_cluster.gke.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.gke.endpoint
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = google_container_cluster.gke.master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool — use in ServiceAccount annotations"
  value       = "${var.project_id}.svc.id.goog"
}

output "node_service_account_email" {
  description = "Email of the GKE node service account"
  value       = var.node_service_account != null ? var.node_service_account : google_service_account.gke_nodes[0].email
}
