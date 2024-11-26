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

resource "google_cloud_quotas_quota_preference" "spot_cpus" {
  count         = var.quota_contact_email != "" ? 1 : 0
  parent        = "projects/${var.project_id}"
  name          = "compute_googleapis_com-PREEMPTIBLE-CPUS-per-project-region_${var.region}"
  dimensions    = { region = "${var.region}" }
  service       = "compute.googleapis.com"
  quota_id      = "PREEMPTIBLE-CPUS-per-project-region"
  contact_email = var.quota_contact_email
  quota_config {
    preferred_value = var.spot_cpus
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "google_cloud_quotas_quota_preference" "pd_disks" {
  count         = var.quota_contact_email != "" ? 1 : 0
  parent        = "projects/${var.project_id}"
  name          = "compute_googleapis_com-DISKS-TOTAL-GB-per-project-region_${var.region}"
  dimensions    = { region = "${var.region}" }
  service       = "compute.googleapis.com"
  quota_id      = "DISKS-TOTAL-GB-per-project-region"
  contact_email = var.quota_contact_email
  quota_config {
    preferred_value = var.PD
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "google_cloud_quotas_quota_preference" "monitoring_ingestion_requests" {
  count         = var.quota_contact_email != "" ? 1 : 0
  parent        = "projects/${var.project_id}"
  name          = "monitoring_googleapis_com_IngestionRequestsPerMinutePerProject_${var.region}"
  service       = "monitoring.googleapis.com"
  quota_id      = "IngestionRequestsPerMinutePerProject"
  contact_email = var.quota_contact_email
  quota_config {
    preferred_value = var.ingestion_requests
  }
  lifecycle {
    ignore_changes = all
  }
}
