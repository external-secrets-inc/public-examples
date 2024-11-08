resource "kubernetes_secret" "azure_keyvault_secret" {
  metadata {
    name      = local.sp_secret_name
    namespace = "default"
  }

  data = {
    clientId     = azuread_service_principal.sp.client_id
    clientSecret = azuread_application_password.password.value
  }

  type = "Opaque"
}


resource "kubernetes_manifest" "secretstore_azure_keyvault_store" {
  depends_on = [kubernetes_secret.azure_keyvault_secret]
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
    metadata = {
      name      = local.secretstore_name
      namespace = "default"
    }
    spec = {
      provider = {
        azurekv = {
          authSecretRef = {
            clientId = {
              key  = "clientId"
              name = local.sp_secret_name
            }
            clientSecret = {
              key  = "clientSecret"
              name = local.sp_secret_name
            }
          }
          authType = "ServicePrincipal"
          tenantId = data.azuread_client_config.current.tenant_id
          vaultUrl = azurerm_key_vault.kv.vault_uri
        }
      }
    }
  }
}

resource "kubernetes_manifest" "external_secret" {
  depends_on = [kubernetes_manifest.secretstore_azure_keyvault_store]
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = local.externalsecret_name
      namespace = "default"
    }
    spec = {
      data = [
        {
          remoteRef = {
            key = local.externalsecret_name
          }
          secretKey = local.externalsecret_name
        },
      ]
      refreshInterval = "1h"
      secretStoreRef = {
        kind = "SecretStore"
        name = local.secretstore_name
      }
      target = {
        name = local.externalsecret_name
      }
    }
  }
}
