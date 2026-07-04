output "vpc_name" {
  value = module.vpc.vpc_name
}

output "kms_cmk_id" {
  value = module.kms.cmk_id
}

output "filestore_ip" {
  description = "Filestore NFS server IP for PV manifests"
  value       = module.filestore.filestore_ip
}

output "filestore_share_name" {
  value = module.filestore.filestore_share_name
}

output "storageclass_manifest_path" {
  value = module.filestore.storageclass_manifest_path
}

output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_endpoint" {
  value     = module.gke.cluster_endpoint
  sensitive = true
}

output "workload_identity_pool" {
  value = module.gke.workload_identity_pool
}
