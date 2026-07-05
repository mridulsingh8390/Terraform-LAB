# Terraform-LAB — Multi-Cloud Kubernetes with CMK

Three clouds. One pipeline. Every Kubernetes cluster and storage resource encrypted with a Customer Managed Key (CMK) you control.

---

## Repository Structure

```
Terraform-LAB/
├── .github/
│   └── workflows/
│       └── terraform.yml          ← Single pipeline for all three clouds
├── terraform/
│   ├── modules/
│   │   ├── azure/
│   │   │   ├── vnet/              VNet + Subnets + NSGs
│   │   │   ├── keyvault/          Key Vault + CMK key + Disk Encryption Set
│   │   │   ├── storage/           Storage Account + Azure Files NFS (CMK)
│   │   │   └── aks/               AKS cluster + system + user node pools (CMK)
│   │   ├── aws/
│   │   │   ├── vpc/               VPC + Subnets + Security Groups
│   │   │   ├── kms/               KMS CMK key + alias + key policy
│   │   │   ├── efs/               EFS file system (CMK) + mount targets
│   │   │   └── eks/               EKS cluster + system + user node groups (CMK)
│   │   └── gcp/
│   │       ├── vpc/               VPC Network + Subnets + Cloud NAT
│   │       ├── kms/               KMS keyring + CryptoKey + IAM bindings
│   │       ├── filestore/         Filestore NFS instance (CMEK)
│   │       └── gke/               GKE cluster + system + user node pools (CMEK)
│   ├── azure/
│   │   └── azure-kubernetes-service/
│   │       ├── main.tf            Wires: vnet → keyvault → storage → aks
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── providers.tf       azurerm provider + S3 backend
│   │       ├── backend/           Local run backend configs (dev/qa/staging/prod)
│   │       └── values/
│   │           ├── dev.tfvars
│   │           ├── qa.tfvars
│   │           ├── staging.tfvars
│   │           └── prod.tfvars
│   ├── aws/
│   │   └── eks-cluster/           Same structure as azure above
│   └── gcp/
│       └── gke-cluster/           Same structure as azure above
├── setup-s3-backend.sh            One-time AWS backend setup script
├── cleanup-s3-backend.sh          Cleanup script to remove all AWS backend resources
└── README.md
```

---

## CMK Coverage

| Resource | Azure | AWS | GCP |
|----------|-------|-----|-----|
| Cluster etcd | Key Vault CMK via DES | KMS envelope encryption | Cloud KMS CMEK |
| Node OS disks | Disk Encryption Set | KMS via Launch Template EBS | boot_disk_kms_key |
| NFS Storage | Azure Files CMK via storage account | EFS KMS encryption | Filestore CMEK |
| Key rotation | 365 days (automatic) | Automatic enabled | 90 days (automatic) |

---

## Node Pool Design

| Pool | Purpose | Taint |
|------|---------|-------|
| System | Kubernetes system components only (CoreDNS, kube-proxy, CNI) | `CriticalAddonsOnly=true:NoSchedule` |
| User | Application workloads + PostgreSQL pods | None — accepts all pods |

---

## State File Layout (S3)

All three clouds share one S3 bucket. Each environment gets its own state file — no Terraform workspaces needed.

```
s3://<TF_STATE_BUCKET>/
├── azure/azure-kubernetes-service/dev/terraform.tfstate
├── azure/azure-kubernetes-service/qa/terraform.tfstate
├── azure/azure-kubernetes-service/staging/terraform.tfstate
├── azure/azure-kubernetes-service/prod/terraform.tfstate
├── aws/eks-cluster/dev/terraform.tfstate
├── aws/eks-cluster/qa/terraform.tfstate
├── aws/eks-cluster/staging/terraform.tfstate
├── aws/eks-cluster/prod/terraform.tfstate
├── gcp/gke-cluster/dev/terraform.tfstate
├── gcp/gke-cluster/qa/terraform.tfstate
├── gcp/gke-cluster/staging/terraform.tfstate
└── gcp/gke-cluster/prod/terraform.tfstate
```

---

## One-Time AWS Backend Setup

Before running the pipeline for the first time, you need an S3 bucket for state storage and a DynamoDB table for state locking.

### Using the setup script

```bash
# 1. Edit the script — set your bucket name (must be globally unique)
vi setup-s3-backend.sh

# 2. Run it
bash setup-s3-backend.sh
```

The script creates:
- S3 bucket (versioning + encryption + public access block enabled)
- DynamoDB table (`terraform-state-lock`) with `LockID` partition key
- IAM user (`terraform-state-user`) with least-privilege S3 + DynamoDB policy
- Access keys for the IAM user

**Note:** For `us-east-1` (the default AWS region), the bucket is created without `--create-bucket-configuration` — this is handled automatically by the script. All other regions include the location constraint.

### Cleaning up the backend

When you no longer need the Terraform backend resources:

```bash
bash cleanup-s3-backend.sh
```

The script deletes in the correct order:
1. All S3 object versions and delete markers (required before bucket deletion when versioning is enabled)
2. The S3 bucket
3. The DynamoDB table
4. IAM access keys → inline policy → IAM user

---

## GitHub Secrets Required

Go to **repo → Settings → Secrets and variables → Actions → New repository secret** and add:

### S3 Backend (shared by all clouds)

| Secret | Description |
|--------|-------------|
| `TF_STATE_BUCKET` | S3 bucket name from setup script |
| `TF_STATE_LOCK_TABLE` | DynamoDB table name (`terraform-state-lock`) |
| `AWS_ACCESS_KEY_ID` | IAM access key from setup script output |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key from setup script output |
| `AWS_REGION` | S3 bucket region (e.g. `us-east-1`) |

