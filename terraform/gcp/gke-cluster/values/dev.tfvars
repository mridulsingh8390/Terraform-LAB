# GCP GKE — DEV
project_id = "mydemo-project-2025"
region     = "us-central1"
prefix     = "gke-dev"

labels = {
  environment = "dev"
  cloud       = "gcp"
  managed_by  = "terraform"
}

vpc_name        = "vpc-gke-dev"
gke_subnet_cidr = "10.0.0.0/20"
pods_cidr       = "10.16.0.0/14"
services_cidr   = "10.20.0.0/20"
master_ipv4_cidr = "172.16.0.0/28"

filestore_zone          = "us-central1-a"
filestore_tier          = "BASIC_SSD"
filestore_capacity_gb   = 2660
filestore_reserved_cidr = "10.100.0.0/29"
k8s_manifest_output_path = "./k8s-manifests"

cluster_name        = "gke-dev-cluster"
release_channel     = "REGULAR"
deletion_protection = false
node_disk_size_gb   = 100

system_node_machine_type = "n2-standard-2"
system_node_min          = 1
system_node_max          = 2

user_node_machine_type = "n2-highmem-4"
user_node_min          = 1
user_node_max          = 2
