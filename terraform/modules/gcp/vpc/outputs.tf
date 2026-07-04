output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "gke_subnet_name" {
  value = google_compute_subnetwork.gke.name
}

output "gke_subnet_id" {
  value = google_compute_subnetwork.gke.id
}

output "pods_range_name" {
  value = "pods"
}

output "services_range_name" {
  value = "services"
}
