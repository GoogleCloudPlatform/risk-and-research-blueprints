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
  source     = "../../../terraform/modules/project"
  project_id = data.google_project.environment.project_id
  region     = var.region
}

# Module to create VPC network and subnets
module "networking" {
  source                = "../../../terraform/modules/network"
  project_id            = data.google_project.environment.project_id
  region                = var.region
  depends_on            = [module.project]
  gke_standard_enabled  = var.gke_standard_enabled
  gke_autopilot_enabled = var.gke_autopilot_enabled
}

# Conditionally create a GKE Standard cluster
module "gke_standard" {
  count                = var.gke_standard_enabled ? 1 : 0
  source               = "../../../terraform/modules/gke-standard"
  project_id           = data.google_project.environment.project_id
  region               = var.region
  network              = module.networking.network
  subnet               = module.networking.subnet-1.id
  ip_range_services    = module.networking.subnet-1.secondary_ip_range[0].range_name
  ip_range_pods        = module.networking.subnet-1.secondary_ip_range[1].range_name
  depends_on           = [module.project, module.networking]
  scaled_control_plane = var.scaled_control_plane
  artifact_registry    = module.artifact_registry.artifact_registry
}

module "artifact_registry" {
  source     = "../../../terraform/modules/artifact-registry"
  region     = var.region
  project_id = data.google_project.environment.project_id
}

# Example Specific
# resource "google_storage_bucket" "gkebatch" {
#   name                        = "gkebatch-${random_string.random.result}"
#   project                     = data.google_project.environment.project_id
#   location                    = "US"
#   force_destroy               = true
#   uniform_bucket_level_access = true
# }
# Copy python_write.py into the GCS Bucket
# This is now done in the toolkit configuration
# resource "google_storage_bucket_object" "python_write" {
#   name         = "python_write.py"
#   source       = "${path.module}/src/tutorial_files/gke_batch.py"
#   content_type = "text/plain"
#   bucket       = google_storage_bucket.gkebatch.id
# }

# resource "random_string" "random" {
#   length  = 8
#   lower   = true
#   special = false
#   upper   = false
# }

# Example IAM
resource "google_project_iam_member" "storage_objectuser" {
  for_each   = toset(["a", "b"])
  project    = data.google_project.environment.project_id
  role       = "roles/storage.objectUser"
  member     = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/team-${each.value}"
  depends_on = [module.gke_standard]
}

resource "google_project_iam_member" "pubsub_publisher" {
  for_each   = toset(["a", "b"])
  project    = data.google_project.environment.project_id
  role       = "roles/pubsub.publisher"
  member     = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/team-${each.value}"
  depends_on = [module.gke_standard]
}

resource "google_project_iam_member" "pubsub_viewer" {
  for_each   = toset(["a", "b"])
  project    = data.google_project.environment.project_id
  role       = "roles/pubsub.viewer"
  member     = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/team-${each.value}"
  depends_on = [module.gke_standard]
}

# Monitoring Dashboard
resource "google_monitoring_dashboard" "risk-platform-overview" {
  project        = data.google_project.environment.project_id
  dashboard_json = file("${path.module}/${var.dashboard}")
  lifecycle {
    ignore_changes = [dashboard_json]
  }
}
