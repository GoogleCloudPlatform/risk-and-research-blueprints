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

module "infrastructure" {
  source              = "../../infrastructure/infrastructure"
  project_id          = var.project_id
  regions             = var.regions
  clusters_per_region = var.clusters_per_region
}

# Example IAM
resource "google_project_iam_member" "storage_objectuser" {
  for_each   = toset(["a", "b"])
  project    = data.google_project.environment.project_id
  role       = "roles/storage.objectUser"
  member     = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/team-${each.value}"
  depends_on = [module.infrastructure]
}

resource "google_project_iam_member" "pubsub_publisher" {
  for_each   = toset(["a", "b"])
  project    = data.google_project.environment.project_id
  role       = "roles/pubsub.publisher"
  member     = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/team-${each.value}"
  depends_on = [module.infrastructure]
}

resource "google_project_iam_member" "pubsub_viewer" {
  for_each   = toset(["a", "b"])
  project    = data.google_project.environment.project_id
  role       = "roles/pubsub.viewer"
  member     = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/namespace/team-${each.value}"
  depends_on = [module.infrastructure]
}

# Monitoring Dashboard
resource "google_monitoring_dashboard" "risk-platform-overview" {
  project        = data.google_project.environment.project_id
  dashboard_json = file("${path.module}/${var.dashboard}")
  lifecycle {
    ignore_changes = [dashboard_json]
  }
}
