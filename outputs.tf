# API Management Module Outputs

output "api_management_id" {
  description = "API Management service resource ID"
  value       = azurerm_api_management.main.id
}

output "api_management_name" {
  description = "API Management service name"
  value       = azurerm_api_management.main.name
}

output "api_management_gateway_url" {
  description = "API Management gateway URL"
  value       = azurerm_api_management.main.gateway_url
}

output "api_management_public_ip_addresses" {
  description = "API Management public IP addresses"
  value       = azurerm_api_management.main.public_ip_addresses
}

output "api_management_private_ip_addresses" {
  description = "API Management private IP addresses"
  value       = azurerm_api_management.main.private_ip_addresses
}

output "api_management_portal_url" {
  description = "API Management developer portal URL"
  value       = azurerm_api_management.main.portal_url
}

output "api_management_management_api_url" {
  description = "API Management management API URL"
  value       = azurerm_api_management.main.management_api_url
}

output "api_management_scm_url" {
  description = "API Management SCM URL"
  value       = azurerm_api_management.main.scm_url
}

output "api_management_identity" {
  description = "API Management managed identity"
  value       = azurerm_api_management.main.identity
}

output "api_management_additional_locations" {
  description = "API Management additional locations"
  value       = azurerm_api_management.main.additional_location
}

output "product_ids" {
  description = "API Management product IDs"
  value       = { for k, v in azurerm_api_management_product.products : k => v.id }
}

output "api_ids" {
  description = "API Management API IDs"
  value       = { for k, v in azurerm_api_management_api.apis : k => v.id }
}

output "named_value_ids" {
  description = "API Management named value (property) IDs"
  value       = { for k, v in azurerm_api_management_named_value.named_values : k => v.id }
}

output "resource_group_name" {
  description = "Resource group name"
  value       = var.resource_group_name
}

output "location" {
  description = "Azure region"
  value       = var.location
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "publisher_name" {
  description = "Publisher name"
  value       = var.publisher_name
}

output "publisher_email" {
  description = "Publisher email"
  value       = var.publisher_email
  sensitive   = true
}

output "sku_name" {
  description = "SKU name"
  value       = var.sku_name
}

output "tags" {
  description = "Resource tags"
  value       = local.tags
}