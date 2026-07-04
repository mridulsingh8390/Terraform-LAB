# terraform-lab — Multi-Cloud Kubernetes with CMK

Three clouds. One folder structure. Every K8s cluster and storage resource is
encrypted with a Customer Managed Key (CMK) you control.

## Folder structure

```
terraform-lab/
├── terraform/
│   ├── modules/
│   │   ├── azure/
│   │   │   ├── vnet/          VNet + subnets (aks-system, aks-user, storage) + NSGs
│   │   │   ├── keyvault/      Key Vault + CMK RSA key + Disk Encryption Set
│   │   │   ├── storage/       Storage Account + Azure Files NFS share (CMK) + StorageClass YAML
│   │   │   └── aks/           AKS cluster + system pool + user pool (CMK OS disks + etcd)
│   │   ├── aws/
│   │   │   ├── vpc/           VPC + subnets + Security Groups (nodes + EFS)
│   │   │   ├── kms/           KMS CMK key + alias + key policy
│   │   │   ├── efs/           EFS file system (CMK) + mount targets + StorageClass YAML
│   │   │   └── eks/           EKS cluster (CMK etcd) + system + user node groups (CMK EBS)
│   │   └── gcp/
│   │       ├── vpc/           VPC network + GKE subnet + secondary ranges + Cloud NAT
│   │       ├── kms/           KMS keyring + CryptoKey + IAM bindings for GKE/Filestore/Compute
│   │       ├── filestore/     Filestore NFS instance (CMEK) + StorageClass YAML
│   │       └── gke/           GKE cluster (CMEK etcd + boot disks) + system + user node pools
│   │
│   ├── azure/azure-kubernetes-service/
│   │   ├── main.tf            Wires: vnet → keyvault → storage → aks
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf       azurerm + S3 backend
│   │   └── values/
│   │       ├── dev.tfvars
│   │       ├── qa.tfvars
│   │       ├── staging.tfvars
│   │       └── prod.tfvars
│   │
│   ├── aws/eks-cluster/
│   │   ├── main.tf            Wires: vpc → kms → efs → eks
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf       aws + S3 backend
│   │   └── values/
│   │       ├── dev.tfvars  ...  prod.tfvars
│   │
│   └── gcp/gke-cluster/
│       ├── main.tf            Wires: vpc → kms → filestore → gke
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf       google + S3 backend
│       └── values/
│           ├── dev.tfvars  ...  prod.tfvars
│
└── pipelines/.github/workflows/
    └── terraform.yml          Single workflow, cloud+env+action+branch dropdowns
```

## CMK (Customer Managed Key) coverage

| Cloud | What is CMK-encrypted |
|-------|-----------------------|
| Azure | AKS node OS disks (via Disk Encryption Set), AKS etcd (via Key Vault), Azure Files NFS share (via storage account CMK), Key Vault key auto-rotates every 365 days |
| AWS   | EKS etcd secrets (envelope encryption via KMS), EKS node EBS root volumes (via Launch Template), EFS file system (NFS for PostgreSQL PVC), IMDSv2 enforced on all nodes |
| GCP   | GKE etcd (database_encryption with CMEK), GKE node boot disks (boot_disk_kms_key), Filestore NFS (kms_key_name), KMS key rotates every 90 days |

## What each node pool is for

| Pool | Runs | Taint |
|------|------|-------|
| System | kube-system pods (CoreDNS, kube-proxy, CNI) | `CriticalAddonsOnly=true:NoSchedule` — app pods cannot land here |
| User | Your application pods + the PostgreSQL pod that mounts the NFS PVC | No taint — tolerates anything |

## StorageClass YAML files

After `terraform apply`, each cloud writes a Kubernetes StorageClass YAML to
`./k8s-manifests/` inside the working directory. The pipeline uploads these as
build artifacts. Apply them before deploying your PostgreSQL pod:

```bash
# Azure
kubectl apply -f k8s-manifests/azure-files-nfs-storageclass.yaml

# AWS  (install EFS CSI driver first — see file header comment)
kubectl apply -f k8s-manifests/efs-postgres-storageclass.yaml

# GCP  (install Filestore CSI driver first — see file header comment)
kubectl apply -f k8s-manifests/filestore-postgres-storageclass.yaml
```

