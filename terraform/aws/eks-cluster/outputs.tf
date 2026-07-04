output "vpc_id" {
  value = module.vpc.vpc_id
}

output "kms_key_arn" {
  value = module.kms.key_arn
}

output "efs_id" {
  value = module.efs.efs_id
}

output "storageclass_manifest_path" {
  value = module.efs.storageclass_manifest_path
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "cluster_oidc_issuer" {
  value = module.eks.cluster_oidc_issuer
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
