output "resource_group" { value = azurerm_resource_group.lab.name }
output "workspace_id" { value = azurerm_log_analytics_workspace.lab.id }
output "storage_account_name" { value = azurerm_storage_account.lab.name }
output "vault_name" { value = azurerm_key_vault.lab.name }
output "reader_identity_id" { value = azurerm_user_assigned_identity.reader.id }
output "reader_client_id" { value = azurerm_user_assigned_identity.reader.client_id }
