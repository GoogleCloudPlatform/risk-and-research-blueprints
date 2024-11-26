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
  workload_args          = ["serve", "--logJSON"]
  workload_grpc_endpoint = "http://localhost:2002/main.LoadTestService/RunLibrary"
  workload_init_args = [
    ["writedata", "--logJSON", "--showProgress=false", "--size", "104857600", "--parallel", "2", "--count", "10", "/data/read_dir/large"],
    ["writedata", "--logJSON", "--showProgress=false", "--size", "10485760", "--parallel", "20", "--count", "100", "/data/read_dir/medium"],
    ["writedata", "--logJSON", "--showProgress=false", "--size", "1048576", "--parallel", "20", "--count", "1000", "/data/read_dir/small"],
    ["gentasks", "--logJSON", "--count=10000", "--initMinMicros=1000000", "--minMicros=1000000", "--initReadDir=/data/read_dir/small", "/data/tasks/10k_1s_1s_read_small.jsonl.gz"],
    ["gentasks", "--logJSON", "--count=1000", "--initMinMicros=1000000", "--minMicros=1000000", "--initReadDir=/data/read_dir/small", "/data/tasks/1k_1s_1s_read_small.jsonl.gz"],
  ]
  test_configs = [
    { name = "hpa_1k_1s_s_read_small", testfile = "/data/tasks/1k_1s_1s_read_small.jsonl.gz", parallel = 0, description = "Autoscaling workers, 1 second compute and small folder read on initialization, 1,000 tasks for 1 second task compute." },
    { name = "10_1k_1s_s_read_small", testfile = "/data/tasks/1k_1s_1s_read_small.jsonl.gz", parallel = 10, description = "10 workers, 1 second compute and small folder read on initialization, 1,000 tasks for 1 second compute." },
    { name = "50_1k_1s_s_read_small", testfile = "/data/tasks/1k_1s_1s_read_small.jsonl.gz", parallel = 50, description = "50 workers, 1 second compute and small folder read on initialization, 1,000 tasks for 1 second compute." },
    { name = "100_1k_1s_s_read_small", testfile = "/data/tasks/1k_1s_1s_read_small.jsonl.gz", parallel = 100, description = "100 workers, 1 second compute and small folder read on initialization, 1,000 tasks for 1 second compute." },
    { name = "500_1k_1s_s_read_small", testfile = "/data/tasks/1k_1s_1s_read_small.jsonl.gz", parallel = 500, description = "500 workers, 1 second compute and small folder read on initialization, 1,000 tasks for 1 second compute." },
    { name = "hpa_10k_1s_s_read_small", testfile = "/data/tasks/10k_1s_1s_read_small.jsonl.gz", parallel = 0, description = "Autoscaling workers, 1 second compute and small folder read on initialization, 10,000 tasks for 1 second compute." },
    { name = "10_10k_1s_s_read_small", testfile = "/data/tasks/10k_1s_1s_read_small.jsonl.gz", parallel = 10, description = "10 workers, 1 second compute and small folder read on initialization, 10,000 tasks for 1 second compute." },
    { name = "100_10k_1s_s_read_small", testfile = "/data/tasks/10k_1s_1s_read_small.jsonl.gz", parallel = 100, description = "100 workers, 1 second compute and small folder read on initialization, 10,000 tasks for 1 second compute." },
    { name = "500_10k_1s_s_read_small", testfile = "/data/tasks/10k_1s_1s_read_small.jsonl.gz", parallel = 500, description = "500 workers, 1 second compute and small folder read on initialization, 10,000 tasks for 1 second compute." },
  ]
  test_configs_dict = {
    for config in local.test_configs :
    config.name => config
  }
  local_test_scripts = merge(
    length(module.cloudrun) == 0 ? {} : {
      for key, script in module.cloudrun[0].test_scripts :
      "run_${key}.sh" => script
    },
    length(module.gke) == 0 ? {} : {
      for key, script in module.gke[0].test_scripts :
      "gke_${key}.sh" => script
  })
  ui_config_file = yamlencode({
    "project_id" : var.project_id,
    "region" : var.region,
    "pubsub_summary_table" : "${google_bigquery_table.messages_summary.project}.${google_bigquery_table.messages_summary.dataset_id}.${google_bigquery_table.messages_summary.table_id}",
    "urls" : {
      "dashboard" = module.gke[0].monitoring_dashboard_url
      "cluster"   = module.gke[0].cluster_url
    },
    "tasks" : concat(
      length(module.gke) == 0 ? [] : [
        for config in local.test_configs : {
          "name"        = "GKE ${config.name}",
          "script"      = module.gke[0].test_scripts[config.name],
          "parallel"    = config.parallel,
          "description" = config.description,
        }
      ],
      length(module.cloudrun) == 0 ? [] : [
        for config in local.test_configs : {
          "name"        = "Cloud Run ${config.name}",
          "script"      = module.cloudrun[0].test_scripts[config.name],
          "parallel"    = config.parallel,
          "description" = config.description,
        }
      ],
    ),
  })
}

