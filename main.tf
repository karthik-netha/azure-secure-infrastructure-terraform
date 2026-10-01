locals {
  name = "soclab-${var.suffix}"
  tags = { purpose = "personal-security-lab", managed_by = "terraform" }
  services = {
    blob  = { zone = "privatelink.blob.core.windows.net", group = "blob", id = azurerm_storage_account.lab.id }
    vault = { zone = "privatelink.vaultcore.azure.net", group = "vault", id = azurerm_key_vault.lab.id }
  }
}
resource "azurerm_resource_group" "lab" {
  name     = local.name
  location = var.location
  tags     = local.tags
}
resource "azurerm_virtual_network" "lab" {
  name                = "${local.name}-vnet"
  resource_group_name = azurerm_resource_group.lab.name
  location            = var.location
  address_space       = ["10.42.0.0/16"]
  tags                = local.tags
}
resource "azurerm_subnet" "endpoints" {
  name                              = "private-endpoints"
  resource_group_name               = azurerm_resource_group.lab.name
  virtual_network_name              = azurerm_virtual_network.lab.name
  address_prefixes                  = ["10.42.1.0/24"]
  private_endpoint_network_policies = "Enabled"
}
resource "azurerm_subnet" "clients" {
  name                 = "clients"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.42.2.0/24"]
}
resource "azurerm_network_security_group" "endpoints" {
  name                = "${local.name}-pe-nsg"
  resource_group_name = azurerm_resource_group.lab.name
  location            = var.location
  tags                = local.tags
  security_rule {
    name                       = "AllowClientTLS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.42.2.0/24"
    destination_address_prefix = "10.42.1.0/24"
  }
  security_rule {
    name                       = "DenyOtherInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "endpoints" {
  subnet_id                 = azurerm_subnet.endpoints.id
  network_security_group_id = azurerm_network_security_group.endpoints.id
}
resource "azurerm_log_analytics_workspace" "lab" {
  name                = "${local.name}-logs"
  resource_group_name = azurerm_resource_group.lab.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1
  tags                = local.tags
}
resource "azurerm_storage_account" "lab" {
  name                              = "soc${var.suffix}"
  resource_group_name               = azurerm_resource_group.lab.name
  location                          = var.location
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  account_kind                      = "StorageV2"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  public_network_access_enabled     = false
  allow_nested_items_to_be_public   = false
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = true
  tags                              = local.tags
  network_rules {
    default_action = "Deny"
    bypass         = ["None"]
  }
}
resource "azurerm_key_vault" "lab" {
  name                          = "kv-${var.suffix}"
  resource_group_name           = azurerm_resource_group.lab.name
  location                      = var.location
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = false
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  tags                          = local.tags
  network_acls {
    default_action = "Deny"
    bypass         = "None"
  }
}
resource "azurerm_user_assigned_identity" "reader" {
  name                = "${local.name}-reader"
  resource_group_name = azurerm_resource_group.lab.name
  location            = var.location
  tags                = local.tags
}
resource "azurerm_role_assignment" "blob_reader" {
  scope                = azurerm_storage_account.lab.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.reader.principal_id
  principal_type       = "ServicePrincipal"
}
resource "azurerm_role_assignment" "secret_reader" {
  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.reader.principal_id
  principal_type       = "ServicePrincipal"
}
resource "azurerm_private_dns_zone" "service" {
  for_each            = local.services
  name                = each.value.zone
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "service" {
  for_each              = local.services
  name                  = "${each.key}-link"
  resource_group_name   = azurerm_resource_group.lab.name
  private_dns_zone_name = azurerm_private_dns_zone.service[each.key].name
  virtual_network_id    = azurerm_virtual_network.lab.id
  registration_enabled  = false
  tags                  = local.tags
}
resource "azurerm_private_endpoint" "service" {
  for_each            = local.services
  name                = "${local.name}-${each.key}-pe"
  resource_group_name = azurerm_resource_group.lab.name
  location            = var.location
  subnet_id           = azurerm_subnet.endpoints.id
  tags                = local.tags
  private_service_connection {
    name                           = "${each.key}-connection"
    private_connection_resource_id = each.value.id
    subresource_names              = [each.value.group]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.service[each.key].id]
  }
  depends_on = [azurerm_subnet_network_security_group_association.endpoints]
}
resource "azurerm_monitor_diagnostic_setting" "vault" {
  name                       = "vault-audit"
  target_resource_id         = azurerm_key_vault.lab.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.lab.id
  enabled_log { category = "AuditEvent" }
}
resource "azurerm_monitor_diagnostic_setting" "blob" {
  name                       = "blob-audit"
  target_resource_id         = "${azurerm_storage_account.lab.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.lab.id
  enabled_log { category = "StorageRead" }
  enabled_log { category = "StorageWrite" }
  enabled_log { category = "StorageDelete" }
}
resource "azurerm_monitor_diagnostic_setting" "activity" {
  name                       = "${local.name}-activity"
  target_resource_id         = "/subscriptions/${var.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.lab.id
  enabled_log { category = "Administrative" }
  enabled_log { category = "Security" }
  enabled_log { category = "Policy" }
}
