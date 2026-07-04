output "keyring_id" {
  value = google_kms_key_ring.keyring.id
}

output "cmk_id" {
  description = "CMK CryptoKey ID — used by GKE, Filestore, and PD for CMEK"
  value       = google_kms_crypto_key.cmk.id
}

output "cmk_name" {
  description = "CMK CryptoKey resource name (fully qualified)"
  value       = google_kms_crypto_key.cmk.name
}
