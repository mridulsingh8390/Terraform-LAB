# Backend config — GCP / qa
# Usage (local runs only):
#   cd terraform/gcp/gke-cluster
#   terraform init -backend-config="backend/qa.backend.hcl"
bucket         = "your-terraform-state-bucket"
key            = "gcp/gke-cluster/qa/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
