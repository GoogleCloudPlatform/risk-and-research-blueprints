# Multi-Region Quota Request Example

This example demonstrates how to use the Quota module to request quota increases for multiple regions and services in a Google Cloud project.

## Overview

The multi-quota example shows how to:

- Request different quotas for different regions (us-central1, us-east4)
- Request global quotas that don't have a region dimension
- Organize quota requests by region for better maintainability
- Use the `concat` function to combine quota requests

## Usage

```hcl
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
```

## Prerequisites

- A Google Cloud project with billing enabled
- A contact email for quota requests
- Appropriate permissions to request quota increases

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| project_id | The Google Cloud project ID | `string` | Yes |
| quota_contact_email | Contact email for quota requests | `string` | Yes |

## Outputs

| Name | Description |
|------|-------------|
| quota_preferences | Map of created quota preferences |
| requested_quota_count | Number of quota preferences requested |

## Notes

- Quota requests are sent to Google Cloud for approval and are not guaranteed to be approved
- Requests may take time to process
- The lifecycle configuration ignores changes after creation since quota updates are handled by Google Cloud
- If no contact email is provided, no quota preferences will be created

## License

Copyright 2024 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
