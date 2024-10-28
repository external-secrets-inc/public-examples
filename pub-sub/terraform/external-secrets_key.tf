variable "external_secrets_service_account_name" {
  type    = string
  default = "external-secrets"
}

# main.tf
# Create the Service Account
resource "google_service_account" "external_secrets_sa" {
  account_id   = var.external_secrets_service_account_name
  display_name = "Service Account for Async Rotator"
}


# Grant Secret Manager Secret Accessor role to the Service Account
resource "google_project_iam_member" "secret_accessor_sa_key" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets_sa.email}"
}

# Generate and store the Service Account key
resource "google_service_account_key" "es_sa_key" {
  service_account_id = google_service_account.external_secrets_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "kubectl_manifest" "es_service_account_key_secret" {
  yaml_body = <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gcp-creds
  namespace: default
type: Opaque
data:
  creds_json: ${google_service_account_key.es_sa_key.private_key}
EOF
}
