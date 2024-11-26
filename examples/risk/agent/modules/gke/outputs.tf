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

# Topics (for BigQuery capturing of output)
output "topics" {
  description = "Image and tag names for build containers"
  value       = local.pubsub_topics
  depends_on = [
    google_pubsub_topic.topic,
    google_pubsub_subscription.subscription
  ]
}

# Helper for fetching credentials for Kubernetes
output "get_credentials" {
  description = "Command for gcloud get credentials"
  value       = "gcloud container clusters get-credentials --project ${var.project_id} --location ${var.region} ${var.cluster_name}"
}

# Dashboard for Platform Overview
output "monitoring_dashboard_url" {
  description = "Cloud Monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/builder/${regex("projects/[0-9]+/dashboards/(.*)$", google_monitoring_dashboard.risk-platform-overview.id)[0]};project=${var.project_id}"
}

# Cluster
output "cluster_url" {
  description = "Cluster url"
  value       = "https://console.cloud.google.com/kubernetes/workload/overview?project=${var.project_id}&pageState=(%22savedViews%22:(%22n%22:%5B%22default%22%5D,%22c%22:%5B%22gke%2F${var.region}%2F${module.gke_standard[0].cluster_name}%22%5D))"
}

# Test scripts (shell scripts)
output "test_scripts" {
  description = "Test configuration shell scripts"
  value       = local.test_shell
}
