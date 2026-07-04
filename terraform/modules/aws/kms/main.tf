################################################################################
# AWS KMS Module
# Creates: KMS Customer Managed Key + alias used to encrypt
#   - EKS cluster secrets (envelope encryption of etcd)
#   - EBS volumes attached to EKS nodes
#   - EFS file system (NFS for PostgreSQL PVC)
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "cmk" {
  description             = "${var.prefix} CMK — encrypts EKS, EBS, EFS"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Account root: full control (required — without this you can lock yourself out)
      {
        Sid    = "AllowRootAccountFullControl"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # EKS service: use the key for envelope encryption of cluster secrets
      {
        Sid    = "AllowEKSSecretsEncryption"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
      },
      # EFS service: use the key to encrypt the file system
      {
        Sid    = "AllowEFSEncryption"
        Effect = "Allow"
        Principal = {
          Service = "elasticfilesystem.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
      },
      # AutoScaling service: needs access to encrypt EBS volumes on new nodes
      {
        Sid    = "AllowAutoScalingEBSEncryption"
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
      },
    ]
  })

  tags = merge(var.tags, { Name = "${var.prefix}-cmk" })
}

resource "aws_kms_alias" "cmk" {
  name          = "alias/${var.prefix}-cmk"
  target_key_id = aws_kms_key.cmk.key_id
}
