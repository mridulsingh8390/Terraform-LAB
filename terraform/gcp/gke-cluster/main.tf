################################################################################
# GCP GKE Root Configuration
# Wires: vpc → kms → filestore → gke
#
# CMK dependency order:
#   1. KMS keyring + CryptoKey created
#   2. KMS IAM bindings granted to GKE, Filestore, Compute service accounts
#   3. Filestore created (CMEK via KMS key)
#   4. GKE cluster created (CMEK etcd + node boot disk encryption)
################################################################################

module "vpc" {
  source = "../../modules/gcp/vpc"

  vpc_name         = var.vpc_name
  prefix           = var.prefix
  project_id       = var.project_id
  region           = var.region
  gke_subnet_cidr  = var.gke_subnet_cidr
  pods_cidr        = var.pods_cidr
  services_cidr    = var.services_cidr
  master_ipv4_cidr = var.master_ipv4_cidr
}

module "kms" {
  source = "../../modules/gcp/kms"

  prefix     = var.prefix
  project_id = var.project_id
  location   = var.region
}

module "filestore" {
  source = "../../modules/gcp/filestore"

  prefix                   = var.prefix
  project_id               = var.project_id
  zone                     = var.filestore_zone
  vpc_name                 = module.vpc.vpc_name
  cmk_id                   = module.kms.cmk_id
  tier                     = var.filestore_tier
  capacity_gb              = var.filestore_capacity_gb
  filestore_reserved_cidr  = var.filestore_reserved_cidr
  k8s_manifest_output_path = var.k8s_manifest_output_path
  labels                   = var.labels

  depends_on = [module.kms]
}

module "gke" {
  source = "../../modules/gcp/gke"

  cluster_name         = var.cluster_name
  prefix               = var.prefix
  project_id           = var.project_id
  region               = var.region
  vpc_name             = module.vpc.vpc_name
  subnet_name          = module.vpc.gke_subnet_name
  pods_range_name      = module.vpc.pods_range_name
  services_range_name  = module.vpc.services_range_name
  cmk_id               = module.kms.cmk_id
  master_ipv4_cidr     = var.master_ipv4_cidr
  release_channel      = var.release_channel
  deletion_protection  = var.deletion_protection
  node_disk_size_gb    = var.node_disk_size_gb

  system_node_machine_type = var.system_node_machine_type
  system_node_min          = var.system_node_min
  system_node_max          = var.system_node_max

  user_node_machine_type = var.user_node_machine_type
  user_node_min          = var.user_node_min
  user_node_max          = var.user_node_max

  labels = var.labels

  depends_on = [module.kms]
}
