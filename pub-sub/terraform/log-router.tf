

resource "google_logging_project_sink" "log_sink" {
  name        = var.sink_name
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.topic.name}"
  filter      = <<EOF
protoPayload.methodName=~"google.cloud.secretmanager.v1.SecretManagerService.AddSecretVersion"
EOF
}

# Grant Pub/Sub Publisher role to the sink's service account
resource "google_pubsub_topic_iam_member" "sink_publisher" {
  topic = google_pubsub_topic.topic.name
  role  = "roles/pubsub.publisher"
  member = google_logging_project_sink.log_sink.writer_identity
}