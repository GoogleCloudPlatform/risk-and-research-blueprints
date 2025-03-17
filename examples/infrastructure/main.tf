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

# Retrieve Google Cloud project information
data "google_project" "environment" {
  project_id = var.project_id
}

# Module to manage project-level settings and API enablement
module "project" {
  source     = "../../terraform/modules/project"
  project_id = data.google_project.environment.project_id
}

# Request additional Quota
# module "quota" {
#   count               = var.additional_quota_enabled ? 1 : 0
#   source              = "../../terraform/modules/quota"
#   project_id          = data.google_project.environment.project_id
#   region              = var.region
#   quota_contact_email = var.additional_quota_enabled ? var.quota_contact_email : "null"
# }

# Module to create VPC network and subnets
resource "google_compute_network" "research-vpc" {
  name                    = "research-vpc"
  project                 = data.google_project.environment.project_id
  auto_create_subnetworks = false
  mtu                     = 8896 # 10% performance gain for Parallelstore
  # enable_ula_internal_ipv6 = true
}

module "networking" {
  for_each   = toset(var.regions)
  region     = each.key
  regions    = var.regions
  source     = "../../terraform/modules/network"
  project_id = data.google_project.environment.project_id
  depends_on = [module.project]
  vpc_id     = google_compute_network.research-vpc.id
  vpc_name   = google_compute_network.research-vpc.name

}

# Conditionally create a GKE Standard cluster
module "gke_standard" {
  source = "../../terraform/modules/gke-standard"
  # count                   = var.gke_standard_enabled ? 1 : 0
  for_each = {
    for entry in flatten([
      for region, count in var.clusters_per_region : [
        for index in range(count) : {
          key           = "${region}-${index}"
          region        = region
          cluster_index = index
        }
      ]
    ]) : entry.key => entry
  }
  cluster_index           = each.value.cluster_index
  cluster_name            = "${var.gke_standard_cluster_name}-${each.value.region}-${each.value.cluster_index}"
  project_id              = data.google_project.environment.project_id
  region                  = each.value.region
  zones                   = var.zones
  network                 = google_compute_network.research-vpc.id
  subnet                  = module.networking[each.value.region].subnet_id
  ip_range_services       = module.networking[each.value.region].service_range_name
  ip_range_pods           = module.networking[each.value.region].pod_range_name
  depends_on              = [google_service_account.cluster_service_account, module.project, module.networking]
  scaled_control_plane    = var.scaled_control_plane
  artifact_registry       = module.artifact_registry.artifact_registry
  cluster_max_cpus        = var.cluster_max_cpus
  cluster_max_memory      = var.cluster_max_memory
  cluster_service_account = google_service_account.cluster_service_account
}

# Create a Parallestore Instance
module "parallelstore" {
  for_each        = var.parallelstore_enabled ? toset(var.regions) : []
  source          = "../../terraform/modules/parallelstore"
  project_id      = data.google_project.environment.project_id
  region          = each.key
  network         = google_compute_network.research-vpc.id
  zone            = var.parallelstore_zone
  deployment_type = var.deployment_type
  depends_on = [
    google_service_networking_connection.default,
    google_compute_global_address.parallelstore_range
  ]
}

# Artifact Registry for Images
module "artifact_registry" {
  source     = "../../terraform/modules/artifact-registry"
  regions    = var.regions
  project_id = data.google_project.environment.project_id
}

# GKE IAM
# Service Account for clusters
resource "google_service_account" "cluster_service_account" {
  account_id   = var.cluster_service_account
  display_name = var.cluster_service_account
  project      = data.google_project.environment.project_id
}

resource "google_project_iam_member" "monitoring_viewer" {
  project = data.google_project.environment.project_id
  role    = "roles/container.serviceAgent"
  member  = "serviceAccount:${google_service_account.cluster_service_account.email}"
}

resource "google_artifact_registry_repository_iam_member" "artifactregistry_reader" {
  project    = data.google_project.environment.project_id
  location   = module.artifact_registry.artifact_registry.location
  repository = module.artifact_registry.artifact_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cluster_service_account.email}"
}

#Parallelstore Networking
resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.research-vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.parallelstore_range.name]
}

resource "google_compute_global_address" "parallelstore_range" {
  project       = data.google_project.environment.project_id
  name          = "parallelstore-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.research-vpc.id
  address       = "172.16.0.0"
}

# resource "google_compute_network_peering" "parallelstore" {
#   name         = "servicenetworking-googleapis-com"
#   network      = google_compute_network.research-vpc.id
#   peer_network = "projects/${var.project_id}/global/networks/servicenetworking-googleapis-com"
#   export_subnet_routes_with_public_ip = true
#   import_subnet_routes_with_public_ip = true
# }

# TODO: This is a Hack until we can do this in terraform
resource "null_resource" "update_peering_routes" {
  triggers = {
    network_id = google_compute_network.research-vpc.id
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud compute networks peerings update servicenetworking-googleapis-com \
        --network=${google_compute_network.research-vpc.name} \
        --export-subnet-routes-with-public-ip \
        --import-subnet-routes-with-public-ip \
        --project=${var.project_id}
    EOT
  }

  depends_on = [
    google_service_networking_connection.default
  ]
}
