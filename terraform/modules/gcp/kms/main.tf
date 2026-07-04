################################################################################
# GCP KMS Module
# Creates: KMS keyring + CryptoKey (CMEK) for GKE etcd, Filestore, and PD
################################################################################

resource "google_kms_key_ring" "keyring" {
  name     = "${var.prefix}-keyring"
  location = var.location
  project  = var.project_id
}

resource "google_kms_crypto_key" "cmk" {
  name            = "${var.prefix}-cmk"
  key_ring        = google_kms_key_ring.keyring.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    # Prevent accidental deletion — destroying a key permanently destroys encrypted data
    prevent_destroy = true
  }
}

# ── Grant GKE service account access to use the CMK for etcd encryption ───────
# GKE's default service account needs this to encrypt/decrypt etcd secrets.

data "google_project" "project" {
  project_id = var.project_id
}

resource "google_kms_crypto_key_iam_member" "gke_encrypt" {
  crypto_key_id = google_kms_crypto_key.cmk.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@container-engine-robot.iam.gserviceaccount.com"
}

# Grant the GCS service account access (for cluster bootstrap)
resource "google_kms_crypto_key_iam_member" "gcs_encrypt" {
  crypto_key_id = google_kms_crypto_key.cmk.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# Grant the Filestore service account access (for NFS CMEK)
resource "google_kms_crypto_key_iam_member" "filestore_encrypt" {
  crypto_key_id = google_kms_crypto_key.cmk.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@cloud-filer.iam.gserviceaccount.com"
}

# Grant Compute Engine service account access (for PD/boot disk encryption)
resource "google_kms_crypto_key_iam_member" "compute_encrypt" {
  crypto_key_id = google_kms_crypto_key.cmk.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
}
