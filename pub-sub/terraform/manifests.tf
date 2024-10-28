resource "kubectl_manifest" "async_rotator" {
  yaml_body = templatefile("${path.module}/manifests/async-rotator.yaml", {
    project_id = var.project_id
    subscription_id   = var.subscription_name
    secret_name = "async-rotator-sa-key"
    secret_namespace = "default"
    secret_key = "service-account-key.json"
  })
  depends_on = [ kubectl_manifest.service_account_key_secret ]
}

resource "kubectl_manifest" "secretstore" {
  yaml_body = templatefile("${path.module}/manifests/secretstore.yaml", {
    project_id = var.project_id
    subscription_id   = var.subscription_name
    secret_name = "async-rotator-sa-key"
    secret_namespace = "default"
    secret_key = "service-account-key.json"
  })
}

resource "kubectl_manifest" "externalsecret" {
  yaml_body = templatefile("${path.module}/manifests/externalsecret.yaml", {
    project_id = var.project_id
    subscription_id   = var.subscription_name
    secret_name = "async-rotator-sa-key"
    secret_namespace = "default"
    secret_key = "service-account-key.json"
  })
}

