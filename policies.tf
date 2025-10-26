# Azure Policy Assignments for API Management Security and Compliance

# Require API Management services to use virtual network
resource "azurerm_subscription_policy_assignment" "apim_vnet_policy" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "apim-vnet-${var.environment}"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/34c877ad-507e-4c82-993e-3452a6e0ad3c" # API Management services should use a virtual network

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Require API Management services to disable public network access
resource "azurerm_subscription_policy_assignment" "apim_public_network" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "apim-public-network-${var.environment}"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/47015565-dc11-4d32-9e52-54223c154ac4" # API Management services should disable public network access

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Require diagnostic settings for API Management
resource "azurerm_subscription_policy_assignment" "apim_diagnostics" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "apim-diagnostics-${var.environment}"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/c89a4225-5319-4c87-9711-9e4a2c3a4978" # Diagnostic settings should be enabled on API Management

  parameters = jsonencode({
    effect = {
      value = "DeployIfNotExists"
    }
    profileName = {
      value = "setByPolicy"
    }
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
    metricsEnabled = {
      value = "true"
    }
    logsEnabled = {
      value = "true"
    }
  })
}

# Require API Management to use managed identity
resource "azurerm_subscription_policy_assignment" "apim_managed_identity" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "apim-managed-identity-${var.environment}"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/17c2a192-71e2-4eb2-9b84-144b9a0cb1b0" # API Management services should use managed identity

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Custom policy for API Management SKU validation
resource "azurerm_policy_definition" "apim_sku_policy" {
  count = var.enable_custom_policies ? 1 : 0

  name         = "apim-sku-validation"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "API Management should use approved SKUs"

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.ApiManagement/service"
        },
        {
          field = "Microsoft.ApiManagement/service/sku.name"
          notIn = ["Standard_1", "Premium_1", "Premium_2", "Premium_4", "Premium_8", "Premium_16"]
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })

  parameters = jsonencode({
    allowedSKUs = {
      type = "Array"
      metadata = {
        displayName = "Allowed SKUs"
        description = "List of allowed API Management SKUs"
      }
      defaultValue = ["Standard_1", "Premium_1", "Premium_2", "Premium_4", "Premium_8", "Premium_16"]
    }
  })
}

# Policy assignment for custom SKU policy
resource "azurerm_subscription_policy_assignment" "apim_sku_assignment" {
  count = var.enable_custom_policies ? 1 : 0

  name                 = "apim-sku-${var.environment}"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = azurerm_policy_definition.apim_sku_policy[0].id

  parameters = jsonencode({
    allowedSKUs = {
      value = ["Standard_1", "Premium_1", "Premium_2", "Premium_4", "Premium_8", "Premium_16"]
    }
  })
}

# Require API Management to have custom domain
resource "azurerm_subscription_policy_assignment" "apim_custom_domain" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "apim-custom-domain-${var.environment}"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2e0156aa-427a-4c4c-9561-3b8444d3b116" # API Management services should have custom domain configured

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Require API Management to use HTTPS
resource "azurerm_subscription_policy_assignment" "apim_https_only" {
  count = var.enable_policy_assignments ? 1 : 0

  name                 = "apim-https-only-${var.environment}"
  subscription_id      = data.azurerm_client_config.current.subscription_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2e0156aa-427a-4c4c-9561-3b8444d3b116" # API Management services should only accept HTTPS

  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}

# Data source for client configuration
data "azurerm_client_config" "current" {}