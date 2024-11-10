resource "kubernetes_manifest" "secretstore_aws_secret_store" {
  depends_on = [module.async_rotator_cluster]
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind = "SecretStore"
    metadata = {
      name = "aws-secret-store"
      namespace = "default"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region = "eu-west-1"
          auth = {
            jwt = {
              serviceAccountRef: {
                name: "secretsofficer"
                namespace: "default"
              }
            }
          }
        }
      }
    }
  }

  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
}

