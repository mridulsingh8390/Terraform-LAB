# GCP GKE — PROD
project_id = "your-gcp-project-id"
region     = "us-central1"
prefix     = "gke-prod"

labels = {
  environment = "prod"
  cloud       = "gcp"
  managed_by  = "terraform"
}

vpc_name        = "vpc-gke-prod"
gke_subnet_cidr = "10.0.0.0/20"
pods_cidr       = "10.16.0.0/14"
services_cidr   = "10.20.0.0/20"
master_ipv4_cidr = "172.16.0.48/28"

filestore_zone          = "us-central1-a"
filestore_tier          = "ENTERPRISE"
filestore_capacity_gb   = 10240
filestore_reserved_cidr = "10.100.0.24/29"

cluster_name        = "gke-prod-cluster"
release_channel     = "STABLE"
deletion_protection = true
node_disk_size_gb   = 200

system_node_machine_type = "n2-standard-8"
system_node_min          = 3
system_node_max          = 5

user_node_machine_type = "n2-highmem-16"
user_node_min          = 3
user_node_max          = 10
