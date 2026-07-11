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
│   │   │   └── eks/               EKS cluster + user node group (CMK)
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

## CMK Coverage (Verified)

### Azure AKS
| Resource | Encrypted | How |
|----------|-----------|-----|
| AKS node OS disks | ✅ Yes | Disk Encryption Set referencing Key Vault CMK |
| AKS etcd secrets | ✅ Yes | Key Vault CMK via cluster identity |
| Azure Files NFS (PostgreSQL PVC) | ✅ Yes | Storage account CMK via user-assigned identity |

### AWS EKS ✅ Verified working
| Resource | Encrypted | Verified |
|----------|-----------|---------|
| EKS etcd secrets | ✅ Yes | `cluster.encryptionConfig` → `resources: [secrets]` |
| EBS node root volume (50GB) | ✅ Yes | `vol-04ecce2c384cec9e3` → `Encrypted: True` |
| EFS file system (PostgreSQL NFS) | ✅ Yes | `fs-06fad7d246a81992d` → `Encrypted: True` |
| KMS key | ✅ Enabled | `a7f2e41f-399a-4ab6-8cde-d9307187942b` |

All three resources use the **same KMS key** (`eks-dev-cmk`):
```
arn:aws:kms:us-east-1:730335612245:key/a7f2e41f-399a-4ab6-8cde-d9307187942b
```

### GCP GKE
| Resource | Encrypted | How |
|----------|-----------|-----|
| GKE etcd secrets | ✅ Yes | Cloud KMS CMEK via `database_encryption` block |
| GKE node boot disks | ✅ Yes | `boot_disk_kms_key` on node pool |
| Filestore NFS (PostgreSQL PVC) | ✅ Yes | `kms_key_name` on Filestore instance |

---

## Node Pool Design

| Pool | Purpose | Taint | Clouds |
|------|---------|-------|--------|
| System | Kubernetes system components only | `CriticalAddonsOnly=true:NoSchedule` | Azure, GCP |
| User | App workloads + PostgreSQL pods | None | Azure, AWS, GCP |

> **Note:** AWS EKS dev environment uses **user node pool only** (`enable_system_node_group = false`) to reduce cost and complexity. Set `enable_system_node_group = true` in `staging.tfvars` and `prod.tfvars` for a proper split.

---

## AWS KMS Key Policy Design

The KMS key policy includes the following principals to ensure nodes can decrypt EBS volumes at launch time — missing any of these causes `Client.InternalError` and immediate instance termination:

| Principal | Why needed |
|-----------|-----------|
| Root account | Prevents accidental key lockout |
| Terraform deployer | Manages key during apply/destroy |
| `eks.amazonaws.com` | etcd secrets encryption |
| `elasticfilesystem.amazonaws.com` | EFS NFS encryption |
| `AWSServiceRoleForAutoScaling` IAM role | EBS volume encryption on node launch |
| `ec2.amazonaws.com` | EBS volume operations |
| `eks-dev-cluster-nodes-role` IAM role | Node boot disk decryption |

Additionally, two **KMS Grants** are created by Terraform:
- `eks-dev-cluster-nodes-ebs-grant` — granted to node IAM role
- `eks-dev-cluster-autoscaling-ebs-grant` — granted to AutoScaling service-linked role

> Belt-and-suspenders: both key policy **and** grants ensure access regardless of IAM propagation timing.

---

## Verify CMK is Working (AWS)

Run after apply to confirm all resources are CMK encrypted:

