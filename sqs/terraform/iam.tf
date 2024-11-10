data "aws_iam_policy_document" "secrets_officer_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.async-rotator-cluster.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(module.async-rotator-cluster.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:secretsofficer"]
    }
  }
}

resource "aws_iam_role" "secrets_officer" {
  name               = "${module.async-rotator-cluster.cluster_name}-secrets-officer"
  assume_role_policy = data.aws_iam_policy_document.secrets_officer_assume_role_policy.json
}

resource "aws_iam_role_policy" "secrets_officer_policy" {
  role   = aws_iam_role.secrets_officer.id
  policy = data.aws_iam_policy_document.secrets_officer_policy_document.json
}

data "aws_iam_policy_document" "secrets_officer_policy_document" {
  statement {
    actions   = ["kms:Decrypt", "secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "kubernetes_service_account" "secrets_officer" {
  metadata {
    name      = "secretsofficer"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.secrets_officer.arn
    }
  }
}