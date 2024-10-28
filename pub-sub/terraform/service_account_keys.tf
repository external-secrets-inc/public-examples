variable "service_account_name" {
  type    = string
  default = "async-rotator-sa"
}

# main.tf
# Create the Service Account
resource "google_service_account" "async_rotator_sa" {
  account_id   = var.service_account_name
  display_name = "Service Account for Async Rotator"
}

# Grant Pub/Sub Subscriber role to the Service Account
resource "google_project_iam_member" "pubsub_subscriber_sa_key" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.async_rotator_sa.email}"
}

# Generate and store the Service Account key
resource "google_service_account_key" "sa_key" {
  service_account_id = google_service_account.async_rotator_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

output "service_account_key" {
  value = google_service_account_key.sa_key.private_key
  sensitive = true
}

resource "kubectl_manifest" "service_account_key_secret" {
  yaml_body = <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: async-rotator-sa-key
  namespace: default
type: Opaque
data:
  service-account-key.json: ${google_service_account_key.sa_key.private_key}
EOF
}
