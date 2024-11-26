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

# Project ID where resources will be deployed
variable "project_id" {
  type        = string
  default     = "YOUR_PROJECT_ID"
  description = "The GCP project ID where resources will be created."

  # Validation to ensure the project_id is set
  validation {
    condition     = var.project_id != "YOUR_PROJECT_ID"
    error_message = "The 'project_id' variable must be set in terraform.tfvars or on the command line."
  }
}

# Region for resource deployment (default: us-central1)
variable "region" {
  type        = string
  description = "The GCP region to deploy resources to."
  default     = "us-central1"
}

# Enable/disable Parallelstore deployment (default: false)
variable "parallelstore_enabled" {
  type        = bool
  description = "Enable or disable the deployment of Parallelstore."
  default     = false
}

# Enable/disable GKE Standard cluster deployment (default: true)
variable "gke_standard_enabled" {
  type        = bool
  description = "Enable or disable the deployment of a GKE Standard cluster."
  default     = true
}

# Enable/disable GKE Autopilot cluster deployment (default: false)
variable "gke_autopilot_enabled" {
  type        = bool
  description = "Enable or disable the deployment of a GKE Autopilot cluster."
  default     = false
}
# Enable/disable initial deployment of a large nodepool for control plane nodes (default: false)
variable "scaled_control_plane" {
  type        = bool
  description = "Deploy a larger initial nodepool to ensure larger control plane nodes are provisied"
  default     = false
}

variable "dashboard" {
  type    = string
  default = "dashboards/monte-carlo-overview.json"
}
