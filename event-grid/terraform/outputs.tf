output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "region" {
  value = var.location
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "secretstore_name" {
  value = local.secretstore_name
}

output "externalsecret_name" {
  value = local.externalsecret_name
}

output "eventgrid_subscription_name" {
  value = local.eg_sub_name
}