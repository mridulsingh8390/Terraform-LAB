output "filestore_id" {
  value = google_filestore_instance.postgres.id
}

output "filestore_ip" {
  description = "Filestore NFS server IP — used in static PV manifests"
  value       = google_filestore_instance.postgres.networks[0].ip_addresses[0]
}

output "filestore_share_name" {
  description = "Filestore share name — used in PV manifests"
  value       = google_filestore_instance.postgres.file_shares[0].name
}

output "storageclass_manifest_path" {
  value = local_file.storageclass.filename
}
