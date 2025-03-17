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

# Project Setup

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
variable "regions" {
  description = "List of regions where GKE clusters should be created"
  type        = list(string)
  default     = ["us-central1"]

  validation {
    condition     = length(var.regions) <= 4
    error_message = "Maximum 4 regions supported"
  }
}

# Zones for resource deployment (default: us-central1 [a-d])
variable "zones" {
  type        = list(string)
  description = "The GCP zones to deploy resources to."
  default     = ["a", "b", "c"]
}

# Quota

# Request additional quota for a scaled load test run
variable "additional_quota_enabled" {
  description = "Enable quota requests for additional"
  type        = bool
  default     = false
}
# Contact email for Quota requests
variable "quota_contact_email" {
  description = "Your contact email for the quota request"
  type        = string
  default     = "null"
}

# GKE Standard

# Number of GKE Standard Clusters per region
variable "clusters_per_region" {
  description = "Map of regions to number of clusters to create in each"
  type        = map(number)
  default     = { "us-central1" = 1 }

  validation {
    condition     = alltrue([for count in values(var.clusters_per_region) : count <= 4])
    error_message = "Maximum 4 clusters per region allowed"
  }
}

# GKE Standard cluster name
variable "gke_standard_cluster_name" {
  type        = string
  description = "Name of GKE cluster"
  default     = "gke-risk-research"
}

# Enable/disable initial deployment of a large nodepool for control plane nodes (default: false)
variable "scaled_control_plane" {
  type        = bool
  description = "Deploy a larger initial nodepool to ensure larger control plane nodes are provisied"
  default     = false
}

# Max Cluster CPU's
variable "cluster_max_cpus" {
  type        = number
  default     = 10000
  description = "Max CPU in cluster autoscaling resource limits"
}

# Max Cluster Memory
variable "cluster_max_memory" {
  type        = number
  default     = 80000
  description = "Max memory in cluster autoscaling resource limits"
}


# Parallelstore

# Enable/disable Parallelstore deployment (default: false)
variable "parallelstore_enabled" {
  type        = bool
  description = "Enable or disable the deployment of Parallelstore."
  default     = false
}

variable "deployment_type" {
  description = "Parallelstore Instance deployment type" # SCRATCH or PERSISTENT
  type        = string
  default     = "SCRATCH"
}

variable "parallelstore_zone" {
  description = "The zone to host the parallelstore instance in e.g. a, b or c"
  type        = string
  default     = null
}

# Artifact Registry

variable "artifact_registry_name" {
  description = "Name of the Artifact Registry"
  type        = string
  default     = "research-images"
}

# Identity

variable "cluster_service_account" {
  description = "Service Account to use for GKE clusters"
  type        = string
  default     = "gke-risk-research-cluster-sa"
}
