This example demonstrates how to work with an Azure Event Grid listener.

# Steps:

### 1. Create a Kind Cluster:
```shell
kind create cluster --config kind-config.yaml
```

### 2. Log in to Azure:
```shell
az login
```

### 3. Install External Secrets Operator, Async Rotator, and NGINX Ingress Controller:
You can obtain the Async Rotator installation link from `https://app.externalsecrets.com/<your-org-name>/rotators`
```shell
kubectl apply --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets
curl https://api.externalsecrets.com/public/rotators/$rotator_id/manifest/latest?token=$token
```

### 4. Configure Default Values:
Retrieve your subscription ID by running `az account show` and noting the value of the `id` field. Create a `terraform.tfvars` file and set the appropriate values:
```hcl
location            = "westeurope"
subscription_id     = "<your_subscription_id>"
resource_prefix     = "<use_any_value_here_without_dashes>"
create_subscription = false
```

### 5. Prepare Terraform:
The Terraform configuration creates a resource group, a Key Vault, and a Service Principal to be used by the External Secrets operator. It also creates a `SecretStore` and an `ExternalSecret` resource in the cluster.
```shell
terraform init -upgrade
```

### 6. Plan and Apply Terraform Configuration:
```shell
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```
Note the `externalsecret_name` from the Terraform output. By default, it should be `<resource_prefix>-es`.

### 7. Deploy the Event Grid Listener:
Update the values in `manifests/async-rotator.yaml` with the Event Grid subscription name and the external secret name. By default, the event subscription name is `<resource_prefix>-egsub`. You can retrieve the actual values by running `terraform show`.

We need to set these values in the deployment file before creating the Event Grid subscription because a handshake will occur between Event Grid and our listener. Our listener must be aware of the incoming subscription.

Once you update the values, deploy the manifests:
```shell
kubectl apply -f manifests/async-rotator.yaml
```

You now have a listener deployed, along with a service and an ingress.

### 8. Open a port to your service
```shell
kubectl port-forward service/eventgrid-rotator-service 8080:80 -n async-rotator-system
```