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

output "cluster_name" {
  description = "Name of the deployed GKE Autopilot cluster for use in kubectl commands and referencing in other resources"
  value       = google_container_cluster.default.name
}

output "endpoint" {
  description = "Control plane endpoint configuration for the GKE Autopilot cluster including DNS endpoints and external access configuration"
  value       = google_container_cluster.default.control_plane_endpoints_config[0]
}
