# Create two secrets for:
# - Static authentication example
# - IRSA authentication example

resource "random_password" "password" {
  length  = 16
  special = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "static_auth_secret" {
  name        = "static-auth"
  description = "This secret is used for static authentication example"
}

resource "aws_secretsmanager_secret" "irsa_auth_secret" {
  name        = "irsa-auth"
  description = "This secret is used for IRSA authentication example"
}

resource "aws_secretsmanager_secret_version" "static_auth_secret" {
  secret_id     = aws_secretsmanager_secret.static_auth_secret.id
  secret_string = jsonencode({
    username = "admin",
    password = random_password.password.result
  })
}

resource "aws_secretsmanager_secret_version" "irsa_auth_secret" {
  secret_id     = aws_secretsmanager_secret.irsa_auth_secret.id
  secret_string = jsonencode({
    username = "admin",
    password = random_password.password.result
  })
}