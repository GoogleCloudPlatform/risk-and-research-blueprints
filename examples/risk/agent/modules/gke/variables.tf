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


#
# Mandatory configuration
#

# Project ID where resources will be deployed
variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created."
}

# Region where the build and artifact repository is
variable "region" {
  type        = string
  description = "The Region of the build"
}

# Zones for resource deployment (default: us-central1 [a-d])
variable "zones" {
  type        = list(string)
  description = "The GCP zones to deploy resources to."
  default     = ["a", "b", "c"]
}

variable "cluster_name" {
  type    = string
  default = "gke-risk-research"
}

variable "artifact_registry" {
  type = object({
    project  = string
    location = string
    name     = string
  })
}

# Containers to build
variable "agent_image" {
  type        = string
  description = "Agent image for Cloud Run templates"
}

# Containers to build
variable "workload_image" {
  type        = string
  description = "Map of image name to configuration (source)"
}

# Sidecar configuration
variable "workload_grpc_endpoint" {
  type        = string
  description = ""
}

variable "workload_args" {
  type = list(string)
}

variable "dashboard" {
  type    = string
  default = "dashboards/risk-platform-overview.json"
}


#
# Optional functionality
# (Review suggested)
#

# Configurations to create shell scripts for
variable "test_configs" {
  type = map(object({
    parallel = number
    testfile = string
  }))
  default     = {}
  description = "Test configurations (parallel = 0 use autoscaler)"
}

variable "workload_init_args" {
  type        = list(list(string))
  default     = []
  description = "Workload initialization arguments to run"
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


#
# Naming defaults
# (Only change if conflicting with other modules)
#

variable "gke_job_request" {
  type    = string
  default = "gke_job_request"
}
variable "gke_job_response" {
  type    = string
  default = "gke_job_response"
}
variable "gke_hpa_request" {
  type    = string
  default = "gke_hpa_request"
}
variable "gke_hpa_response" {
  type    = string
  default = "gke_hpa_response"
}
