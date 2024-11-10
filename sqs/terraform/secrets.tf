resource "random_password" "password" {
  length  = 16
  special = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "irsa_auth_secret" {
  name        = "irsa-auth"
  description = "This secret is used for IRSA authentication example"
}

resource "aws_secretsmanager_secret_version" "irsa_auth_secret" {
  secret_id     = aws_secretsmanager_secret.irsa_auth_secret.id
  secret_string = jsonencode({
    username = "admin",
    password = random_password.password.result
  })
}

resource "kubernetes_manifest" "es_irsa_auth_secret" {
  depends_on = [
    module.async_rotator_cluster,
    kubernetes_manifest.secretstore_aws_secret_store
  ]
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind = "ExternalSecret"
    metadata = {
      name = aws_secretsmanager_secret.irsa_auth_secret.name
      namespace = "default"
    }
    spec = {
      data = [
        {
          remoteRef = {
            key = aws_secretsmanager_secret.irsa_auth_secret.arn
          }
          secretKey = aws_secretsmanager_secret.irsa_auth_secret.name
        },
      ]
      secretStoreRef = {
        kind = "SecretStore"
        name = "aws-secret-store"
      }
      target = {
        name = aws_secretsmanager_secret.irsa_auth_secret.name
      }
    }
  }
}

