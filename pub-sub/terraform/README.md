# Setup GCP Pubsub for Async Rotator

This folder contains terraform code to setup everything needed for Async rotator to connect to a valid PubSub subscription.

It is intended to be used together with `kind` for a local setup, and not production usage, as it leverage GCP Service Account Keys.

In order to try it:

1. Install ESO And Async Rotator:
```
helm install external-secrets external-secrets/external-secrets

## Get installation link from https://app.externalsecrets.com/<your-org-name>/rotators
curl \
https://api.externalsecrets.com/public/rotators/$rotator_id/manifest/latest\
\?token\=$token
```
2. Create a test.tfvars file:
```
project_id = "your-test-project"
topic_name = "test-pubsub-rotator"
subscription_name = "rotator-subscription"
sink_name = "test-rotator-sink"
```

3. Init terraform:
```
terraform init -upgrade
```

4. Login to Gcloud:
```
gcloud auth application-default login
```

5. Plan/Apply:
```
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
```