```bash
# 1. EKS etcd encryption
aws eks describe-cluster \
  --name eks-dev-cluster \
  --region us-east-1 \
  --query "cluster.encryptionConfig[].{Resources:resources,KeyArn:provider.keyArn}" \
  --output table

# 2. KMS key status
aws kms describe-key \
  --key-id alias/eks-dev-cmk \
  --region us-east-1 \
  --query "KeyMetadata.{KeyId:KeyId,State:KeyState,Description:Description}" \
  --output table

# 3. KMS grants
KEY_ID=$(aws kms describe-key \
  --key-id alias/eks-dev-cmk \
  --region us-east-1 \
  --query "KeyMetadata.KeyId" --output text)
aws kms list-grants \
  --key-id "$KEY_ID" \
  --region us-east-1 \
  --query "Grants[].{Name:Name,Grantee:GranteePrincipal}" \
  --output table

# 4. EBS volumes encrypted
aws ec2 describe-volumes \
  --region us-east-1 \
  --filters "Name=tag:eks:cluster-name,Values=eks-dev-cluster" \
  --query "Volumes[].{ID:VolumeId,Encrypted:Encrypted,KmsKeyId:KmsKeyId,Size:Size}" \
  --output table

# 5. EFS encrypted
aws efs describe-file-systems \
  --region us-east-1 \
  --query "FileSystems[?Tags[?Key=='Name' && Value=='eks-dev-postgres-efs']].{ID:FileSystemId,Encrypted:Encrypted,KmsKeyId:KmsKeyId}" \
  --output table

# 6. Node group status
aws eks describe-nodegroup \
  --cluster-name eks-dev-cluster \
  --nodegroup-name eks-dev-cluster-user \
  --region us-east-1 \
  --query "nodegroup.{Status:status,InstanceType:instanceTypes,Health:health.issues}" \
  --output json
```

**Expected results (all verified on 2026-07-11):**
- etcd: `resources: [secrets]` with KMS key ARN ✅
- KMS key: `State: Enabled` ✅
- EBS: `Encrypted: True` with KMS key ARN ✅
- EFS: `Encrypted: True` with KMS key ARN ✅
- Node group: `Status: ACTIVE`, `Health: []` ✅

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

Before running the pipeline for the first time, create the S3 bucket, DynamoDB lock table, and IAM user.

### Using the setup script

```bash
# 1. Edit the script — set your bucket name (must be globally unique)
vi setup-s3-backend.sh

# 2. Run it
bash setup-s3-backend.sh
```

**Note for us-east-1:** The bucket is created without `--create-bucket-configuration` — handled automatically by the script.

### Cleaning up the backend

```bash
bash cleanup-s3-backend.sh
```

Deletes in correct order: S3 object versions → bucket → DynamoDB table → IAM keys → policy → user.

---

## GitHub Secrets Required

Go to **repo → Settings → Secrets and variables → Actions → New repository secret**:

### S3 Backend (all clouds)

| Secret | Description |
|--------|-------------|
| `TF_STATE_BUCKET` | S3 bucket name |
| `TF_STATE_LOCK_TABLE` | DynamoDB table name (`terraform-state-lock`) |
| `AWS_ACCESS_KEY_ID` | IAM access key for S3/DynamoDB access |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key |
| `AWS_REGION` | S3 bucket region (e.g. `us-east-1`) |

### Azure

| Secret | Description |
|--------|-------------|
| `ARM_CLIENT_ID` | Service principal `appId` |
| `ARM_CLIENT_SECRET` | Service principal `password` |
| `ARM_TENANT_ID` | Azure AD `tenant` ID |
| `ARM_SUBSCRIPTION_ID` | Azure subscription ID |

```bash
# Login
az login --use-device-code

# Create service principal
MSYS_NO_PATHCONV=1 az ad sp create-for-rbac \
  --name "github-actions-terraform" \
  --role "Contributor" \
  --scopes "/subscriptions/<subscription-id>"

# Grant role assignment permission
MSYS_NO_PATHCONV=1 az role assignment create \
  --assignee <appId> \
  --role "User Access Administrator" \
  --scope "/subscriptions/<subscription-id>"
```

> **Git Bash on Windows:** Always prefix Azure CLI commands with `MSYS_NO_PATHCONV=1`

### AWS (resource provisioning)

| Secret | Description |
|--------|-------------|
| `AWS_PROVIDER_ACCESS_KEY_ID` | IAM key for EKS/VPC/KMS/EFS provisioning |
| `AWS_PROVIDER_SECRET_ACCESS_KEY` | IAM secret key |
| `AWS_PROVIDER_REGION` | AWS region (e.g. `us-east-1`) |

> Attach `AdministratorAccess` policy to the provisioner IAM user for lab use.

### GCP

| Secret | Description |
|--------|-------------|
| `GCP_CREDENTIALS` | Full contents of a service account JSON key file |
| `GCP_PROJECT_ID` | GCP project ID |

---

## Before First Apply — Update tfvars

### Azure
```hcl
key_vault_name                = "kv-aksdev-yourname"   # globally unique, 3-24 chars
storage_account_name          = "staksdevyourname"      # globally unique, lowercase only
kv_purge_protection_enabled   = true                    # required for CMK with storage
```

