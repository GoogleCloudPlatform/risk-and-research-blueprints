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
  value       = google_compute_network.research-vpc.id
}



output "subnet-1" {
  description = "Standard Subnet"

  value = {
    name               = length(google_compute_subnetwork.cluster-1) > 0 ? google_compute_subnetwork.cluster-1[0].name : 0
    id                 = length(google_compute_subnetwork.cluster-1) > 0 ? google_compute_subnetwork.cluster-1[0].id : 0
    secondary_ip_range = length(google_compute_subnetwork.cluster-1) > 0 ? google_compute_subnetwork.cluster-1[0].secondary_ip_range : []
  }
}

output "subnet-2" {
  description = "Autopilot Subnet"
  value = {
    name               = length(google_compute_subnetwork.cluster-2) > 0 ? google_compute_subnetwork.cluster-2[0].name : 0
    id                 = length(google_compute_subnetwork.cluster-2) > 0 ? google_compute_subnetwork.cluster-2[0].id : 0
    secondary_ip_range = length(google_compute_subnetwork.cluster-2) > 0 ? google_compute_subnetwork.cluster-2[0].secondary_ip_range : []
  }
}
