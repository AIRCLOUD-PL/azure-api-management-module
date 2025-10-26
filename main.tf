# Azure API Management Service Module
# Enterprise-grade API Management with security, monitoring, and governance features

locals {
  api_management_name = var.api_management_name != null ? var.api_management_name : "${var.naming_prefix}-${var.environment}-${random_string.suffix.result}"

  # Default tags
  default_tags = {
    Environment       = var.environment
    Module            = "api-management"
    ManagedBy         = "terraform"
    Owner             = "platform-team"
    CostCenter        = "api-management"
    Confidentiality   = "internal"
    Compliance        = "sox-pci"
    Backup            = "daily"
    MaintenanceWindow = "sunday-02:00"
  }

  tags = merge(local.default_tags, var.tags)
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

# API Management Service
resource "azurerm_api_management" "main" {
  name                = local.api_management_name
  location            = var.location
  resource_group_name = var.resource_group_name

  publisher_name  = var.publisher_name
  publisher_email = var.publisher_email

  sku_name = var.sku_name

  # Virtual network configuration
  dynamic "virtual_network_configuration" {
    for_each = var.virtual_network_type != "None" && var.virtual_network_configuration != null ? [1] : []
    content {
      subnet_id = var.virtual_network_configuration.subnet_id
    }
  }

  virtual_network_type = var.virtual_network_type

  # Additional locations for multi-region
  dynamic "additional_location" {
    for_each = var.additional_location
    content {
      location = additional_location.value.location
      capacity = additional_location.value.capacity
    }
  }

  # Availability zones
  zones = var.zones

  # Managed identity
  dynamic "identity" {
    for_each = var.identity != null ? [1] : []
    content {
      type         = var.identity.type
      identity_ids = var.identity.identity_ids
    }
  }

  # Sign-in settings
  dynamic "sign_in" {
    for_each = var.sign_in != null ? [1] : []
    content {
      enabled = var.sign_in.enabled
    }
  }

  # Sign-up settings
  dynamic "sign_up" {
    for_each = var.sign_up != null ? [1] : []
    content {
      enabled = var.sign_up.enabled

      dynamic "terms_of_service" {
        for_each = var.sign_up.terms_of_service != null ? [1] : []
        content {
          enabled          = var.sign_up.terms_of_service.enabled
          consent_required = var.sign_up.terms_of_service.consent_required
          text             = var.sign_up.terms_of_service.text
        }
      }
    }
  }

  tags = local.tags
}

# Global Policy
resource "azurerm_api_management_policy" "global" {
  count = var.policy != null ? 1 : 0

  api_management_id = azurerm_api_management.main.id

  xml_content = var.policy.xml_content
  xml_link    = var.policy.xml_link
}

# API Products
resource "azurerm_api_management_product" "products" {
  for_each = var.products

  product_id          = each.key
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  display_name          = each.value.display_name
  description           = each.value.description
  approval_required     = each.value.approval_required
  published             = each.value.published
  subscription_required = each.value.subscription_required
  subscriptions_limit   = each.value.subscriptions_limit
  terms                 = each.value.terms
}

# Product Policies
resource "azurerm_api_management_product_policy" "product_policies" {
  for_each = { for k, v in var.products : k => v if v.policy != null }

  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
  product_id          = azurerm_api_management_product.products[each.key].product_id

  xml_content = each.value.policy.xml_content
  xml_link    = each.value.policy.xml_link
}

# APIs
resource "azurerm_api_management_api" "apis" {
  for_each = var.apis

  name                = each.key
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  display_name = each.value.display_name
  description  = each.value.description
  path         = each.value.path
  protocols    = each.value.protocols
  revision     = each.value.revision
  service_url  = each.value.service_url

  subscription_key_parameter_names {
    header = each.value.subscription_key_parameter_names.header
    query  = each.value.subscription_key_parameter_names.query
  }

  dynamic "import" {
    for_each = each.value.import != null ? [1] : []
    content {
      content_format = each.value.import.content_format
      content_value  = each.value.import.content_value

      dynamic "wsdl_selector" {
        for_each = each.value.import.wsdl_selector != null ? [1] : []
        content {
          service_name  = each.value.import.wsdl_selector.service_name
          endpoint_name = each.value.import.wsdl_selector.endpoint_name
        }
      }
    }
  }
}

# API Policies
resource "azurerm_api_management_api_policy" "api_policies" {
  for_each = { for k, v in var.apis : k => v if v.policy != null }

  api_name            = azurerm_api_management_api.apis[each.key].name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  xml_content = each.value.policy.xml_content
  xml_link    = each.value.policy.xml_link
}

# API Operations
resource "azurerm_api_management_api_operation" "operations" {
  for_each = merge([
    for api_key, api in var.apis : {
      for op_key, op in api.operations : "${api_key}-${op_key}" => merge(op, {
        api_name = api_key
      })
    }
  ]...)

  operation_id        = each.key
  api_name            = azurerm_api_management_api.apis[each.value.api_name].name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  display_name = each.value.display_name
  method       = each.value.method
  url_template = each.value.url_template
  description  = each.value.description
}

# Operation Policies
resource "azurerm_api_management_api_operation_policy" "operation_policies" {
  for_each = merge([
    for api_key, api in var.apis : {
      for op_key, op in api.operations : "${api_key}-${op_key}" => merge(op, {
        api_name = api_key
      }) if op.policy != null
    }
  ]...)

  operation_id        = each.key
  api_name            = azurerm_api_management_api.apis[each.value.api_name].name
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  xml_content = each.value.policy.xml_content
  xml_link    = each.value.policy.xml_link
}

# Product-API Associations
resource "azurerm_api_management_product_api" "product_apis" {
  for_each = merge([
    for product_key, product in var.products : {
      for api_key in product.subscriptions : "${product_key}-${api_key}" => {
        product_id = product_key
        api_name   = api_key
      }
    }
  ]...)

  api_name            = azurerm_api_management_api.apis[each.value.api_name].name
  product_id          = azurerm_api_management_product.products[each.value.product_id].product_id
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name
}

# Named Values (Properties)
resource "azurerm_api_management_named_value" "named_values" {
  for_each = var.named_values

  name                = each.key
  api_management_name = azurerm_api_management.main.name
  resource_group_name = var.resource_group_name

  display_name = each.value.display_name
  value        = each.value.value
  secret       = each.value.secret
  tags         = each.value.tags
}

# Diagnostic Settings
resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name                       = each.value.name
  target_resource_id         = azurerm_api_management.main.id
  log_analytics_workspace_id = each.value.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = each.value.logs
    content {
      category = enabled_log.value.category
    }
  }

  dynamic "metric" {
    for_each = each.value.metrics
    content {
      category = metric.value.category
      enabled  = metric.value.enabled
    }
  }
}