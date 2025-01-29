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

output "subnet_id" {
  description = "ID of the created subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "subnet_name" {
  description = "Name of the created subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "pod_range_name" {
  description = "Name of the pods secondary range"
  value       = "pods-range-${var.region}"
}

output "service_range_name" {
  description = "Name of the services secondary range"
  value       = "services-range-${var.region}"
}

output "nat_ip" {
  description = "NAT IP addresses"
  value       = google_compute_router_nat.nat.nat_ips
}

output "router_id" {
  description = "Cloud Router ID"
  value       = google_compute_router.router.id
}


# output "subnet-1" {
#   description = "Standard Subnet"
#   value = length(google_compute_subnetwork.cluster-1) > 0 ? {
#     name               = google_compute_subnetwork.cluster-1[0].name
#     id                 = google_compute_subnetwork.cluster-1[0].id
#     secondary_ip_range = google_compute_subnetwork.cluster-1[0].secondary_ip_range
#   } : null
# }

# output "subnet-2" {
#   description = "Standard Subnet"
#   value = length(google_compute_subnetwork.cluster-2) > 0 ? {
#     name               = google_compute_subnetwork.cluster-2[0].name
#     id                 = google_compute_subnetwork.cluster-2[0].id
#     secondary_ip_range = google_compute_subnetwork.cluster-2[0].secondary_ip_range
#   } : null
# }
