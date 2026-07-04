################################################################################
# AWS EKS Root Configuration
# Wires: vpc → kms → efs → eks
#
# CMK dependency order:
#   1. KMS key created (with policy granting EKS, EFS, AutoScaling access)
#   2. EFS created (CMK-encrypted via KMS key)
#   3. EKS cluster created (CMK etcd envelope encryption via KMS key)
#   4. EKS nodes created with CMK-encrypted EBS root volumes
################################################################################

module "vpc" {
  source = "../../modules/aws/vpc"

  vpc_name           = var.vpc_name
  prefix             = var.prefix
  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  tags               = var.tags
}

module "kms" {
  source = "../../modules/aws/kms"

  prefix                  = var.prefix
  deletion_window_in_days = var.kms_deletion_window_days
  tags                    = var.tags
}

module "efs" {
  source = "../../modules/aws/efs"

  prefix                   = var.prefix
  kms_key_arn              = module.kms.key_arn
  subnet_ids               = module.vpc.private_subnet_ids
  efs_security_group_id    = module.vpc.efs_security_group_id
  throughput_mode          = var.efs_throughput_mode
  performance_mode         = var.efs_performance_mode
  k8s_manifest_output_path = var.k8s_manifest_output_path
  tags                     = var.tags
}

module "eks" {
  source = "../../modules/aws/eks"

  cluster_name           = var.cluster_name
  kubernetes_version     = var.kubernetes_version
  subnet_ids             = module.vpc.private_subnet_ids
  node_security_group_id = module.vpc.eks_node_security_group_id
  kms_key_arn            = module.kms.key_arn
  endpoint_public_access = var.endpoint_public_access
  node_volume_size_gb    = var.node_volume_size_gb

  system_node_instance_types = var.system_node_instance_types
  system_node_desired        = var.system_node_desired
  system_node_min            = var.system_node_min
  system_node_max            = var.system_node_max

  user_node_instance_types = var.user_node_instance_types
  user_node_desired        = var.user_node_desired
  user_node_min            = var.user_node_min
  user_node_max            = var.user_node_max

  tags = var.tags
}
