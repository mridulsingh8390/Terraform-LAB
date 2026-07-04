################################################################################
# GCP GKE Module
# Creates: GKE cluster (Standard mode, CMEK etcd encryption),
# system node pool (CriticalAddonsOnly) + user node pool (app/PostgreSQL),
# node boot disks CMEK-encrypted
################################################################################

resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  network    = var.vpc_name
  subnetwork = var.subnet_name

  # Remove the default node pool — we manage pools explicitly below
  remove_default_node_pool = true
  initial_node_count       = 1

  # IP alias for pods/services from secondary subnet ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # CMEK encryption for etcd (Kubernetes secrets at rest)
  database_encryption {
    state    = "ENCRYPTED"
    key_name = var.cmk_id
  }

  # Workload Identity — lets pods authenticate to GCP services without keys
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Private cluster — nodes have no public IPs
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr
  }

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Shielded nodes — Secure Boot + integrity monitoring
  enable_shielded_nodes = true

  deletion_protection = var.deletion_protection

  release_channel {
    channel = var.release_channel
  }

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  resource_labels = var.labels
}

# ── System node pool ──────────────────────────────────────────────────────────

resource "google_container_node_pool" "system" {
  name       = "${var.cluster_name}-system"
  cluster    = google_container_cluster.gke.id
  location   = var.region
  project    = var.project_id

  autoscaling {
    min_node_count = var.system_node_min
    max_node_count = var.system_node_max
  }

  node_config {
    machine_type = var.system_node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-ssd"

    # CMK for node boot disks
    boot_disk_kms_key = var.cmk_id

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Workload Identity — use node service account with minimal permissions
    service_account = var.node_service_account

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Taint: only critical addon pods can schedule here
    taint {
      key    = "CriticalAddonsOnly"
      value  = "true"
      effect = "NO_SCHEDULE"
    }

    labels = {
      "nodepool-type" = "system"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ── User node pool ────────────────────────────────────────────────────────────

resource "google_container_node_pool" "user" {
  name       = "${var.cluster_name}-user"
  cluster    = google_container_cluster.gke.id
  location   = var.region
  project    = var.project_id

  autoscaling {
    min_node_count = var.user_node_min
    max_node_count = var.user_node_max
  }

  node_config {
    machine_type = var.user_node_machine_type
    disk_size_gb = var.node_disk_size_gb
    disk_type    = "pd-ssd"

    # CMK for node boot disks
    boot_disk_kms_key = var.cmk_id

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    service_account = var.node_service_account

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = {
      "nodepool-type" = "user"
      "workload"      = "application"
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# ── GKE node service account ──────────────────────────────────────────────────

resource "google_service_account" "gke_nodes" {
  count        = var.node_service_account == null ? 1 : 0
  account_id   = "${var.prefix}-gke-nodes"
  display_name = "GKE node service account for ${var.cluster_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "nodes_log_writer" {
  count   = var.node_service_account == null ? 1 : 0
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "nodes_metric_writer" {
  count   = var.node_service_account == null ? 1 : 0
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}

resource "google_project_iam_member" "nodes_artifact_reader" {
  count   = var.node_service_account == null ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes[0].email}"
}
