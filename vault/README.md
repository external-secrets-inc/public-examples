# Setup Hashicorp Vault for Async Rotator

This folder contains code to setup everything needed for Hashicorp Vault to send Audit Log events to Async Rotator.

It is intended to be used together with `kind` for a local setup, and not production usage. It considers both Hashicorp Vault and Async Rotator are installed within the same cluster.

In order to try it:

1. Install ESO And Async Rotator:
```
helm install external-secrets external-secrets/external-secrets

## Get installation link from https://app.externalsecrets.com/<your-org-name>/rotators
curl \
https://api.externalsecrets.com/public/rotators/$rotator_id/manifest/latest\
\?token\=$token
```

2. Install Hashicorp Vault locally:
```
helm install vault -n vault --create-namespace hashicorp/vault --set server.dev.enabled=true --set dataStorage.enabled=false
```

3. Configure Vault to send information to Async Rotator:
```
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN=root # dev mode
kubectl port-forward -n vault svc/vault 8200:8200 &
vault audit enable socket address=async-rotator-controller-manager-socket.async-rotator-system:8000 socket_type=tcp
# create a vault secret
vault kv put -mount secret key-in-vault key=value
```

4. Create a Vault Async Rotator manifest:
```
cat << EOF | kubectl apply -f -
apiVersion: eso.externalsecrets.com/v1
kind: AsyncRotator
metadata:
  name: vault-rotator
  namespace: default
spec:
  notificationSources:
    - type: HashicorpVault
      hashicorpVault:
        host: 0.0.0.0
        port: 8000
  secretsToWatch:
    - namespaceSelectors:
      - matchLabels: {} # match all namespaces
EOF
```
5. Create SecretStore targetting vault
```
cat << EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: default
spec:
  provider:
    vault:
      server: "http://vault.vault:8200"
      path: "secret"
      version: "v2"
      auth:
        tokenSecretRef:
          name: "vault-token"
          key: "token"
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-token
  namespace: default
data:
  token: cm9vdA== # "root"
EOF
```
6. Create ExternalSecret
```
cat << EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: vault-example
spec:
  refreshInterval: "720h"
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: example-sync
  data:
  - secretKey: my-key
    remoteRef:
      key: key-in-vault
      property: key
EOF
kubectl get secret example-sync -o jsonpath='{.data.my-key}' | base64 -d ## value
```
7. Update vault secret and check for immediate secret change
```
vault kv put -mount secret key-in-vault key=new-value
kubectl get secret example-sync -o jsonpath='{.data.my-key}' | base64 -d ## new-value
```