Then reference the StorageClass in your PostgreSQL PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes: [ReadWriteMany]
  storageClassName: azure-files-nfs-cmk   # or efs-postgres-cmk / filestore-postgres-cmek
  resources:
    requests:
      storage: 50Gi
```

## State file layout in S3

One file per cloud+environment, no Terraform workspaces needed:

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

## GitHub Secrets required

**S3 backend (all clouds share this):**

| Secret | Value |
|--------|-------|
| `TF_STATE_BUCKET` | S3 bucket name |
| `TF_STATE_LOCK_TABLE` | DynamoDB table name |
| `AWS_ACCESS_KEY_ID` | IAM key for state bucket access only |
| `AWS_SECRET_ACCESS_KEY` | IAM secret for state bucket access only |
| `AWS_REGION` | S3 bucket region |

**Azure:**

| Secret | Value |
|--------|-------|
| `ARM_CLIENT_ID` | Service principal app ID |
| `ARM_CLIENT_SECRET` | Service principal password |
| `ARM_TENANT_ID` | Azure AD tenant ID |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |

**AWS (resource provisioning — separate IAM user from S3 backend):**

| Secret | Value |
|--------|-------|
| `AWS_PROVIDER_ACCESS_KEY_ID` | IAM key for EKS/VPC/KMS/EFS provisioning |
| `AWS_PROVIDER_SECRET_ACCESS_KEY` | IAM secret |
| `AWS_PROVIDER_REGION` | AWS region for resources |

**GCP:**

| Secret | Value |
|--------|-------|
| `GCP_CREDENTIALS` | Full contents of a service account JSON key |
| `GCP_PROJECT_ID` | GCP project ID |

## Before first run — update placeholders

**Azure tfvars:** replace `REPLACE` suffixes in `key_vault_name` and
`storage_account_name` — both must be globally unique in Azure.

**AWS tfvars:** update `aws_region`, `availability_zones`, and S3 bucket name
if using a different region.

**GCP tfvars:** set `project_id` to your real GCP project ID in all four
`values/*.tfvars` files (or pass it at plan time via the `GCP_PROJECT_ID`
secret, which the pipeline does automatically).

## Running the pipeline

Go to **Actions → Terraform → Run workflow** in GitHub and fill in:

| Input | Options |
|-------|---------|
| Cloud | `azure` / `aws` / `gcp` |
| Environment | `dev` / `qa` / `staging` / `prod` |
| Action | `plan` / `apply` / `destroy` |
| Branch | any branch (default: `main`) |

## Running locally

```bash
# Azure
cd terraform/azure/azure-kubernetes-service
export ARM_CLIENT_ID=...  ARM_CLIENT_SECRET=...  ARM_TENANT_ID=...  ARM_SUBSCRIPTION_ID=...
export AWS_ACCESS_KEY_ID=...  AWS_SECRET_ACCESS_KEY=...  AWS_DEFAULT_REGION=us-east-1
terraform init \
  -backend-config="bucket=your-bucket" \
  -backend-config="key=azure/azure-kubernetes-service/dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-state-lock" \
  -backend-config="encrypt=true"
terraform plan  -var-file="values/dev.tfvars"
terraform apply -var-file="values/dev.tfvars"

# AWS
cd terraform/aws/eks-cluster
export AWS_ACCESS_KEY_ID=...  AWS_SECRET_ACCESS_KEY=...  AWS_DEFAULT_REGION=us-east-1
terraform init -backend-config="bucket=..." -backend-config="key=aws/eks-cluster/dev/terraform.tfstate" ...
terraform plan  -var-file="values/dev.tfvars"

# GCP
cd terraform/gcp/gke-cluster
export GOOGLE_CREDENTIALS=$(cat /path/to/sa-key.json)
terraform init -backend-config="bucket=..." -backend-config="key=gcp/gke-cluster/dev/terraform.tfstate" ...
terraform plan  -var-file="values/dev.tfvars" -var="project_id=your-project-id"
```
