resource "azurerm_eventgrid_system_topic" "kv" {
  name                   = "${var.resource_prefix}-topic"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  source_arm_resource_id = azurerm_key_vault.kv.id
  topic_type             = "Microsoft.KeyVault.vaults"
}

resource "azurerm_eventgrid_event_subscription" "keyvault_secret_subscription" {
  name                  = local.eg_sub_name
  scope                 = azurerm_key_vault.kv.id
  event_delivery_schema = "EventGridSchema"

  included_event_types = [
    "Microsoft.KeyVault.SecretNewVersionCreated"
  ]

  webhook_endpoint {
    url = "${var.forwarding_url}/${local.eg_sub_name}"
  }
}