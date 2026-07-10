# AWS EKS — dev
aws_region = "us-east-1"
prefix     = "eks-dev"

tags = {
  environment = "dev"
  cloud       = "aws"
  managed_by  = "terraform"
}

vpc_name             = "vpc-eks-dev"
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

kms_deletion_window_days = 30
efs_throughput_mode      = "elastic"
k8s_manifest_output_path = "./k8s-manifests"

cluster_name           = "eks-dev-cluster"
kubernetes_version     = "1.31"
endpoint_public_access = true
node_volume_size_gb    = 50

system_node_instance_types = ["t3.medium"]
system_node_desired        = 1
system_node_min            = 1
system_node_max            = 2

user_node_instance_types = ["t3.large"]
user_node_desired        = 1
user_node_min            = 1
user_node_max            = 2