### Azure

| Secret | Description |
|--------|-------------|
| `ARM_CLIENT_ID` | Service principal `appId` |
| `ARM_CLIENT_SECRET` | Service principal `password` |
| `ARM_TENANT_ID` | Azure AD `tenant` ID |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |

Create the service principal (run in terminal with Azure CLI logged in):

```bash
# Login with device code
az login --use-device-code

# Set subscription
az account set --subscription <your-subscription-id>

# Create service principal
MSYS_NO_PATHCONV=1 az ad sp create-for-rbac \
  --name "github-actions-terraform" \
  --role "Contributor" \
  --scopes "/subscriptions/<your-subscription-id>"

# Grant role assignment permission (needed for CMK role assignments)
MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee <appId-from-above> \
  --role "User Access Administrator" \
  --scope "/subscriptions/<your-subscription-id>"
```

> **Git Bash on Windows:** Always prefix Azure CLI commands with `MSYS_NO_PATHCONV=1` to prevent Git Bash from converting `/subscriptions/...` paths to Windows file paths.

### AWS (resource provisioning)

| Secret | Description |
|--------|-------------|
| `AWS_PROVIDER_ACCESS_KEY_ID` | IAM key for EKS/VPC/KMS/EFS provisioning |
| `AWS_PROVIDER_SECRET_ACCESS_KEY` | IAM secret key |
| `AWS_PROVIDER_REGION` | AWS region for resources (e.g. `us-east-1`) |

### GCP

| Secret | Description |
|--------|-------------|
| `GCP_CREDENTIALS` | Full contents of a service account JSON key file |
| `GCP_PROJECT_ID` | GCP project ID |

---

## Before First Apply — Update tfvars

Open `terraform/<cloud>/<service>/values/dev.tfvars` and replace placeholder values:

### Azure
```hcl
key_vault_name       = "kv-aksdev-YOURNAME"      # globally unique, 3-24 chars
storage_account_name = "staksdvYOURNAME"          # globally unique, lowercase alphanumeric only
kv_purge_protection_enabled = true                 # required for CMK with storage account
```

### AWS
```hcl
s3_bucket_name = "eks-dev-app-storage-YOURNAME"   # globally unique (if enable_s3_bucket = true)
```

### GCP
```hcl
project_id     = "your-real-gcp-project-id"
gcs_bucket_name = "gke-dev-app-YOURNAME"          # globally unique (if enable_gcs_bucket = true)
```

---

## Running the Pipeline

Go to **Actions → Terraform → Run workflow** in GitHub:

| Input | Options |
|-------|---------|
| Cloud | `azure` / `aws` / `gcp` |
| Environment | `dev` / `qa` / `staging` / `prod` |
| Action | `plan` / `apply` / `destroy` |
| Branch | any branch name (default: `main`) |

### Recommended first-run order

```
1. cloud=azure  env=dev  action=plan    ← verify the plan looks correct
2. cloud=azure  env=dev  action=apply   ← create dev resources
3. cloud=aws    env=dev  action=plan
4. cloud=aws    env=dev  action=apply
5. cloud=gcp    env=dev  action=plan
6. cloud=gcp    env=dev  action=apply
```

---

## Running Locally

```bash
# Set credentials as environment variables
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_TENANT_ID="..."
export ARM_SUBSCRIPTION_ID="..."
export AWS_ACCESS_KEY_ID="..."        # S3 backend IAM user
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"

# Navigate to the cloud config
cd terraform/azure/azure-kubernetes-service

# Init with local backend config
terraform init -backend-config="backend/dev.backend.hcl"

# Plan
terraform plan -var-file="values/dev.tfvars"

# Apply
terraform apply -var-file="values/dev.tfvars"
```

Update `backend/dev.backend.hcl` with your real bucket name and region before running locally.

---

## After Apply — Kubernetes StorageClass

After `terraform apply`, a StorageClass YAML is written to `./k8s-manifests/` and uploaded as a pipeline artifact. Apply it before deploying your PostgreSQL pod:

```bash
# Get cluster credentials
az aks get-credentials \
  --resource-group rg-aks-dev \
  --name aks-dev-cluster

# Apply the StorageClass
kubectl apply -f k8s-manifests/azure-files-nfs-storageclass.yaml

# Use in your PostgreSQL PVC
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes: [ReadWriteMany]
  storageClassName: azure-files-nfs-cmk
  resources:
    requests:
      storage: 50Gi
YAML
```

---

## Common Errors and Fixes

| Error | Fix |
|-------|-----|
| `Please run 'az login'` | Azure secrets not set in GitHub — add `ARM_*` secrets |
| `The value cannot be empty` | S3 backend secrets not set — add `TF_STATE_BUCKET`, `AWS_REGION` etc. |
| `InvalidLocationConstraint` | Running `create-bucket` with `LocationConstraint=us-east-1` — use the setup script which handles this automatically |
| `InsufficientVCPUQuota` | VM family quota exceeded — change `system_node_vm_size` in tfvars to a smaller family or request a quota increase in Azure Portal |
| `NetworkAclsValidationFailure` | AKS user subnet missing `Microsoft.Storage` service endpoint — already fixed in modules |
| `must be configured for both Purge Protection and Soft Delete` | Set `kv_purge_protection_enabled = true` in tfvars when using CMK with storage |
| `MSYS_NO_PATHCONV` path error | Git Bash converts `/subscriptions/...` to Windows path — prefix command with `MSYS_NO_PATHCONV=1` |
