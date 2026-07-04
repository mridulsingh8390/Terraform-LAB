# Backend config — AWS / staging
# Usage (local runs only):
#   cd terraform/aws/eks-cluster
#   terraform init -backend-config="backend/staging.backend.hcl"
bucket         = "your-terraform-state-bucket"
key            = "aws/eks-cluster/staging/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
