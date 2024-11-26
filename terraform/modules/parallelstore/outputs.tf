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

output "reserved_ip_range" {
  description = "Contains the id of the allocated IP address range associated with the private service access connection"
  value       = google_parallelstore_instance.parallelstore.reserved_ip_range
}

output "daos_version" {
  description = "The version of DAOS software running in the instance"
  value       = google_parallelstore_instance.parallelstore.daos_version
}

output "id" {
  description = "An identifier for the resource with format projects/{{project}}/locations/{{location}}/instances/{{instance_id}}"
  value       = google_parallelstore_instance.parallelstore.id
}

output "name" {
  description = "An identifier for the resource with format projects/{{project}}/locations/{{location}}/instances/{{name}}"
  value       = google_parallelstore_instance.parallelstore.name
}

output "access_points" {
  description = "List of access_points. Contains a list of IPv4 addresses used for client side configuration."
  value       = google_parallelstore_instance.parallelstore.access_points
}
