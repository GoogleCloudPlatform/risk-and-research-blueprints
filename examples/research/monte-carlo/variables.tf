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
  description = "The GCP project ID where Monte Carlo simulation resources will be created."

  # Validation to ensure the project_id is set
  validation {
    condition     = var.project_id != "YOUR_PROJECT_ID"
    error_message = "The 'project_id' variable must be set in terraform.tfvars or on the command line."
  }
}

variable "regions" {
  description = "List of GCP regions where GKE clusters for Monte Carlo workloads should be created"
  type        = list(string)
  default     = ["us-central1"]

  validation {
    condition     = length(var.regions) <= 1
    error_message = "This example supports a single region"
  }
}

variable "clusters_per_region" {
  description = "Map of GCP regions to number of GKE clusters to create for Monte Carlo simulations"
  type        = map(number)
  default     = { "us-central1" = 1 }

  validation {
    condition     = alltrue([for count in values(var.clusters_per_region) : count <= 1])
    error_message = "This example supports a single cluster"
  }
}

variable "dashboard" {
  type    = string
  default = "dashboards/monte-carlo-overview.json"
}
