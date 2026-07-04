# GCP GKE — STAGING
project_id = "your-gcp-project-id"
region     = "us-central1"
prefix     = "gke-staging"

labels = {
  environment = "staging"
  cloud       = "gcp"
  managed_by  = "terraform"
}

vpc_name        = "vpc-gke-staging"
gke_subnet_cidr = "10.0.0.0/20"
pods_cidr       = "10.16.0.0/14"
services_cidr   = "10.20.0.0/20"
master_ipv4_cidr = "172.16.0.32/28"

filestore_zone          = "us-central1-a"
filestore_tier          = "BASIC_SSD"
filestore_capacity_gb   = 5320
filestore_reserved_cidr = "10.100.0.16/29"

cluster_name        = "gke-staging-cluster"
release_channel     = "REGULAR"
deletion_protection = false
node_disk_size_gb   = 100

system_node_machine_type = "n2-standard-4"
system_node_min          = 2
system_node_max          = 3

user_node_machine_type = "n2-highmem-8"
user_node_min          = 2
user_node_max          = 5
