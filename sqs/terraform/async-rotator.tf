resource "kubernetes_manifest" "asyncrotator" {
  depends_on = [kubernetes_manifest.secretstore_aws_secret_store]
  manifest = {
    apiVersion = "eso.externalsecrets.com/v1"
    kind = "AsyncRotator"
    metadata = {
      name = "async-rotator"
      namespace = "default"
    }
    spec = {
      notificationSources = [
        {
          awsSqs = {
            auth = {
              authMethod = "irsa"
              serviceAccountRef = {
                name = "secretsofficer"
                namespace = "default"
              }
            }
            queueURL = aws_sqs_queue.secrets_manager_events_queue.url
            region = "eu-west-1"
          }
          type = "AwsSqs"
        }
      ]
      secretsToWatch = [
        {
          names = [aws_secretsmanager_secret.irsa_auth_secret.name]
        }
      ]
    }
  }
}
