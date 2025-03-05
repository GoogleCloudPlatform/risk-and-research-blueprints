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

locals {
  workload_init_args = {
    for idx, args in var.workload_init_args :
    "job-${idx}-${substr(sha256(jsonencode(args)), 0, 10)}" => {
      args  = args,
      image = var.workload_image,
    }
  }

  # Whether to enable different patterns
  enable_jobs = (var.gke_job_request != "" && var.gke_job_response != "") ? 1 : 0
  enable_hpa  = (var.gke_hpa_request != "" && var.gke_job_response != "") ? 1 : 0

  # Topics
  pubsub_topics = concat(
    local.enable_jobs == 1 ? [
      var.gke_job_request,
      var.gke_job_response,
    ] : [],
    local.enable_hpa == 1 ? [
      var.gke_hpa_request,
      var.gke_hpa_response,
    ] : [],
  )

  cluster_config = "${var.cluster_name}-${var.region}-${var.project_id}"
  kubeconfig_script = join("\n", [
    "export KUBECONFIG=\"${path.root}/generated/kubeconfig.yaml\"",
    "if [ ! -r \"$${KUBECONFIG}\" ]; then",
    "KUBECONFIG=\"$${KUBECONFIG}.$$$\" gcloud container clusters get-credentials ${var.cluster_name} --project=${var.project_id} --region=${var.region}",
    "mv -f \"$${KUBECONFIG}.$$$\" \"$${KUBECONFIG}\"",
    "fi",
  ])

  # Test output
  test_job_template = {
    for id, cfg in var.test_configs :
    id => templatefile(
      "${path.module}/k8s/agent_job.templ", {
        name              = "${replace(id, "/[_\\.]/", "-")}-worker",
        parallel          = cfg.parallel,
        workload_args     = var.workload_args,
        workload_image    = var.workload_image,
        agent_image       = var.agent_image,
        workload_endpoint = var.workload_grpc_endpoint,
        workload_request_sub = (cfg.parallel > 0 ?
          google_pubsub_subscription.subscription[var.gke_job_request].name :
        google_pubsub_subscription.subscription[var.gke_hpa_request].name)
        workload_response = (cfg.parallel > 0 ?
        var.gke_job_response : var.gke_hpa_response)
    })
  }
  test_controller_template = {
    for id, cfg in var.test_configs :
    id => templatefile(
      "${path.module}/k8s/job.templ", {
        parallel       = 1,
        job_name       = "${replace(id, "/[_\\.]/", "-")}-controller",
        container_name = "controller",
        image          = var.agent_image,
        args = [
          "test", "pubsub",
          "--logJSON",
          "--logAll",
          "--jsonPubSub=true",
          (cfg.parallel > 0 ?
          var.gke_job_request : var.gke_hpa_request),
          (cfg.parallel > 0 ?
            google_pubsub_subscription.subscription[var.gke_job_response].name :
          google_pubsub_subscription.subscription[var.gke_hpa_response].name),
          "--source",
        cfg.testfile]
    })
  }
  test_shell = {
    for id, cfg in var.test_configs :
    id => templatefile(
      "${path.module}/k8s/test_config.sh.templ", {
        parallel          = cfg.parallel,
        job_config        = local.test_job_template[id],
        controller_config = local.test_controller_template[id],
        project_id        = var.project_id,
        region            = var.region,
        cluster_name      = var.cluster_name,
    })
  }
}


#
# Google Kubernetes Engine
#

# Retrieve Google Cloud project information
data "google_project" "environment" {
  project_id = var.project_id
}

# Module to manage project-level settings and API enablement
# module "project" {
#     source = "../../../../../terraform/modules/project"
#     project_id = data.google_project.environment.project_id
#     region = var.region
# }

# Module to create VPC network and subnets
module "networking" {
  source                = "../../../../../terraform/modules/network"
  project_id            = data.google_project.environment.project_id
  region                = var.region
  gke_standard_enabled  = var.gke_standard_enabled
  gke_autopilot_enabled = var.gke_autopilot_enabled
}

# Conditionally create a GKE Standard cluster
module "gke_standard" {
  count                = var.gke_standard_enabled ? 1 : 0
  source               = "../../../../../terraform/modules/gke-standard"
  project_id           = data.google_project.environment.project_id
  region               = var.region
  zones                = var.zones
  network              = module.networking.network
  subnet               = module.networking.subnet-1.id
  ip_range_services    = module.networking.subnet-1.secondary_ip_range[0].range_name
  ip_range_pods        = module.networking.subnet-1.secondary_ip_range[1].range_name
  depends_on           = [module.networking]
  scaled_control_plane = var.scaled_control_plane
  artifact_registry    = var.artifact_registry
}

resource "google_monitoring_dashboard" "risk-platform-overview" {
  project        = data.google_project.environment.project_id
  dashboard_json = file("${path.module}/${var.dashboard}")

  lifecycle {
    ignore_changes = [
      dashboard_json
    ]
  }
}

