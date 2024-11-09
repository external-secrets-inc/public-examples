# Create an SQS queue
resource "aws_sqs_queue" "secrets_manager_events_queue" {
  name = "secrets-manager-events-queue"
}

# Create a KMS key
resource "aws_kms_key" "key" {
  description = "KMS key for Cloud Trail"
  policy      = <<EOT
        {
            "Version": "2012-10-17",
            "Id": "Key policy created by CloudTrail",
            "Statement": [
                {
                    "Sid": "Enable IAM User Permissions",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": [
                            "arn:aws:iam::${var.account_id}:user/gustavo_carvalho",
                            "arn:aws:iam::${var.account_id}:root"
                        ]
                    },
                    "Action": "kms:*",
                    "Resource": "*"
                },
                {
                    "Sid": "Allow CloudTrail to encrypt logs",
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "cloudtrail.amazonaws.com"
                    },
                    "Action": "kms:GenerateDataKey*",
                    "Resource": "*",
                    "Condition": {
                        "StringEquals": {
                            "aws:SourceArn": "arn:aws:cloudtrail:${var.region}:${var.account_id}:trail/${var.trail_name}"
                        },
                        "StringLike": {
                            "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${var.account_id}:trail/*"
                        }
                    }
                },
                {
                    "Sid": "Allow CloudTrail to describe key",
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "cloudtrail.amazonaws.com"
                    },
                    "Action": "kms:DescribeKey",
                    "Resource": "*"
                },
                {
                    "Sid": "Allow principals in the account to decrypt log files",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "*"
                    },
                    "Action": [
                        "kms:Decrypt",
                        "kms:ReEncryptFrom"
                    ],
                    "Resource": "*",
                    "Condition": {
                        "StringEquals": {
                            "kms:CallerAccount": "${var.account_id}"
                        },
                        "StringLike": {
                            "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${var.account_id}:trail/*"
                        }
                    }
                },
                {
                    "Sid": "Allow alias creation during setup",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "*"
                    },
                    "Action": "kms:CreateAlias",
                    "Resource": "*",
                    "Condition": {
                        "StringEquals": {
                            "kms:ViaService": "ec2.${var.region}.amazonaws.com",
                            "kms:CallerAccount": "${var.account_id}"
                        }
                    }
                },
                {
                    "Sid": "Enable cross account log decryption",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "*"
                    },
                    "Action": [
                        "kms:Decrypt",
                        "kms:ReEncryptFrom"
                    ],
                    "Resource": "*",
                    "Condition": {
                        "StringEquals": {
                            "kms:CallerAccount": "${var.account_id}"
                        },
                        "StringLike": {
                            "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${var.account_id}:trail/*"
                        }
                    }
                }
            ]
        }
        EOT
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "aws-cloudtrail-logs-${var.account_id}-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck20150319-726018a8-3413-47d8-8130-0b30cf3a63ac",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.cloudtrail.arn}",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudtrail:${var.region}:${var.account_id}:trail/${var.trail_name}"
                }
            }
        },
        {
            "Sid": "AWSCloudTrailWrite20150319-e03b0864-94c2-46ab-a7ab-2fdfd4fd5a4b",
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${var.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control",
                    "AWS:SourceArn": "arn:aws:cloudtrail:${var.region}:${var.account_id}:trail/${var.trail_name}"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_cloudtrail" "secrets_manager_trail" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  kms_key_id                    = aws_kms_key.key.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  advanced_event_selector {
    name = "Management events selector"
    field_selector {
      equals = [
        "Management",
      ]
      field = "eventCategory"
    }
  }
  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

data "aws_iam_policy_document" "policy" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.secrets_manager_events_queue.arn]
    sid       = "AllowEventBridgeToSendMessages"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.secrets_manager_events_rule.arn]
    }
    effect = "Allow"
  }
}
# Attach a policy to the SQS queue to allow EventBridge to send messages
resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.secrets_manager_events_queue.id

  policy = data.aws_iam_policy_document.policy.json
}

# Create an EventBridge rule to capture all Secrets Manager events
resource "aws_cloudwatch_event_rule" "secrets_manager_events_rule" {
  name = "secrets-manager-events-rule"

  event_pattern = jsonencode({
    source = ["aws.secretsmanager"]
  })
  ## For GetSecretValue Logging, uncomment below
  # state = "ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS"
}

# Create an EventBridge target to send events to the SQS queue
resource "aws_cloudwatch_event_target" "secrets_manager_events_target" {
  rule      = aws_cloudwatch_event_rule.secrets_manager_events_rule.name
  target_id = "send-to-sqs"
  arn       = aws_sqs_queue.secrets_manager_events_queue.arn
}
