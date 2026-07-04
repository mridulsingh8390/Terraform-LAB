# Backend config — GCP / dev
# Usage (local runs only):
#   cd terraform/gcp/gke-cluster
#   terraform init -backend-config="backend/dev.backend.hcl"
bucket         = "your-terraform-state-bucket"
key            = "gcp/gke-cluster/dev/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
