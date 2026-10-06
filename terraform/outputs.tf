output "public_ip" {
  description = "Публічна IP-адреса Application Gateway"
  value       = azurerm_public_ip.agw.ip_address
}

output "azure_client_id" {
  description = "Client ID для секрету GitHub AZURE_CLIENT_ID"
  value       = azuread_application_registration.github.client_id
}

output "azure_tenant_id" {
  description = "Tenant ID для секрету GitHub AZURE_TENANT_ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Subscription ID для секрету GitHub AZURE_SUBSCRIPTION_ID"
  value       = data.azurerm_client_config.current.subscription_id
}
