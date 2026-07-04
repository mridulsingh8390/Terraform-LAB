# Backend config — GCP / prod
# Usage (local runs only):
#   cd terraform/gcp/gke-cluster
#   terraform init -backend-config="backend/prod.backend.hcl"
bucket         = "your-terraform-state-bucket"
key            = "gcp/gke-cluster/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
