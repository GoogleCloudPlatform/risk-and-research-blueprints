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

- This guide expect an existing Google Cloud Project to have been created already.
    - Project ID of a new Google Cloud Project, preferably with no APIs enabled
    - roles/owner IAM permissions on the project
- This guide is meant to be run on [Cloud Shell](https://shell.cloud.google.com) which comes preinstalled with the [Google Cloud SDK](https://cloud.google.com/sdk) and other tools that are required to complete this tutorial.
- Familiarity with following
  - [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine)
  - [Terraform](https://www.terraform.io/)
  - [git](https://git-scm.com/)
  - [GitHub](https://github.com/)

### Quota
- The default quota given to a project should be sufficient for this guide.
- If you would like to request more Quota, specifically Spot vCPU's and Persistent Disk, there is a [module](/terraform/modules/quota/) to support this via terraform.

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
    ├── prioirty-classes
    └── storage
        ├── parallelstore-nodemount
        ├── parallelstore-transfer-tool
        └── gcsfuse-nodemount
└── terraform
    ├── example
    └── modules
        ├── artifact-registry
        ├── builder
        ├── gke-autopilot
        ├── gke-standard
        ├── network
        ├── parallelstore
        ├── project
        ├── pubsub-subscriptions
        └── quota
```

* **examples:** Example applications and configurations.
    * **risk:**  Example using HTC.
        * **agent:** Client-side code for the HTC example.
        * **american-options:** Client-side code for the HTC example.
        * **loadtest:** Client-side code for the HTC example.
    * **research:**
        * **monte-carlo** Sample Monte Carlo calculations with Kubernetes Jobs and Kueue
    * **infrastructure:** Sample implementation of terraform modules
* **kubernetes:** Kubernetes-specific configurations.
    * **compute-classes:** Examples of custom compute classes.
    * **kueue:** Kueue + GMP configurations
    * **storage:** Storage configurations.
        * **parallelstore:** Parallelstore node-mount setup.
        * **gcs:** Google Cloud Storage node-mount setup.
* **terraform:** Terraform modules for infrastructure provisioning.
    * **modules:** Reusable Terraform modules.
        * **artifact-registry:** Module for setting up Artifact Registry.
        * **gke-autopilot:** Module for deploying a GKE Autopilot cluster.
        * **gke-standard:** Module for deploying a GKE Standard cluster.
        * **network:**  Module for configuring network settings.
        * **parallelstore:** Module for provisioning Parallelstore.
        * **project:** Module for setting up a Google Cloud project.
        * **quota:** Module for requesting quota to support running the examples at larger scales.

## Getting Started

Explore the examples:

1. Risk
    - Run local jobs to calculate American Option prices - [examples/risk/american-option/readme](examples/risk/american-option/README.md)
    - Run a load test of the infrastrcture platform - [examples/risk/loadtest/readme](examples/risk/loadtest/README.md)

2. Research
    - Follow the steps in the [/examples/research/monte-carlo/readme](/examples/research/monte-carlo/README.md)

3. Deploy an empty infrastructure setup:
    - Follow the steps in in [/examples/infrastructure/readme](/examples/infrastructure/README.md)

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
