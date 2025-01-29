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

variable "project_id" {
  description = "The GCP project where the resources will be created"
  type        = string

  validation {
    condition     = var.project_id != "YOUR_PROJECT_ID"
    error_message = "'project_id' was not set, please set the value in the fsi-resaerch-1.tfvars file"
  }
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "The zones for cluster nodes"
  type        = list(string)
  default     = ["a", "b", "c"]
}

variable "network" {
  description = "The vpc the cluster should be deployed to"
  type        = string
  default     = "default"
}

variable "subnet" {
  description = "The subnet the cluster should be deployed to"
  type        = string
  default     = "default"
}

variable "ip_range_pods" {
  type        = string
  description = "The _name_ of the secondary subnet ip range to use for pods"
}

variable "ip_range_services" {
  type        = string
  description = "The _name_ of the secondary subnet range to use for services"
}

variable "scaled_control_plane" {
  type        = bool
  description = "Deploy a larger initial nodepool to ensure larger control plane nodes are provisied"
  default     = false
}

variable "cluster_name" {
  type        = string
  description = "Name of GKE cluster"
  default     = "gke-risk-research"
}

variable "cluster_service_account" {
  description = "The service account for the GKE cluster"
  type = object({
    email = string
    id    = string
  })
}

variable "artifact_registry" {
  type = object({
    project  = string
    location = string
    name     = string
  })
}

variable "cluster_max_cpus" {
  type        = number
  default     = 10000
  description = "Max CPU in cluster autoscaling resource limits"
}

variable "cluster_max_memory" {
  type        = number
  default     = 80000
  description = "Max memory in cluster autoscaling resource limits"
}
