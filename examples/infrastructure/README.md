## Deploying example GKE, Artifact Registry & Parallelstore

This Terraform example demonstrates how to deploy a Parallelstore instance along with a Google Kubernetes Engine (GKE) cluster. It includes options for deploying on GKE Standard or GKE Autopilot.

**Prerequisites:**

* **Google Cloud Project:** A Google Cloud project with billing enabled.
* **Terraform:** Terraform CLI installed and configured.

**Deployment Steps:**

1. **Clone the Repository:** Clone the repository containing this Terraform example.
2. **Configure Variables:**

3. **Initialize Terraform:** Run `terraform init` to initialize the working directory.
4. **Plan and Apply:**
   *  Execute `terraform plan` to preview the changes.
   *  Run `terraform apply` to deploy the infrastructure.

**Note:** This is a basic example and may need to be adapted to your specific requirements. Refer to the module documentation for more advanced configuration options.


1. **Clone the Repository:**
   ```bash
   git clone https://gitlab.com/google-cloud-ce/googlers/duncanjames/research-platform-for-fsi.git
   cd research-platform-for-fsi/examples/infrastructure
   ```

2. **Configure Variables:**
   *  Update `variables.tfvars` with your desired values:
      *   `project_id`: Your Google Cloud project ID.
      *   `region`: The desired region for deployment (e.g., `us-central1`).
      *   `parallelstore_enabled`: Set to `true` to deploy Parallelstore.
      *   `gke_standard_enabled`: Set to `true` to deploy a GKE Standard cluster.
      *   `gke_autopilot_enabled`: Set to `true` to deploy a GKE Autopilot cluster.
      *   (Optional): `quota_contact_email`: Your contact email for quota requests.

3. **Deploy with Terraform:**

    - Authorize `gcloud`

    ```bash
    gcloud auth login --activate --no-launch-browser --quiet --update-adc
    ```
    - Run Terraform

   ```bash
   terraform init
   terraform plan -var-file="terraform.tfvars" -out=tfplan
   terraform apply tfplan
   ```
4. **Tidy Up**
   ```
   terraform destroy
   ```