#
# API Enablement
#

# Module to manage project-level settings and API enablement
module "project" {
  source               = "../../../terraform/modules/project"
  project_id           = var.project_id
  region               = var.region
  enable_log_analytics = false
}

#
# Artifact Repository
#

module "artifact_registry" {
  source     = "../../../terraform/modules/artifact-registry"
  region     = var.region
  project_id = var.project_id
  name       = "example-images"
}

#
# Build the containers (Docker file Cloudbuild)
#

module "agent" {
  source = "../../../terraform/modules/builder"

  project_id    = var.project_id
  region        = var.region
  repository_id = module.artifact_registry.artifact_registry.repository_id
  containers = {
    agent = {
      source = "${path.module}/../agent/src"
    },
    loadtest = {
      source = "${path.module}/src"
    },
    american_option = {
      source = "${path.module}/../american-option"
    }
  }
}


#
# Cloud Run
#

module "cloudrun" {
  source = "../agent/modules/run"
  # TODO: Mark this part of a count and optional.
  count = 1
  # var.bq_dataset is defined?

  project_id  = var.project_id
  region      = var.region
  agent_image = module.agent.status["agent"].image

  # Cloud Run specific options
  bq_dataset = google_bigquery_dataset.main.dataset_id

  # Workload options
  workload_image         = module.agent.status["loadtest"].image
  workload_args          = local.workload_args
  workload_grpc_endpoint = local.workload_grpc_endpoint
  workload_init_args     = local.workload_init_args
  test_configs           = local.test_configs_dict
}


#
# GKE
#

module "gke" {
  source     = "../agent/modules/gke"
  depends_on = [module.project]
  zones      = var.zones

  # TODO: Mark this part of a count and optional.
  count = 1
  # var.zones, gke_standard_enabled, gke_autopilot_enabled result in count

  project_id  = var.project_id
  region      = var.region
  agent_image = module.agent.status["agent"].image

  # GKE specific options
  gke_standard_enabled  = var.gke_standard_enabled
  gke_autopilot_enabled = var.gke_autopilot_enabled
  artifact_registry     = module.artifact_registry.artifact_registry

  # Workload options
  # TODO: Other configuration for the workload - needs to be standardized
  workload_image         = module.agent.status["loadtest"].image
  workload_args          = local.workload_args
  workload_grpc_endpoint = local.workload_grpc_endpoint
  workload_init_args     = local.workload_init_args
  test_configs           = local.test_configs_dict
}

#
# Log analytics (specific workload and agent, GKE and Run)
#

# Always have the same filter. Leave this at the top level. This will
# capture application *and* agent stuff.
# To be put into an *agent* module...
resource "google_logging_project_bucket_config" "analytics-enabled-bucket" {
  project          = var.project_id
  location         = var.region
  enable_analytics = true
  bucket_id        = "applogs"
}

resource "google_logging_linked_dataset" "logging_linked_dataset" {
  link_id     = "applogs"
  bucket      = google_logging_project_bucket_config.analytics-enabled-bucket.id
  description = "Linked dataset test"
  depends_on = [
    module.project
  ]
}

resource "google_logging_project_sink" "my-sink" {
  project = var.project_id
  name    = "my-pubsub-instance-sink"

  # Can export to pubsub, cloud storage, bigquery, log bucket, or another project
  destination = "logging.googleapis.com/${google_logging_project_bucket_config.analytics-enabled-bucket.id}"

  # This depends on the use of GKE and Cloud Run for the filter
  filter = "logName=\"projects/${var.project_id}/logs/stdout\" OR logName=\"projects/${var.project_id}/logs/stderr\" OR logName=\"projects/${var.project_id}/logs/run.googleapis.com%2Fstdout\" OR logName=\"projects/${var.project_id}/logs/run.googleapis.com%2Fstdout\""

  description = "Local application logs"
}

