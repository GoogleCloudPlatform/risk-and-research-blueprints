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

data "google_project" "environment" {
  project_id = var.project_id
}

# Get available zones for the region
data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

# Random zone selection
resource "random_shuffle" "zone" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

# Create Parallelstore instance
resource "google_parallelstore_instance" "parallelstore" {
  project         = var.project_id
  provider        = google-beta
  instance_id     = var.zone == null ? "parallelstore-${random_shuffle.zone.result[0]}" : "parallelstore-${var.region}-${var.zone}"
  location        = var.zone == null ? random_shuffle.zone.result[0] : "${var.region}-${var.zone}"
  capacity_gib    = var.deployment_type == "PERSISTENT" ? 27000 : 12000
  network         = var.network
  deployment_type = var.deployment_type
  # file_stripe_level = "FILE_STRIPE_LEVEL_MAX"
  # directory_stripe_level = "DIRECTORY_STRIPE_LEVEL_MAX"
}
