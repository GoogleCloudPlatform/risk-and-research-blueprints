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

data "google_project" "environment" {
  project_id = var.project_id
}


resource "google_container_cluster" "default" {
  name     = "example-autopilot-cluster"
  project  = data.google_project.environment.project_id
  provider = google-beta


  location         = var.region
  enable_autopilot = true

  node_config {
    # service_account = google_service_account.cluster_service_account.email
    gvnic {
      enabled = true
    }
    reservation_affinity {
      consume_reservation_type = "NO_RESERVATION"
    }
  }



  network    = var.network
  subnetwork = var.subnet



  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = var.ip_range_services
    cluster_secondary_range_name  = var.ip_range_pods
  }

  deletion_protection = false
  release_channel {
    channel = "RAPID"
  }

  cluster_autoscaling {
    auto_provisioning_defaults {
      service_account = google_service_account.cluster_service_account.email
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
    }
  }

  secret_manager_config {
    enabled = true
  }

  addons_config {
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    # Not Supported for autopilot or terraform yet
    # parallelstore_config {
    #   enabled = true
    # }
  }

  private_cluster_config {
    # Set to false for testing
    enable_private_endpoint = false
    enable_private_nodes    = true
  }


  monitoring_config {
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


}

resource "google_service_account" "cluster_service_account" {
  account_id   = "gke-cluster-sa"
  display_name = "gke-cluster-sa"
  project      = data.google_project.environment.project_id
}

resource "google_project_iam_member" "monitoring_viewer" {
  project = data.google_project.environment.project_id
  role    = "roles/container.serviceAgent"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
}

# Artifact Registry
resource "google_artifact_registry_repository" "research-images" {
  project       = data.google_project.environment.project_id
  location      = var.region
  repository_id = "research-images"
  description   = "Images"
  format        = "DOCKER"
  # Keep only 10 latest images in docker repo
  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
  docker_config {
    immutable_tags = true
  }
}

resource "google_artifact_registry_repository_iam_member" "gke-cluster-access" {
  project    = google_artifact_registry_repository.research-images.project
  location   = google_artifact_registry_repository.research-images.location
  repository = google_artifact_registry_repository.research-images.name
  role       = "roles/artifactregistry.reader"
  # Get output from GKE SA
  member = "serviceAccount:${google_service_account.cluster_service_account.email}"
}

# TODO - Look to move these somewhere else away from Infra
resource "google_project_iam_member" "pubsub_subscriber" {
  project = data.google_project.environment.project_id
  role    = "roles/pubsub.subscriber"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${google_container_cluster.default.name}"
  # member = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/${var.htcexample-namespace}"
}

resource "google_project_iam_member" "pubsub_publisher" {
  project = data.google_project.environment.project_id
  role    = "roles/pubsub.publisher"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${google_container_cluster.default.name}"
  # member = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/${var.htcexample-namespace}"
}

resource "google_project_iam_member" "pubsub_viewer" {
  project = data.google_project.environment.project_id
  role    = "roles/pubsub.viewer"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${google_container_cluster.default.name}"
  # member = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/${var.htcexample-namespace}"
}


resource "google_project_iam_member" "example_monitoring_viewer" {
  project = data.google_project.environment.project_id
  role    = "roles/monitoring.viewer"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${google_container_cluster.default.name}"
  # member = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/${var.htcexample-namespace}"
}

resource "google_artifact_registry_repository_iam_member" "artifactregistry_reader" {
  project    = google_artifact_registry_repository.research-images.project
  location   = google_artifact_registry_repository.research-images.location
  repository = google_artifact_registry_repository.research-images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cluster_service_account.email}"
}