### AWS
```hcl
kubernetes_version       = "1.36"          # latest EKS version
enable_system_node_group = false           # single user pool for dev
user_node_instance_types = ["t3.large"]   # good availability + cost
```

### GCP
```hcl
project_id = "your-real-gcp-project-id"
```

---

## Running the Pipeline

Go to **Actions → Terraform → Run workflow**:

| Input | Options |
|-------|---------|
| Cloud | `azure` / `aws` / `gcp` |
| Environment | `dev` / `qa` / `staging` / `prod` |
| Action | `plan` / `apply` / `destroy` |
| Branch | any branch (default: `main`) |

### Recommended first-run order
```
1. cloud=azure  env=dev  action=plan    ← verify plan first
2. cloud=azure  env=dev  action=apply
3. cloud=aws    env=dev  action=plan
4. cloud=aws    env=dev  action=apply
5. cloud=gcp    env=dev  action=plan
6. cloud=gcp    env=dev  action=apply
```

> ⚠️ **Never cancel a pipeline mid-apply** — it causes state drift where resources exist in the cloud but not in Terraform state, requiring manual cleanup.

---

## After Apply — Kubernetes StorageClass

After apply, a StorageClass YAML is written to `./k8s-manifests/` and uploaded as a pipeline artifact:

```bash
# Azure
kubectl apply -f k8s-manifests/azure-files-nfs-storageclass.yaml

# AWS (install EFS CSI driver first)
kubectl apply -f k8s-manifests/efs-postgres-storageclass.yaml

# GCP (install Filestore CSI driver first)
kubectl apply -f k8s-manifests/filestore-postgres-storageclass.yaml
```

PostgreSQL PVC example:
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

---

## Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Please run 'az login'` | Azure secrets missing | Add `ARM_*` secrets to GitHub |
| `The value cannot be empty` | S3 backend secrets missing | Add `TF_STATE_BUCKET`, `AWS_REGION` etc. |
| `InvalidLocationConstraint` | `us-east-1` bucket creation quirk | Use setup script — handles this automatically |
| `Client.InternalError` on EC2 | Node role missing KMS access | Fixed in code: key policy now includes node role + AutoScaling service-linked role + KMS grants |
| `InsufficientVCPUQuota` | VM family quota exceeded | Change VM size in tfvars or request quota increase |
| `NetworkAclsValidationFailure` | Missing `Microsoft.Storage` service endpoint | Fixed in code: added to AKS user subnet |
| `must be configured for Purge Protection` | Key Vault missing purge protection | Set `kv_purge_protection_enabled = true` in tfvars |
| `ResourceInUseException` | Pipeline cancelled mid-apply, resources exist but not in state | Delete resources manually then re-run apply |
| `Error acquiring state lock` | Previous run didn't release DynamoDB lock | Delete lock: `aws dynamodb delete-item --table-name terraform-state-lock --key '{"LockID":{"S":"<bucket>/<key>"}}'` |
| `state data in S3 does not match checksum` | S3 state deleted but DynamoDB checksum remains | Delete checksum: same command above but append `-md5` to the LockID value |
| `MSYS_NO_PATHCONV` path error | Git Bash converts `/subscriptions/...` to Windows path | Prefix command with `MSYS_NO_PATHCONV=1` |
| `MalformedPolicyDocumentException` | KMS key policy locks out caller | Fixed in code: added explicit caller ARN to key policy |
| `InvalidParameterValue` on Security Group | Em-dash `—` in description field | Fixed in code: replaced with plain hyphen `-` |

---

## Destroy / Cleanup

Run pipeline with `action=destroy` per environment. For AWS, some resources require manual cleanup if pipeline was cancelled:

```bash
# Delete EKS node groups first
aws eks delete-nodegroup --cluster-name eks-dev-cluster --nodegroup-name eks-dev-cluster-user --region us-east-1
aws eks wait nodegroup-deleted --cluster-name eks-dev-cluster --nodegroup-name eks-dev-cluster-user --region us-east-1

# Then run pipeline destroy
# cloud=aws | env=dev | action=destroy
```

KMS keys have a minimum 7-day deletion waiting period:
```bash
aws kms schedule-key-deletion \
  --key-id alias/eks-dev-cmk \
  --pending-window-in-days 7 \
  --region us-east-1

aws kms delete-alias --alias-name alias/eks-dev-cmk --region us-east-1
```