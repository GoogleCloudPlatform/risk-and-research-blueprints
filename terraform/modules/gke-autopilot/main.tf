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
    # service_account = var.cluster_service_account.email
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
      service_account = var.cluster_service_account.email
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

resource "google_project_iam_member" "monitoring_viewer" {
  project = data.google_project.environment.project_id
  role    = "roles/container.serviceAgent"
  member  = "serviceAccount:${var.cluster_service_account.email}"
}

resource "google_artifact_registry_repository_iam_member" "artifactregistry_reader" {
  project    = data.google_project.environment.project_id
  location   = var.artifact_registry.location
  repository = var.artifact_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.cluster_service_account.email}"
}
