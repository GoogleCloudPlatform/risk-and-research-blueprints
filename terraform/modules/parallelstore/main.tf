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

resource "google_parallelstore_instance" "parallelstore" {
  project      = data.google_project.environment.project_id
  provider     = google-beta
  instance_id  = "daos-instance"
  location     = "${var.region}-a"
  capacity_gib = 12000
  network      = var.network
  # file_stripe_level = "FILE_STRIPE_LEVEL_MAX"
  # directory_stripe_level = "DIRECTORY_STRIPE_LEVEL_MAX"
  depends_on = [google_service_networking_connection.default]
}

# Create an IP address
resource "google_compute_global_address" "private_ip_alloc" {
  project       = data.google_project.environment.project_id
  name          = "address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = var.network
  provider      = google-beta
}

# Create a private connection
resource "google_service_networking_connection" "default" {
  network                 = var.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  provider                = google-beta
}

resource "google_compute_firewall" "allow-parallelstore" {
  name          = "allow-parallelstore"
  project       = data.google_project.environment.project_id
  network       = var.network
  direction     = "INGRESS"
  source_ranges = ["${google_compute_global_address.private_ip_alloc.address}/${google_compute_global_address.private_ip_alloc.prefix_length}"]

  allow {
    protocol = "tcp"
  }
  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
