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


output "region_mapping" {
  description = "Map of regions to their multi-region parent"
  value       = local.region_mapping
}

output "region_counts" {
  description = "Count of regions in each multi-region"
  value       = local.region_counts
}

output "dominant_region" {
  description = "The multi-region with the most regions (preferring US in ties)"
  value       = local.dominant_region
}

output "default_region" {
  description = "First alphabetical region from the dominant multi-region"
  value       = local.default_region
}

output "regions_in_dominant" {
  description = "All regions in the dominant multi-region"
  value       = local.regions_in_dominant
}
