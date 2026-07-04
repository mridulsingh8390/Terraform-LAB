################################################################################
# AWS EFS Module
# Creates: EFS file system (CMK-encrypted) + mount targets in each subnet
# Writes the EFS CSI StorageClass YAML to disk for kubectl apply
################################################################################

resource "aws_efs_file_system" "postgres" {
  creation_token  = "${var.prefix}-postgres-efs"
  encrypted       = true
  kms_key_id      = var.kms_key_arn
  throughput_mode = var.throughput_mode

  performance_mode = var.performance_mode

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, { Name = "${var.prefix}-postgres-efs" })
}

# ── Mount targets — one per subnet (AZ) so pods on any node can mount ─────────

resource "aws_efs_mount_target" "postgres" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.postgres.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}

# ── EFS Access Point — gives PostgreSQL pods an isolated directory ─────────────
# Access point enforces UID/GID 999 (standard PostgreSQL container user)

resource "aws_efs_access_point" "postgres" {
  file_system_id = aws_efs_file_system.postgres.id

  posix_user {
    uid = 999
    gid = 999
  }

  root_directory {
    path = "/postgres"
    creation_info {
      owner_uid   = 999
      owner_gid   = 999
      permissions = "0750"
    }
  }

  tags = merge(var.tags, { Name = "${var.prefix}-efs-ap-postgres" })
}

# ── Kubernetes StorageClass manifest ─────────────────────────────────────────

resource "local_file" "storageclass" {
  filename = "${var.k8s_manifest_output_path}/efs-postgres-storageclass.yaml"
  content  = <<-YAML
    # EFS CSI StorageClass for PostgreSQL PVC
    # CMK encryption is enforced at the EFS file system level.
    # Prerequisites: install the EFS CSI driver on EKS first:
    #   kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-2.0"
    # Then apply: kubectl apply -f efs-postgres-storageclass.yaml
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: efs-postgres-cmk
    provisioner: efs.csi.aws.com
    reclaimPolicy: Retain
    volumeBindingMode: Immediate
    parameters:
      provisioningMode: efs-ap
      fileSystemId:     ${aws_efs_file_system.postgres.id}
      directoryPerms:   "0750"
      basePath:         /postgres
      uid:              "999"
      gid:              "999"
    mountOptions:
      - tls
      - iam
  YAML
}
