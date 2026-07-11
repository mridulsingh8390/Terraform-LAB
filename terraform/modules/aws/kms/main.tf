################################################################################
# AWS KMS Module
# Creates: KMS Customer Managed Key + alias used to encrypt
#   - EKS cluster secrets (envelope encryption of etcd)
#   - EBS volumes attached to EKS nodes
#   - EFS file system (NFS for PostgreSQL PVC)
#
# FIX: Key policy now includes node role ARN and AutoScaling service-linked
# role directly — this prevents Client.InternalError on node launch caused
# by nodes being unable to decrypt their CMK-encrypted EBS root volumes.
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "cmk" {
  description             = "${var.prefix} CMK - encrypts EKS, EBS, EFS"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Root account — full control, prevents accidental lockout
      {
        Sid    = "AllowRootAccountFullControl"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # Calling IAM user/role (Terraform deployer) — full control
      {
        Sid    = "AllowCallerFullControl"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # EKS service — for etcd secrets envelope encryption
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
      # EFS service — for NFS file system encryption
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
      # AutoScaling service-linked role — for EBS encryption on node launch
      # Must use the IAM role ARN, not the service principal, for EBS grants
      {
        Sid    = "AllowAutoScalingEBSEncryption"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
      },
      # EC2 service — for EBS volume operations during instance launch
      {
        Sid    = "AllowEC2EBSEncryption"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
      },
      # EKS node IAM role — decrypt EBS volumes on node boot
      # This is the critical fix: nodes must be able to use the key
      # before they can mount their root volume and start up.
      {
        Sid    = "AllowEKSNodeRoleEBSAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-cluster-nodes-role"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:GenerateDataKeyWithoutPlaintext",
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
