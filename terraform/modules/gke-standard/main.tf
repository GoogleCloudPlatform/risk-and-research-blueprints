# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  zones = flatten([for zone in var.zones : [for letter in split(",", zone) : "${var.region}-${letter}"]])
}

data "google_project" "environment" {
  project_id = var.project_id
}

resource "google_container_cluster" "risk-research" {
  deletion_protection = false
  provider            = google-beta
  name                = var.cluster_name
  project             = var.project_id
  location            = var.region
  datapath_provider   = "ADVANCED_DATAPATH"
  node_locations      = local.zones

  # We do this to ensure we have large control plane nodes created initially
  initial_node_count       = var.scaled_control_plane ? 700 : 1
  remove_default_node_pool = true

  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true
    }
  }

  node_config {
    service_account = google_service_account.cluster_service_account.email
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
    machine_type = "e2-standard-2"
    preemptible  = false
  }

  network    = var.network
  subnetwork = var.subnet

  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.gke-key.id
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.32/28"
    # TODO - Enabled for easier testing
    master_global_access_config {
      enabled = true
    }
  }

  # Mainteance only on Weekends
  # 4am UTC = 12am EST
  maintenance_policy {
    recurring_window {
      start_time = "2024-09-17T04:00:00Z"
      end_time   = "2024-09-18T04:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
    }
  }

  enable_intranode_visibility              = true
  enable_cilium_clusterwide_network_policy = true

  monitoring_config {
    advanced_datapath_observability_config {
      enable_metrics = true
      enable_relay   = false
    }

    enable_components = [
      "SYSTEM_COMPONENTS",
      "STORAGE",
      "POD",
      "DEPLOYMENT",
      "STATEFULSET",
      "DAEMONSET",
      "HPA",
      "CADVISOR",
      "KUBELET",
      "APISERVER",
      "SCHEDULER",
      "CONTROLLER_MANAGER"
    ]
    managed_prometheus {
      enabled = true
    }
  }
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "APISERVER",
      "CONTROLLER_MANAGER",
      "SCHEDULER",
      "WORKLOADS"
    ]
  }

  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = var.ip_range_services
    cluster_secondary_range_name  = var.ip_range_pods
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  # Adding gcfs_config to enable image streaming on the cluster.
  node_pool_defaults {

    node_config_defaults {
      logging_variant = "MAX_THROUGHPUT"
      gcfs_config {
        enabled = true
      }
    }
  }

  # Support for mTLS
  mesh_certificates {
    enable_certificates = false
  }

  dns_config {
    cluster_dns       = "CLOUD_DNS"
    cluster_dns_scope = "CLUSTER_SCOPE"
  }

  addons_config {
    gcp_filestore_csi_driver_config {
      enabled = false
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    dns_cache_config {
      enabled = true
    }
    # parallelstore_csi_driver_config {
    #   enabled = true
    # }
  }

  cluster_autoscaling {
    enabled             = true
    autoscaling_profile = "OPTIMIZE_UTILIZATION"

    resource_limits {
      resource_type = "cpu"
      minimum       = 4
      maximum       = var.cluster_max_cpus
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 16
      maximum       = var.cluster_max_memory
    }

    resource_limits {
      resource_type = "nvidia-a100-80gb"
      maximum       = 30
    }

    resource_limits {
      resource_type = "nvidia-l4"
      maximum       = 30
    }

    resource_limits {
      resource_type = "nvidia-tesla-t4"
      maximum       = 300
    }

    resource_limits {
      resource_type = "nvidia-tesla-a100"
      maximum       = 50
    }

    resource_limits {
      resource_type = "nvidia-tesla-k80"
      maximum       = 30
    }

    resource_limits {
      resource_type = "nvidia-tesla-p4"
      maximum       = 30
    }

    resource_limits {
      resource_type = "nvidia-tesla-p100"
      maximum       = 30
    }

    resource_limits {
      resource_type = "nvidia-tesla-v100"
      maximum       = 30
    }

    auto_provisioning_defaults {
      management {
        auto_repair  = true
        auto_upgrade = true
      }

      shielded_instance_config {
        enable_integrity_monitoring = true
        enable_secure_boot          = true
      }

      upgrade_settings {
        strategy        = "SURGE"
        max_surge       = 1
        max_unavailable = 0
      }
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
      service_account = google_service_account.cluster_service_account.email
    }
  }
  release_channel {
    channel = "REGULAR"
  }

  secret_manager_config {
    enabled = true
  }

  lifecycle {

    # Once deleted the node_config will change. We can ignore this.
    ignore_changes = [
      node_config,
    ]
  }

}


resource "google_container_node_pool" "primary_ondemand_nodes" {
  name           = "ondemand-node-1"
  provider       = google-beta
  project        = var.project_id
  location       = var.region
  cluster        = google_container_cluster.risk-research.name
  node_locations = local.zones

  autoscaling {
    location_policy      = "ANY"
    total_min_node_count = 0
    total_max_node_count = 32
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }


  node_config {
    logging_variant = "MAX_THROUGHPUT"
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    preemptible  = false
    machine_type = "n2-standard-16"

    # Can be used for GCS Node Cache
    # local_nvme_ssd_block_config {
    #   local_ssd_count = 2
    # }

    labels = {
      "resource-model" : "n2"
      "resource-type" : "cpu"
      "billing-type" : "on-demand"
    }
    gvnic {
      enabled = true
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.cluster_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [
      node_config,
    ]
  }
}

resource "google_container_node_pool" "primary_spot_nodes" {
  name           = "spot-nodes-1"
  provider       = google-beta
  project        = var.project_id
  location       = var.region
  cluster        = google_container_cluster.risk-research.name
  node_locations = local.zones

  autoscaling {
    location_policy      = "ANY"
    total_min_node_count = 0
    total_max_node_count = 750
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  node_config {
    logging_variant = "MAX_THROUGHPUT"
    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    preemptible  = true
    machine_type = "n2-standard-64"

    # Boot Disk Config
    # disk_type = "pd-ssd"
    # disk_size_gb = "200"

    labels = {
      "resource-model" : "n2"
      "resource-type" : "cpu"
      "billing-type" : "spot"
    }
    gvnic {
      enabled = true
    }

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.cluster_service_account.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  lifecycle {
    ignore_changes = [
      node_config,
    ]
  }
}

resource "google_service_account" "cluster_service_account" {
  account_id   = "gke-risk-research-cluster-sa"
  display_name = "gke-risk-research-cluster-sa"
  project      = data.google_project.environment.project_id
}

resource "google_project_iam_member" "monitoring_viewer" {
  project = data.google_project.environment.project_id
  role    = "roles/container.serviceAgent"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
}

resource "google_artifact_registry_repository_iam_member" "artifactregistry_reader" {
  project    = data.google_project.environment.project_id
  location   = var.artifact_registry.location
  repository = var.artifact_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cluster_service_account.email}"
}

# KMS for Encryption

resource "random_string" "random" {
  length           = 5
  special          = true
  override_special = "_-"
}

resource "google_kms_key_ring" "gke-keyring" {
  name     = "gke-keyring-${random_string.random.id}"
  project  = data.google_project.environment.project_id
  location = var.region
}

resource "google_kms_crypto_key" "gke-key" {
  name            = "gke-key"
  key_ring        = google_kms_key_ring.gke-keyring.id
  rotation_period = "7776000s"
  purpose         = "ENCRYPT_DECRYPT"
}

resource "google_kms_crypto_key_iam_member" "gke_crypto_key" {
  crypto_key_id = google_kms_crypto_key.gke-key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.environment.number}@container-engine-robot.iam.gserviceaccount.com"
}
