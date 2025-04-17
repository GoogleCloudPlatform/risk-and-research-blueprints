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

# Example usage of the quota module to request multiple quotas

module "multi_region_quotas" {
  source = "../../../terraform/modules/quota"

  project_id          = var.project_id
  quota_contact_email = var.quota_contact_email

  # Request quotas for multiple regions
  quota_preferences = concat(
    # US Central 1 quotas
    [
      {
        service         = "compute.googleapis.com"
        quota_id        = "PREEMPTIBLE-CPUS-per-project-region"
        preferred_value = 10000
        region          = "us-central1"
      },
      {
        service         = "compute.googleapis.com"
        quota_id        = "DISKS-TOTAL-GB-per-project-region"
        preferred_value = 65000
        region          = "us-central1"
      }
    ],
    # US East 1 quotas
    [
      {
        service         = "compute.googleapis.com"
        quota_id        = "PREEMPTIBLE-CPUS-per-project-region"
        preferred_value = 5000
        region          = "us-east4"
      },
      {
        service         = "compute.googleapis.com"
        quota_id        = "DISKS-TOTAL-GB-per-project-region"
        preferred_value = 30000
        region          = "us-east4"
      }
    ],
    # Global quotas (no region dimension)
    [
      {
        service         = "monitoring.googleapis.com"
        quota_id        = "IngestionRequestsPerMinutePerProject"
        preferred_value = 100000
      },
      {
        service         = "pubsub.googleapis.com"
        quota_id        = "messagePublishRequestsPerMinutePerProject"
        preferred_value = 200000
      }
    ]
  )
}
