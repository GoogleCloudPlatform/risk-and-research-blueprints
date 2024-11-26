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

resource "google_compute_network" "research-vpc" {
  name                    = "research-vpc"
  project                 = data.google_project.environment.project_id
  auto_create_subnetworks = false
  mtu                     = 8896 # 10% performance gain for Parallelstore
  # enable_ula_internal_ipv6 = true
}

# Subnet Config for GKE
# Up to 4092 node(s) per cluster.
# Up to 64 service(s) per cluster.
# Up to 110 pods per node.

resource "google_compute_subnetwork" "cluster-1" {
  count         = var.gke_standard_enabled ? 1 : 0
  name          = "cluster-1"
  project       = data.google_project.environment.project_id
  ip_cidr_range = "10.64.0.0/20"
  region        = var.region
  stack_type    = "IPV4_ONLY"

  network = google_compute_network.research-vpc.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.64.32.0/26"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "10.0.0.0/11"
  }
}

resource "google_compute_subnetwork" "cluster-2" {
  count         = var.gke_autopilot_enabled ? 1 : 0
  name          = "cluster-2"
  project       = data.google_project.environment.project_id
  ip_cidr_range = "10.64.16.0/20"
  region        = var.region

  stack_type = "IPV4_ONLY"

  network = google_compute_network.research-vpc.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "10.64.32.64/26"
  }

  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = "10.32.0.0/11"
  }
}

resource "google_compute_router" "router" {
  name    = "cloud-router-${var.region}"
  project = data.google_project.environment.project_id
  region  = var.region
  network = google_compute_network.research-vpc.id

  bgp {
    asn = 64514
  }

  depends_on = [google_compute_network.research-vpc]
}

resource "google_compute_router_nat" "nat" {
  name                               = "cloud-nat-${var.region}"
  project                            = data.google_project.environment.project_id
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  depends_on = [google_compute_router.router]

}
