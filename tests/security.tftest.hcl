mock_provider "azurerm" {}
variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  tenant_id       = "00000000-0000-0000-0000-000000000000"
  suffix          = "test1234"
}
run "security_defaults" {
  command = plan
  assert {
    condition     = !azurerm_storage_account.lab.public_network_access_enabled && !azurerm_key_vault.lab.public_network_access_enabled
    error_message = "Storage and vault must not expose public data endpoints."
  }
  assert {
    condition     = !azurerm_storage_account.lab.shared_access_key_enabled && !azurerm_storage_account.lab.allow_nested_items_to_be_public
    error_message = "Shared keys and anonymous blobs must stay disabled."
  }
  assert {
    condition     = azurerm_storage_account.lab.min_tls_version == "TLS1_2" && azurerm_storage_account.lab.https_traffic_only_enabled && azurerm_storage_account.lab.infrastructure_encryption_enabled
    error_message = "Storage encryption and TLS controls regressed."
  }
  assert {
    condition     = azurerm_key_vault.lab.rbac_authorization_enabled && azurerm_key_vault.lab.purge_protection_enabled
    error_message = "Vault needs RBAC and purge protection."
  }
  assert {
    condition     = azurerm_role_assignment.blob_reader.role_definition_name == "Storage Blob Data Reader" && azurerm_role_assignment.secret_reader.role_definition_name == "Key Vault Secrets User"
    error_message = "Workload roles must remain read-only."
  }
  assert {
    condition     = length(azurerm_private_endpoint.service) == 2 && length(azurerm_private_dns_zone_virtual_network_link.service) == 2
    error_message = "Both services require endpoints and DNS links."
  }
  assert {
    condition     = azurerm_subnet.endpoints.private_endpoint_network_policies == "Enabled" && length([for r in azurerm_network_security_group.endpoints.security_rule : r if r.access == "Allow" && r.source_address_prefix == "10.42.2.0/24" && r.destination_port_range == "443"]) == 1
    error_message = "Endpoint subnet must enforce the narrow client TLS rule."
  }
  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.blob.enabled_log) == 3 && length(azurerm_monitor_diagnostic_setting.vault.enabled_log) == 1 && length(azurerm_monitor_diagnostic_setting.activity.enabled_log) == 3
    error_message = "Required diagnostic categories are missing."
  }
}
run "reject_bad_suffix" {
  command = plan
  variables { suffix = "INVALID!" }
  expect_failures = [var.suffix]
}
run "reject_malformed_uuid" {
  command = plan
  variables { subscription_id = "123456789012345678901234567890123456" }
  expect_failures = [var.subscription_id]
}
