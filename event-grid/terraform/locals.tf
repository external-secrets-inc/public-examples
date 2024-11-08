locals {
  sp_name             = "${var.resource_prefix}-keyvault-officer"
  sp_secret_name      = "${var.resource_prefix}-sp-secret"
  resource_group_name = "${var.resource_prefix}-rg"
  keyvault_name       = "${var.resource_prefix}kv"
  secretstore_name    = "${var.resource_prefix}-secretstore"
  externalsecret_name = "${var.resource_prefix}-es"
  eg_sub_name         = "${var.resource_prefix}-egsub"
}