resource "google_bigquery_dataset" "main" {
  project    = var.project_id
  dataset_id = "workload"
  location   = var.region
  depends_on = [
    module.project
  ]
}

#
# Logging BigQuery views
#

# Create an abstraction across Cloud Run Jobs, Cloud Run Services, and K8S pods
resource "google_bigquery_table" "log_stats" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.main.dataset_id
  table_id   = "log_stats"

  view {
    query = templatefile(
      "${path.module}/sql/log_stats.sql", {
        project_id = var.project_id
        dataset_id = regex("^bigquery.googleapis.com/projects/[^/]+/datasets/(.*)$", google_logging_linked_dataset.logging_linked_dataset.bigquery_dataset[0].dataset_id)[0]
    })
    use_legacy_sql = false
  }
}

# Collect agent statistics
resource "google_bigquery_table" "agent_stats" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.main.dataset_id
  table_id   = "agent_stats"

  view {
    query = templatefile(
      "${path.module}/sql/agent_stats.sql", {
        project_id = var.project_id
        dataset_id = google_bigquery_dataset.main.dataset_id
        table_id   = google_bigquery_table.log_stats.table_id
    })
    use_legacy_sql = false
  }
}

# Summarise agent statistics by instance
resource "google_bigquery_table" "agent_summary_by_instance" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.main.dataset_id
  table_id   = "agent_summary_by_instance"

  view {
    query = templatefile(
      "${path.module}/sql/agent_summary_by_instance.sql", {
        project_id = var.project_id
        dataset_id = google_bigquery_dataset.main.dataset_id
        table_id   = google_bigquery_table.agent_stats.table_id
    })
    use_legacy_sql = false
  }
}


#
# Capture Pub/Sub topics into BigQuery
#
# All message are assumed to be JSON and captured in a JSON data element
module "bigquery_capture" {
  source           = "../../../terraform/modules/pubsub-subscriptions"
  project_id       = var.project_id
  region           = var.region
  bigquery_dataset = google_bigquery_dataset.main.dataset_id
  bigquery_table   = "pubsub_messages"
  topics = concat(
    length(module.cloudrun) > 0 ? module.cloudrun[0].topics : [],
  length(module.gke) > 0 ? module.gke[0].topics : [])
}


#
# Quota Requests
#

module "quota" {
  count               = var.additional_quota_enabled ? 1 : 0
  source              = "../../../terraform/modules/quota"
  region              = var.region
  quota_contact_email = var.quota_contact_email
  project_id          = var.project_id
}

#
# Create views for Data Studio
#

# Pub/Sub messages joined by request/response
resource "google_bigquery_table" "messages_joined" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.main.dataset_id
  table_id   = "pubsub_messages_joined"

  view {
    query = templatefile(
      "${path.module}/sql/pubsub_messages_joined.sql", {
        project_id = var.project_id
        dataset_id = google_bigquery_dataset.main.dataset_id
        table_id   = "pubsub_messages"
    })
    use_legacy_sql = false
  }

  depends_on = [
    module.bigquery_capture
  ]
}

# Pub/Sub summary by job
resource "google_bigquery_table" "messages_summary" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.main.dataset_id
  table_id   = "pubsub_messages_summary"

  view {
    query = templatefile(
      "${path.module}/sql/pubsub_messages_summary.sql", {
        project_id      = google_bigquery_table.messages_joined.project
        dataset_id      = google_bigquery_table.messages_joined.dataset_id
        joined_table_id = google_bigquery_table.messages_joined.table_id
    })
    use_legacy_sql = false
  }

  depends_on = [
    google_bigquery_table.messages_joined
  ]
}


#
# UI Configuration and scripts
#

# Create test scripts
resource "local_file" "test_scripts" {
  for_each = (var.scripts_output == "") ? {} : local.local_test_scripts
  filename = "${var.scripts_output}/${each.key}"
  content  = each.value
}

# Create UI config file
resource "local_file" "ui_config" {
  filename = "${var.scripts_output}/config.yaml"
  content  = local.ui_config_file
}

# Build the container (Docker file Cloudbuild)
module "ui_image" {
  count = var.ui_image_enabled ? 1 : 0

  source = "../../../terraform/modules/builder"

  project_id    = var.project_id
  region        = var.region
  repository_id = module.artifact_registry.artifact_registry.repository_id
  containers = {
    ui = {
      source      = "${path.module}/ui"
      config_yaml = local.ui_config_file
    }
  }
  service_account_name = "ui-cloudbuild"
}
