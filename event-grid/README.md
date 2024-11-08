# Azure Event Grid Listener Example

This example demonstrates how to work with an Azure Event Grid listener.

## Steps

### 1. Download and Install ngrok:**
Download and install [ngrok](https://ngrok.com/). Ngrok is needed to open a tunnel to the async rotator service for handling the validation handshake for the Event Grid subscription.

### 2. Create a Kind Cluster:
```shell
kind create cluster --config kind-config.yaml
```

### 3. Log in to Azure:
```shell
az login
```

### 4. Install External Secrets Operator, Async Rotator, and NGINX Ingress Controller:
Obtain the Async Rotator installation link from `https://app.externalsecrets.com/<your-org-name>/rotators` and then execute the following commands:
```shell
kubectl apply --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets
curl https://api.externalsecrets.com/public/rotators/$rotator_id/manifest/latest?token=$token
```

### 5. Configure Default Values:
Retrieve your subscription ID by running `az account show` and noting the value of the `id` field. Create a `terraform.tfvars` file and set the appropriate values:
```hcl
location            = "westeurope"
subscription_id     = "<your_subscription_id>"
resource_prefix     = "<use_any_value_here_without_dashes>"
create_subscription = false
```

### 6. Prepare Terraform:
Terraform will create a resource group, a Key Vault, and a Service Principal for the External Secrets operator. It also creates a `SecretStore` and an `ExternalSecret` resource in the cluster.
```shell
terraform init -upgrade
```

### 7. Plan and Apply Terraform Configuration:
```shell
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```
Note the `externalsecret_name` from the Terraform output, which is typically `<resource_prefix>-es`.

### 8. Deploy the Event Grid Listener:
Update the values in `manifests/async-rotator.yaml` with the Event Grid subscription name and the external secret name. By default, the event subscription name is `<resource_prefix>-egsub`. You can get the actual values by running `terraform show`.

Set these values in the deployment file before creating the Event Grid subscription to ensure the validation handshake between Event Grid and your listener can occur. Once updated, deploy the manifests:
```shell
kubectl apply -f manifests/async-rotator.yaml
```
You should now have a listener deployed, along with a service and an ingress.

### 9. Expose the Event Grid Webhook as a Service:
```shell
kubectl -n async-rotator-system expose deployment async-rotator-controller-manager --type=ClusterIP --port 8000 --target-port=8000 --name=async-rotator-service
```

### 10. Open a Port to Your Service:
```shell
kubectl -n async-rotator-system port-forward service/async-rotator-service 8000:8000
```

### 11. Create a Tunnel with ngrok:
Create a tunnel to your exposed service using ngrok so that Event Grid can reach your service and complete the handshake process:
```shell
ngrok http 8000
```
Note the forwarding URL (e.g., `https://2b46-88-230-175-55.ngrok-free.app`).

### 12. Update the Terraform Configuration:
To create the Event Grid subscription, update `create_subscription` to `true` and set the `forwarding_url` with the ngrok forwarding URL in `terraform.tfvar`:
```hcl
create_subscription = true
forwarding_url      = "https://2b46-88-230-175-55.ngrok-free.app"
```

### 13. Apply Terraform:
Apply the Terraform configuration again to create the subscription, complete the handshake process, and start sending secret events to your Event Grid listener:
```shell
terraform apply -var-file=terraform.tfvars
```

Check the logs of the async rotator:
```shell
kubectl -n async-rotator-system logs -f deployments/async-rotator-controller-manager
```
You should see an output similar to:
```text
Registering handler for path    {"path": "/asyncrotatordemo-egsub"}
Starting server    {"addr": "localhost:8000"}
Validation URL call successful    {"status": "200 OK"}
```
This indicates the handshake was successful and the Event Grid listener is ready to receive events.

### 14. Update the Secret and Confirm the Rotation:
Update the value of the secret by running the command below. Change the vault name and secret name if you modified `resource_prefix` earlier:
```shell
az keyvault secret set --vault-name "asyncrotatordemokv" --name "asyncrotatordemo-es" --value "$(openssl rand -base64 32)"
```

### 15. Validate the Rotation Event:
Check the async rotator logs to confirm the annotation that triggers a sync on the External Secrets operator:
```text
Received secret new version created event    {"secret": "asyncrotatordemo-es"}
...
Annotated ExternalSecret    {"name": "asyncrotatordemo-es", "namespace": "default"}
```
### 16. Destroy the resources
```shell
terraform destroy --auto-approve
```