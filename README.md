## Overview

Financial Services Institutions require powerful computing resources for risk analysis, quantitative analysis, and other data-heavy workloads. Google Cloud Platform (GCP) provides a scalable, high-performance, and cost-effective solution for these requirements.

This solution helps these firms standardize their compute and research platforms on Kubernetes, offering a pre-configured, optimized, and secure environment. It addresses key use cases such as research computing platforms and quantitative analysis, and also supports data analytics, visualization, and warehousing tools to complement large-scale computing workloads. Benefits include accelerated development, reduced complexity, and mitigated risks.


## Use cases

### Risk: High Throughput Compute and Data & Analytics

There are a number of components demonstrating High Throughput Compute and Data & Analytics on Google Cloud.

Risk examples rely on an [unary gRPC service](https://grpc.io/docs/what-is-grpc/core-concepts/#unary-rpc). This service consumes a single protobuf and returns a single protobuf and can be deployed through a variety of mechanisms.

There are some provided example gRPC services, including a [Load Test](examples/risk/loadtest/README.md) example that provides a test harness that can exercise GCP infrastructure (some compute, some IO) and an [American Options](examples/risk/american-option/README.md) example is a Python example using quantlib to calculate American Options.

It is recommended to start with [Load Test](examples/risk/loadtest/README.md) which provides an end to end deployment demonstration and testing framework.

### Research: Monte Carlo Simulations

Run [Monte Carlo simulations](examples/research/monte-carlo/README.md) for VaR on multiple tickers on GKE, review outputs in BigQuery and Perform data visualization in Vertex AI Notebooks

## Prerequisites

- A Google Cloud Project:
    - Project ID of a new or existing Google Cloud Project, preferably with no APIs enabled
    - You must have roles/owner or equivalent IAM permissions on the project
- Development environment with:
    - [Google Cloud SDK](https://cloud.google.com/sdk) (gcloud CLI)
    - [Terraform](https://www.terraform.io/) (version 1.0+)
    - [kubectl](https://kubernetes.io/docs/tasks/tools/)
    - [git](https://git-scm.com/)
- You can also use [Cloud Shell](https://shell.cloud.google.com) which comes preinstalled with all required tools.
- Familiarity with:
    - [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)
    - [Terraform](https://www.terraform.io/)
    - [Kubernetes](https://kubernetes.io/)

### Quota Requirements
- The default quotas assigned to a project should be sufficient for initial testing and exploration.
- For production workloads or larger-scale testing, you may need additional quota for:
    - Spot vCPUs (for cost-effective batch processing)
    - Persistent Disk capacity (for storage-intensive workloads)
    - Monitoring API requests (for observability at scale)
- The repository includes a [quota module](/terraform/modules/quota/) to help request these resources via Terraform.

## Project Structure

```
├── docs
├── examples
│   ├── risk
│   │   └── agent
│   │   └── american-option
│   │   └── loadtest
│   └── research
│   │   └── monte-carlo
└── kubernetes
    ├── kueue
    ├── compute-classes
    ├── priority-classes
    └── storage
        ├── parallelstore
        ├── parallelstore-transfer-tool
        ├── gcsfuse-nodemount
        └── fio-testing
└── terraform
    ├── example
    └── modules
        ├── artifact-registry
        ├── builder
        ├── gke-autopilot
        ├── gke-standard
        ├── lustre
        ├── network
        ├── parallelstore
        ├── project
        ├── pubsub-subscriptions
        └── quota
```

* **examples:** Example applications and configurations.
    * **risk:**  Example using HTC.
        * **agent:** Client-side code for the HTC example.
        * **american-option:** Client-side code for the HTC example.
        * **loadtest:** Client-side code for the HTC example.
    * **research:**
        * **monte-carlo** Sample Monte Carlo calculations with Kubernetes Jobs and Kueue
    * **infrastructure:**
        * **infrastructure** Sample implementation of terraform modules
        * **multi-quota** Sample of how to request quota with terraform
* **kubernetes:** Kubernetes-specific configurations.
    * **compute-classes:** Examples of custom compute classes.
    * **priority-classes:** Priority class configurations.
    * **kueue:** Kueue + GMP configurations
    * **storage:** Storage configurations.
        * **parallelstore:** Parallelstore node-mount setup.
        * **parallelstore-transfer-tool:** Utility for transferring data to/from Parallelstore.
        * **gcsfuse-nodemount:** Google Cloud Storage FUSE node-mount setup.
        * **fio-testing:** FIO benchmarking tools for storage testing.
* **terraform:** Terraform modules for infrastructure provisioning.
    * **modules:** Reusable Terraform modules.
        * **artifact-registry:** Module for setting up Artifact Registry.
        * **builder:** Module for CI/CD build configuration.
        * **gke-autopilot:** Module for deploying a GKE Autopilot cluster.
        * **gke-standard:** Module for deploying a GKE Standard cluster.
        * **kubectl:** Module for kubectl provider configuration.
        * **lustre:** Module for provisioning Lustre.
        * **network:**  Module for configuring network settings.
        * **parallelstore:** Module for provisioning Parallelstore.
        * **project:** Module for setting up a Google Cloud project.
        * **pubsub-subscriptions:** Module for PubSub subscription configuration.
        * **quota:** Module for requesting quota to support running the examples at larger scales.
        * **region-analysis:** Module for analyzing available resources across regions.

## Getting Started

Follow these steps to get started with the Risk and Research Blueprints:

1. **Set up your Infrastructure:**
   - For a complete infrastructure setup, follow the steps in [examples/infrastructure/infrastructure](examples/infrastructure/infrastructure/README.md)
   - This will deploy a GKE cluster, Artifact Registry, and other foundational components

2. **Explore Risk Examples:**
   - Run calculations for American Option pricing: [examples/risk/american-option](examples/risk/american-option/README.md)
   - Test your infrastructure with a scalable load test: [examples/risk/loadtest](examples/risk/loadtest/README.md)
   - Understand agent-based architecture: [examples/risk/agent](examples/risk/agent/README.md)

3. **Try Research Examples:**
   - Run Monte Carlo simulations for Value at Risk (VaR): [examples/research/monte-carlo](examples/research/monte-carlo/README.md)
   - Visualize results in BigQuery and Vertex AI Notebooks

4. **Explore Storage Solutions:**
   - Test high-performance storage with FIO benchmarks: [kubernetes/storage/fio-testing](kubernetes/storage/fio-testing/README.md)
   - Set up Parallelstore: [kubernetes/storage/parallelstore](kubernetes/storage/parallelstore/README.md)

5. **Configure Workload Management:**
   - Learn about Kueue for job scheduling: [kubernetes/kueue](kubernetes/kueue/README.md)

## Contributing
If you would like to contribute to this project, please consult our [how to contribute](./docs/contributing.md) guide.

## Disclaimers

_This is not an officially supported Google Service. The use of this solution is on an “as-is” basis, and is not a
Service offered under the Google Cloud Terms of Service._

This solution is under active development. Interfaces and functionality may change at any time.

## License

This repository is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0.txt) (
see [LICENSE](LICENSE.txt)). The solution includes declarative markdown files that are interpretable by certain
third-party technologies (e.g., Terraform and DBT). These files are for informational use only and do not constitute an
endorsement of those technologies, including any warranties, representations, or other guarantees as to their security,
reliability, or suitability for purpose.
