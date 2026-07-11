################################################################################
# AWS EKS Module
# Creates: EKS cluster (CMK envelope encryption of etcd secrets),
# system + user managed node groups (EBS volumes CMK-encrypted),
# required IAM roles
################################################################################

data "aws_caller_identity" "current" {}

# ── IAM Role — EKS cluster control plane ──────────────────────────────────────

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ── IAM Role — EKS managed node group ────────────────────────────────────────

resource "aws_iam_role" "eks_nodes" {
  name = "${var.cluster_name}-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "nodes_worker_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "nodes_cni_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "nodes_ecr_readonly" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EFS CSI driver — nodes need this to mount EFS volumes
resource "aws_iam_role_policy_attachment" "nodes_efs_policy" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}

# ── Launch template — enforces CMK encryption on EBS root volumes ─────────────

resource "aws_launch_template" "nodes" {
  name_prefix = "${var.cluster_name}-node-lt-"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.node_volume_size_gb
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 required — security best practice
    http_put_response_hop_limit = 1
  }

  tags = var.tags
}

# ── EKS Cluster ────────────────────────────────────────────────────────────────

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = [var.node_security_group_id]
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = true
  }

  # CMK envelope encryption of Kubernetes secrets in etcd
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn
    }
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
  ]
}

# ── System node group (optional) — runs kube-system pods only ────────────────
# Disabled by default for dev — set enable_system_node_group = true for prod

resource "aws_eks_node_group" "system" {
  count           = var.enable_system_node_group ? 1 : 0
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-system"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids

  instance_types = var.system_node_instance_types

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  scaling_config {
    desired_size = var.system_node_desired
    min_size     = var.system_node_min
    max_size     = var.system_node_max
  }

  update_config {
    max_unavailable = 1
  }

  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  labels = {
    "nodepool-type" = "system"
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-system-node" })

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker_policy,
    aws_iam_role_policy_attachment.nodes_cni_policy,
    aws_iam_role_policy_attachment.nodes_ecr_readonly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ── User node group — runs app + PostgreSQL pods ──────────────────────────────

resource "aws_eks_node_group" "user" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-user"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.subnet_ids

  instance_types = var.user_node_instance_types

  launch_template {
    id      = aws_launch_template.nodes.id
    version = aws_launch_template.nodes.latest_version
  }

  scaling_config {
    desired_size = var.user_node_desired
    min_size     = var.user_node_min
    max_size     = var.user_node_max
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    "nodepool-type" = "user"
    "workload"      = "application"
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-user-node" })

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker_policy,
    aws_iam_role_policy_attachment.nodes_cni_policy,
    aws_iam_role_policy_attachment.nodes_ecr_readonly,
    aws_iam_role_policy_attachment.nodes_efs_policy,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# ── OIDC Provider — enables IRSA (IAM Roles for Service Accounts) ─────────────

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer

  tags = var.tags
}

# ── KMS grants — allows node role and AutoScaling to use CMK for EBS ─────────
# Belt-and-suspenders: key policy (in kms module) + grants here both grant
# access so nodes can decrypt EBS volumes on launch regardless of policy
# propagation timing.

resource "aws_kms_grant" "nodes_ebs" {
  name              = "${var.cluster_name}-nodes-ebs-grant"
  key_id            = var.kms_key_arn
  grantee_principal = aws_iam_role.eks_nodes.arn

  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "ReEncryptTo",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "DescribeKey",
    "CreateGrant",
  ]
}

resource "aws_kms_grant" "autoscaling_ebs" {
  name              = "${var.cluster_name}-autoscaling-ebs-grant"
  key_id            = var.kms_key_arn
  grantee_principal = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"

  operations = [
    "Encrypt",
    "Decrypt",
    "ReEncryptFrom",
    "ReEncryptTo",
    "GenerateDataKey",
    "GenerateDataKeyWithoutPlaintext",
    "DescribeKey",
    "CreateGrant",
  ]
}
