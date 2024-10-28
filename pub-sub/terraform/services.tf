  resource "google_project_service" "pubsub" {
    project = var.project_id
    service = "pubsub.googleapis.com"
  }

  resource "google_project_service" "secretmanager" {
    project = var.project_id
    service = "secretmanager.googleapis.com"
  }

  resource "google_project_service" "logging" {
    project = var.project_id
    service = "logging.googleapis.com"
  }
