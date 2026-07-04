# Backend config — Azure / qa
# Usage (local runs only — pipeline supplies these flags automatically):
#   cd terraform/azure/azure-kubernetes-service
#   terraform init -backend-config="backend/qa.backend.hcl"
#
# Update bucket, region, and dynamodb_table to match your S3 setup.
# The key path must match the pipeline — do not change it.
bucket         = "your-terraform-state-bucket"
key            = "azure/azure-kubernetes-service/qa/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-state-lock"
encrypt        = true
