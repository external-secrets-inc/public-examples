resource "google_secret_manager_secret" "example_secret" {
    project = var.project_id
  secret_id = "test-key-in-gcp"
  replication {
    auto {
      
    }
  }
 depends_on = [ google_project_service.secretmanager ]
}

resource "google_secret_manager_secret_version" "example_secret_version" {
  secret      = google_secret_manager_secret.example_secret.id
  secret_data = "Hello, world!"
 depends_on = [ google_project_service.secretmanager ]
}
