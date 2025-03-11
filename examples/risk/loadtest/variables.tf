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
# Required parameters
#

# Project ID where resources will be deployed
variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be created."

  # Validation to ensure the project_id is set
  validation {
    condition     = var.project_id != "YOUR_PROJECT_ID"
    error_message = "The 'project_id' variable must be set in terraform.tfvars or on the command line."
  }
}

variable "clusters_per_region" {
  description = "Map of regions to number of clusters to create in each"
  type        = map(number)
  default     = { "us-central1" = 1 }

  validation {
    condition     = alltrue([for count in values(var.clusters_per_region) : count <= 4])
    error_message = "Maximum 4 clusters per region allowed"
  }
}


variable "regions" {
  description = "List of regions where GKE clusters should be created"
  type        = list(string)
  default     = ["us-central1"]

  validation {
    condition     = length(var.regions) <= 4
    error_message = "Maximum 4 regions supported"
  }
}

#
# Enable / Disable Cloud Run
#

variable "cloudrun_enabled" {
  description = "Enable Cloud Run deployment"
  type        = bool
  default     = true
}

#
# Optional configuration
#

# Output testing scripts folder (default: ./generated)
variable "scripts_output" {
  type        = string
  description = "Output for testing scripts"
  default     = "./generated"
}

# Enable/disable UI image build (default: false)
variable "ui_image_enabled" {
  type        = bool
  description = "Enable or disable the building of the ui image."
  default     = false
}

# Enable/disable Parallelstore deployment (default: false)
variable "parallelstore_enabled" {
  type        = bool
  description = "Enable or disable the deployment of Parallelstore."
  default     = false
}
# Deployment type for Parallelstore SCRATCH or PERSISTENT (default: SCRATCH)
variable "deployment_type" {
  description = "Parallelstore Instance deployment type"
  type        = string
  default     = "SCRATCH"
}

variable "parallelstore_zone" {
  description = "The zone to host the parallelstore instance in e.g. a, b or c"
  type        = string
  default     = null
}

# Enable/disable initial deployment of a large nodepool for control plane nodes (default: false)
variable "scaled_control_plane" {
  type        = bool
  description = "Deploy a larger initial nodepool to ensure larger control plane nodes are provisied"
  default     = false
}

# Max CPU's for GKE Cluster
variable "cluster_max_cpus" {
  type        = number
  default     = 10000
  description = "Max CPU in cluster autoscaling resource limits"
}

# Max memory for GKE Cluster
variable "cluster_max_memory" {
  type        = number
  default     = 80000
  description = "Max memory in cluster autoscaling resource limits"
}

# Request additional quota for a scaled load test run
variable "additional_quota_enabled" {
  description = "Enable quota requests for additional"
  type        = bool
  default     = false
}

variable "enable_csi_parallelstore" {
  description = "Enable the Parallelstore CSI Driver"
  type        = bool
  default     = true
}

variable "enable_csi_filestore" {
  description = "Enable the Filestore CSI Driver"
  type        = bool
  default     = false
}

variable "enable_csi_gcs_fuse" {
  description = "Enable the GCS Fuse CSI Driver"
  type        = bool
  default     = true
}

# Contact email for Quota requests
variable "quota_contact_email" {
  description = "Your contact email for the quota request"
  type        = string
  default     = ""
}

# Enable Pub/Sub exactly once subscriptions
variable "pubsub_exactly_once" {
  type        = bool
  default     = true
  description = "Enable Pub/Sub exactly once subscriptions"
}

# Enable hierarchical namespace GCS buckets
variable "hsn_bucket" {
  description = "Enable hierarchical namespace GCS buckets"
  type = bool
  default = false
}


#
# Naming customization
#

# Pub/Sub topic to send task requests to.
variable "request_topic" {
  description = "Request topic for tasks"
  type        = string
  default     = "request"
}

# Pub/Sub subscription to receive task requests from.
variable "request_subscription" {
  description = "Request subscription for tasks"
  type        = string
  default     = "request_sub"
}

# Pub/Sub topic to send task responses to.
variable "response_topic" {
  description = "Response topic for tasks"
  type        = string
  default     = "response"
}

# Pub/Sub subscription to receive task responses from.
variable "response_subscription" {
  description = "Response subscription for tasks"
  type        = string
  default     = "response_sub"
}

# BigQuery dataset for storing Pub/Sub messages.
variable "dataset_id" {
  description = "BigQuery dataset in the project to create the tables"
  type        = string
  default     = "pubsub_msgs"
}