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

# Request additional Quota
module "quota" {
  count               = var.additional_quota_enabled ? 1 : 0
  source              = "../../terraform/modules/quota"
  project_id          = data.google_project.environment.project_id
  region              = var.region
  quota_contact_email = var.quota_contact_email
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
  zones                = var.zones
  network              = module.networking.network
  subnet               = module.networking.subnet-1.id
  ip_range_services    = module.networking.subnet-1.secondary_ip_range[0].range_name
  ip_range_pods        = module.networking.subnet-1.secondary_ip_range[1].range_name
  depends_on           = [module.project, module.networking]
  scaled_control_plane = var.scaled_control_plane
  artifact_registry    = module.artifact_registry.artifact_registry
}

# Conditionall create a GKE Autpilot cluster
module "gke_autopilot" {
  count             = var.gke_autopilot_enabled ? 1 : 0
  source            = "../modules/gke-autopilot"
  project_id        = data.google_project.environment.project_id
  region            = var.region
  network           = module.networking.network
  subnet            = module.networking.subnet-2.id
  ip_range_services = module.networking.subnet-2.secondary_ip_range[0].range_name
  ip_range_pods     = module.networking.subnet-2.secondary_ip_range[1].range_name
  depends_on        = [module.project, module.networking]
}

# Create a Parallestore Instance
module "parallelstore" {
  count      = var.parallelstore_enabled ? 1 : 0
  source     = "../modules/parallelstore"
  project_id = data.google_project.environment.project_id
  region     = var.region
  network    = module.networking.network
}

# Artifact Registry for Images
module "artifact_registry" {
  source     = "../../../terraform/modules/artifact-registry"
  region     = var.region
  project_id = data.google_project.environment.project_id
}
