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
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Global Resources

# Pubsub
resource "google_pubsub_topic" "topic" {
  for_each = toset(local.pubsub_topics)
  project  = var.project_id
  name     = each.value
  message_storage_policy {
    allowed_persistence_regions = var.regions
  }
}

resource "google_pubsub_subscription" "subscription" {
  for_each                     = toset(local.pubsub_topics)
  project                      = google_pubsub_topic.topic[each.value].project
  topic                        = google_pubsub_topic.topic[each.value].name
  name                         = "${each.value}_sub"
  enable_exactly_once_delivery = var.pubsub_exactly_once
  ack_deadline_seconds         = 60
  retry_policy {
    minimum_backoff = "30s"
    maximum_backoff = "600s"
  }
}

# Dashboard

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
    allowed_persistence_regions = var.regions
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

resource "google_storage_bucket" "us_dual_region_bucket" {
  name = "${var.project_id}-dualregion-gke-data-${random_string.suffix.id}"
  project = data.google_project.environment.project_id
  location      = "US"
  uniform_bucket_level_access = true
  rpo = "ASYNC_TURBO"
  custom_placement_config {
    data_locations = ["US-CENTRAL1","US-EAST4"]
  }
  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}


# IAM for Workloads in GKE

resource "google_project_iam_member" "storage_objectuser" {
  project = data.google_project.environment.project_id
  role    = "roles/storage.objectUser"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${var.cluster_name}"
}

resource "google_project_iam_member" "pubsub_publisher" {
  project = data.google_project.environment.project_id
  role    = "roles/pubsub.publisher"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${var.cluster_name}"
}

resource "google_project_iam_member" "pubsub_subscriber" {
  project = data.google_project.environment.project_id
  role    = "roles/pubsub.subscriber"
  member  = "principalSet://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${data.google_project.environment.project_id}.svc.id.goog/kubernetes.cluster/https://container.googleapis.com/v1/projects/${data.google_project.environment.project_id}/locations/${var.region}/clusters/${var.cluster_name}"
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
}

resource "google_project_iam_member" "metrics_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "principal://iam.googleapis.com/projects/${data.google_project.environment.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/default"
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
        gcs_storage_data = google_storage_bucket.us_dual_region_bucket.id
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

resource "null_resource" "apply_custom_priority_class" {
  triggers = {
    cluster_change = local.cluster_config
    kustomize_change = sha512(join("", [
      for f in fileset(".", "${path.module}/../../../../../kubernetes/priority-classes/**") :
      filesha512(f)
    ]))
  }

  provisioner "local-exec" {
    when    = create
    command = <<-EOT

    ${local.kubeconfig_script}

    kubectl apply -k "${path.module}/../../../../../kubernetes/priority-classes/"

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
    google_project_iam_member.storage_objectuser,
    google_project_iam_member.pubsub_publisher,
    google_project_iam_member.pubsub_subscriber,
    google_project_iam_member.metrics_writer,
    google_project_iam_member.gke_hpa
  ]
}
