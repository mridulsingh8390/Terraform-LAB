################################################################################
# GCP Filestore Module
# Creates: Filestore instance (NFS) CMEK-encrypted, for PostgreSQL PVC
# Writes the Kubernetes StorageClass YAML to disk for kubectl apply
################################################################################

resource "google_filestore_instance" "postgres" {
  name     = "${var.prefix}-postgres-fs"
  tier     = var.tier
  location = var.zone
  project  = var.project_id

  file_shares {
    name        = "postgres_data"
    capacity_gb = var.capacity_gb
  }

  networks {
    network      = var.vpc_name
    modes        = ["MODE_IPV4"]
    connect_mode = "PRIVATE_SERVICE_ACCESS"
  }

  # CMEK encryption — reference the KMS CryptoKey
  kms_key_name = var.cmk_id

  labels = var.labels
}

# ── Kubernetes StorageClass manifest ─────────────────────────────────────────

resource "local_file" "storageclass" {
  filename = "${var.k8s_manifest_output_path}/filestore-postgres-storageclass.yaml"
  content  = <<-YAML
    # Filestore CSI StorageClass for PostgreSQL PVC
    # CMEK encryption enforced at the Filestore instance level.
    # Prerequisites: install the Filestore CSI driver:
    #   kubectl apply -k "github.com/kubernetes-sigs/gcp-filestore-csi-driver/deploy/kubernetes/overlays/stable_new"
    # Then apply: kubectl apply -f filestore-postgres-storageclass.yaml
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: filestore-postgres-cmek
    provisioner: filestore.csi.storage.gke.io
    reclaimPolicy: Retain
    volumeBindingMode: WaitForFirstConsumer
    allowVolumeExpansion: true
    parameters:
      tier:             ${var.tier}
      network:          ${var.vpc_name}
      reserved-ipv4-cidr: ${var.filestore_reserved_cidr}
    mountOptions:
      - hard
      - timeo=600
      - retrans=3
      - _netdev
      - nfsvers=3
  YAML
}
