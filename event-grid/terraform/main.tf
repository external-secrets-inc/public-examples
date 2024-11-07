locals {
  sp_name             = "${var.resource_prefix}-keyvault-officer"
  sp_secret_name      = "${var.resource_prefix}-sp-secret"
  resource_group_name = "${var.resource_prefix}-rg"
  keyvault_name       = "${var.resource_prefix}kv"
  secretstore_name    = "${var.resource_prefix}-secretstore"
  externalsecret_name = "${var.resource_prefix}-es"
  eg_sub_name         = "${var.resource_prefix}-egsub"
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_key_vault" "kv" {
  name                      = local.keyvault_name
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  purge_protection_enabled  = false
  enable_rbac_authorization = true
}

resource "azuread_application" "app" {
  display_name = local.sp_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "sp" {
  client_id                    = azuread_application.app.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "password" {
  display_name   = "Password for ${local.sp_name}"
  application_id = azuread_application.app.id
}

# Assign Key Vault Secrets Officer role to the service principal
data "azurerm_role_definition" "kv_secrets_officer" {
  name  = "Key Vault Secrets Officer"
  scope = "/"
}

resource "azurerm_role_assignment" "sp_kv_secrets_officer" {
  principal_id       = azuread_service_principal.sp.object_id
  role_definition_id = data.azurerm_role_definition.kv_secrets_officer.id
  scope              = azurerm_key_vault.kv.id
}

resource "random_password" "externalsecret_value" {
  length  = 32
  special = true
}

resource "azurerm_key_vault_secret" "externalsecret" {
  name         = local.externalsecret_name
  value        = random_password.externalsecret_value.result
  key_vault_id = azurerm_key_vault.kv.id
}