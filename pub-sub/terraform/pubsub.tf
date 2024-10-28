resource "google_pubsub_topic" "topic" {
  project = var.project_id
  name = var.topic_name
}

resource "google_pubsub_subscription" "subscription" {
  project = var.project_id
  name  = var.subscription_name
  topic = google_pubsub_topic.topic.name
}