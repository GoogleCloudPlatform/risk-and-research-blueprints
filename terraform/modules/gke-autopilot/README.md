# Google Kubernetes Engine (GKE) Autopilot Module

This module creates a Google Kubernetes Engine (GKE) Autopilot cluster optimized for risk and research workloads, providing a fully managed Kubernetes experience with automatic scaling and management.

## Usage

```hcl
module "gke_autopilot" {
  source = "github.com/GoogleCloudPlatform/risk-and-research-blueprints//terraform/modules/gke-autopilot"

  project_id           = "your-project-id"
  region               = "us-central1"
  cluster_name         = "risk-research-ap-cluster"
  network              = google_compute_network.vpc.id
  subnet               = google_compute_subnetwork.subnet.id
  ip_range_services    = "gke-services-range"
  ip_range_pods        = "gke-pods-range"
  cluster_service_account = google_service_account.gke_sa
  artifact_registry = {
    project  = "your-project-id"
    location = "us-central1"
    name     = "research-images"
  }
}
```

## Features

- Fully managed Kubernetes cluster with Autopilot mode
- Automatic scaling and node management
- Enhanced security with KMS encryption
- Integrated monitoring and logging
- Support for private clusters
- Workload identity for secure access to Google Cloud services
- Integration with Artifact Registry for container images

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | The GCP project where the resources will be created | `string` | n/a | yes |
| region | The region to host the cluster in | `string` | `"us-central1"` | no |
| cluster_name | Name of GKE cluster | `string` | `"gke-ap-risk-research"` | no |
| network | The VPC network ID where the cluster will be created | `string` | `"default"` | no |
| subnet | The subnetwork ID where the cluster will be created | `string` | `"default"` | no |
| ip_range_services | The secondary IP range name for services | `string` | n/a | yes |
| ip_range_pods | The secondary IP range name for pods | `string` | n/a | yes |
| cluster_service_account | The service account for the GKE cluster | `object` | n/a | yes |
| artifact_registry | Configuration for Artifact Registry integration | `object` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the created GKE cluster |
| cluster_name | The name of the created GKE cluster |
| cluster_location | The location (region) of the GKE cluster |
| cluster_endpoint | The endpoint for the GKE cluster |
| cluster_ca_certificate | The CA certificate for the GKE cluster |
| cluster_self_link | The self-link of the GKE cluster |

## Notes

- Autopilot clusters are fully managed by Google, with automatic scaling and node configuration
- Resource allocation is based on pod requests and limits
- The module creates necessary KMS keys for cluster encryption
- Integration with Artifact Registry allows for seamless container deployment
- Autopilot offers simplified operations at a slightly higher cost than Standard GKE

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
