output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value     = aws_eks_cluster.eks.endpoint
  sensitive = true
}

output "cluster_ca_data" {
  value     = aws_eks_cluster.eks.certificate_authority[0].data
  sensitive = true
}

output "cluster_oidc_issuer" {
  description = "OIDC issuer URL — used for IRSA service account federation"
  value       = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "node_role_arn" {
  description = "IAM role ARN for EKS nodes — attach extra policies here"
  value       = aws_iam_role.eks_nodes.arn
}
