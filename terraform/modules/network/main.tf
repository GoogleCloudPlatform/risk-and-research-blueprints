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

locals {
  region_number = index(var.regions, var.region)

  dynamic_region_indices = { for region in var.regions : region => "region-${index(var.regions, region)}" }

  network_cidrs = {
    nodes = cidrsubnet("10.0.0.0/8", 8, local.region_number)
    pods = {
      "region-0" = "172.16.0.0/12"
      "region-1" = "172.32.0.0/12"
      "region-2" = "172.48.0.0/12"
      "region-3" = "172.64.0.0/12"
    }[local.dynamic_region_indices[var.region]]
    services = cidrsubnet("192.168.0.0/16", 6, local.region_number)
  }

  capacity = {
    max_nodes_per_region    = 65536   # /16
    max_pods_per_region     = 1048574 # /12
    max_services_per_region = 1024    # /22

    max_nodes_per_cluster    = floor(65536 / 4) # 16384 nodes
    max_pods_per_cluster     = 524288           # Adjust as needed, within /12 limit
    max_services_per_cluster = floor(1024 / 4)  # 256 services

    max_supported_regions = 4
  }
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet-${var.region}"
  project       = data.google_project.environment.project_id
  ip_cidr_range = local.network_cidrs.nodes
  region        = var.region
  network       = var.vpc_id

  # Secondary ranges for GKE
  secondary_ip_range {
    range_name    = "pods-range-${var.region}"
    ip_cidr_range = local.network_cidrs.pods
  }

  secondary_ip_range {
    range_name    = "services-range-${var.region}"
    ip_cidr_range = local.network_cidrs.services
  }

  # Enable flow logs (optional but recommended)
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Create Cloud Router
resource "google_compute_router" "router" {
  name    = "gke-router-${var.region}"
  project = data.google_project.environment.project_id
  region  = var.region
  network = var.vpc_id

  bgp {
    asn = 64514 + local.region_number
  }
}

# Create NAT configuration
resource "google_compute_router_nat" "nat" {
  name                               = "gke-nat-${var.region}"
  project                            = data.google_project.environment.project_id
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
