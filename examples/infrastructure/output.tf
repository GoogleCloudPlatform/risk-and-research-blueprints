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

output "gke_clusters" {
  description = "List of GKE cluster names and their regions"
  value = [
    for k, cluster in module.gke_standard : {
      cluster_name = cluster.cluster_name
      region       = cluster.region
      endpoint     = cluster.endpoint
    }
  ]
}

output "artifact_registry" {
  value = {
    name              = module.artifact_registry.artifact_registry.name
    url               = module.artifact_registry.artifact_registry_url
    artifact_registry = module.artifact_registry.artifact_registry
    id                = module.artifact_registry.artifact_registry_id
    location          = module.artifact_registry.artifact_registry_region
  }
}

output "vpc" {
  description = "The VPC resource being created"
  value = {
    id   = google_compute_network.research-vpc.id
    name = google_compute_network.research-vpc.name
    mtu  = google_compute_network.research-vpc.mtu
  }
}

output "subnets" {
  description = "Map of networking resources per region"
  value = {
    for region, network in module.networking : region => {
      subnet_id          = network.subnet_id
      service_range_name = network.service_range_name
      pod_range_name     = network.pod_range_name
    }
  }
}

output "parallelstore_instances" {
  description = "Map of Parallelstore instances per region"
  value = {
    for region, instance in module.parallelstore : region => {
      name     = instance.name_short
      access_points = instance.access_points
      location = instance.location
      region = instance.region
      id = instance.id
      capacity_gib = instance.capacity_gib
    }
  }
}

output "cluster_service_account" {
  description = "The service account used by GKE clusters"
  value = {
    email = google_service_account.cluster_service_account.email
    id    = google_service_account.cluster_service_account.id
    name  = google_service_account.cluster_service_account.name
  }
}