#
# Create Pub/Sub topics and subscriptions
#

resource "google_pubsub_topic" "topic" {
  for_each = toset(local.pubsub_topics)
  project  = var.project_id
  name     = each.value
  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }
}

resource "google_pubsub_subscription" "subscription" {
  for_each                     = toset(local.pubsub_topics)
  project                      = google_pubsub_topic.topic[each.value].project
  topic                        = google_pubsub_topic.topic[each.value].name
  name                         = "${each.value}_sub"
  enable_exactly_once_delivery = true
  ack_deadline_seconds         = 60
  expiration_policy {
    ttl = ""
  }
  retry_policy {
    minimum_backoff = "30s"
    maximum_backoff = "600s"
  }
}


#
# Create GCS bucket
#

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}


# Configure GCS bucket for test
resource "google_storage_bucket" "gcs_storage_data" {
  project                     = var.project_id
  location                    = var.region
  name                        = "${var.project_id}-${var.region}-gke-data-${random_string.suffix.id}"
  uniform_bucket_level_access = true
}


# IAM for Workloads in GKE

resource "google_project_iam_member" "storage_objectuser" {
  project = data.google_project.environment.project_id
  role    = "roles/storage.objectUser"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${module.gke_standard[0].cluster_name}"
}

resource "google_project_iam_member" "pubsub_publisher" {
  project = data.google_project.environment.project_id
  role    = "roles/pubsub.publisher"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${module.gke_standard[0].cluster_name}"
}

resource "google_project_iam_member" "pubsub_subscriber" {
  project = data.google_project.environment.project_id
  role    = "roles/pubsub.subscriber"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${module.gke_standard[0].cluster_name}"
}

#
# Initialization
#

# Apply needed permission to GCP service account (workload identity)
# for reading Pub/Sub metrics
resource "google_project_iam_member" "gke_hpa" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "principal://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/custom-metrics/sa/custom-metrics-stackdriver-adapter"

  depends_on = [
    module.gke_standard
  ]
}

resource "google_project_iam_member" "metrics_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "principal://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/default"

  depends_on = [
    module.gke_standard
  ]
}

# Apply configurations to the cluster
# (whether through templates or hard-coded)
resource "null_resource" "cluster_init" {
  depends_on = [
    module.gke_standard
  ]

  for_each = merge(
    { for fname in fileset(".", "${path.module}/k8s/*.yaml") : fname => file(fname) },
    { "volume_yaml" = templatefile(
      "${path.module}/k8s/volume.yaml.templ", {
        gcs_storage_data = google_storage_bucket.gcs_storage_data.id
      }),
      "hpa_yaml" = templatefile(
        "${path.module}/k8s/hpa.yaml.templ", {
          name                = "gke-hpa",
          workload_image      = var.workload_image,
          workload_args       = var.workload_args,
          workload_endpoint   = var.workload_grpc_endpoint,
          agent_image         = var.agent_image,
          gke_hpa_request_sub = google_pubsub_subscription.subscription[var.gke_hpa_request].name
          gke_hpa_response    = var.gke_hpa_response
      }),
    }
  )

  triggers = {
    template       = each.value
    cluster_change = local.cluster_config
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT
    ${local.kubeconfig_script}

    kubectl apply -f - <<EOF
    ${each.value}
    EOF
    EOT
  }
}

resource "null_resource" "apply_custom_compute_class" {
  depends_on = [
    module.gke_standard
  ]

  triggers = {
    cluster_change = local.cluster_config
    kustomize_change = sha512(join("", [
      for f in fileset(".", "${path.module}/../../../../../kubernetes/compute-classes/**") :
      filesha512(f)
    ]))
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT

    ${local.kubeconfig_script}

    kubectl apply -k "${path.module}/../../../../../kubernetes/compute-classes/"

    EOT
  }
}

# Run workload initialization jobs
resource "null_resource" "job_init" {
  for_each = {
    for id, cfg in local.workload_init_args :
    id => templatefile("${path.module}/k8s/job.templ", {
      job_name       = replace(id, "/[_\\.]/", "-"),
      container_name = replace(id, "/[_\\.]/", "-"),
      parallel       = 1,
      image          = cfg.image,
      args           = cfg.args
    })
  }

  depends_on = [
    null_resource.cluster_init,
  ]

  triggers = {
    cluster_change = local.cluster_config
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT

    ${local.kubeconfig_script}

    kubectl apply -f - <<EOF
    ${each.value}
    EOF

    while true; do
      echo "Checking status of job ${each.key}"

      if kubectl wait --for=condition=Complete --timeout=0 job/${each.key} 2> /dev/null; then
        echo "Job ${each.key} successful"
        exit 0
      fi

      if kubectl wait --for=condition=Failed --timeout=0 job/${each.key} 2> /dev/null; then
        echo "Job ${each.key} failed, logs follow:"
        kubectl logs -c ${each.key} --tail 10 "jobs/${each.key}"
        exit 1
      fi

      sleep 2
    done

    EOT
  }
}
