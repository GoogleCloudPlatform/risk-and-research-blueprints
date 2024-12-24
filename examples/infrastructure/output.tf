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

output "network" {
  description = "network"
  value       = module.networking.network
}

output "subnet_1" {
  description = "Standard Subnet"
  value       = module.networking.subnet-1
}

output "subnet_2" {
  description = "Autopilot Subnet"
  value       = module.networking.subnet-2
}

output "cluster_service_account" {
  description = "Cluster Service Account"
  value       = google_service_account.cluster_service_account
}

output "artifact_registry" {
  value = {
    name              = module.artifact_registry.artifact_registry.name
    url               = module.artifact_registry.artifact_registry_url
    artifact_registry = module.artifact_registry.artifact_registry
  }
}

output "parallelstore_instance" {
  description = "Parallelstore Instance"
  value = length(module.parallelstore[0].id) > 0 ? {
    name              = module.parallelstore.name
    id                = module.parallelstore.id
    access_points     = module.parallelstore.access_points
    reserved_ip_range = module.parallelstore.reserved_ip_range
  } : null
}
