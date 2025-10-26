# API Management Module - Complete Enterprise Example

# This example demonstrates a production-ready API Management deployment with:
# - Virtual network integration for security
# - Multiple API products and APIs
# - Custom policies and named values
# - Comprehensive monitoring and diagnostics
# - Azure Policy integration
# - Multi-region deployment

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "rg-apim-example"
  location = "East US"

  tags = {
    Environment = "example"
    Module      = "api-management"
    Owner       = "platform-team"
  }
}

# Log Analytics Workspace for diagnostics
resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-apim-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "example"
  }
}

# Virtual Network for API Management
resource "azurerm_virtual_network" "example" {
  name                = "vnet-apim-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "example"
  }
}

resource "azurerm_subnet" "apim" {
  name                 = "snet-apim"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]

  # Delegate subnet to API Management
  delegation {
    name = "Microsoft.ApiManagement.service"
    service_delegation {
      name = "Microsoft.ApiManagement/service"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "apim" {
  name                = "uai-apim-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  tags = {
    Environment = "example"
  }
}

# API Management Module
module "api_management" {
  source = "../"

  # Basic Configuration
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  environment         = "example"
  api_management_name = "apim-enterprise-example"

  publisher_name  = "Enterprise API Platform"
  publisher_email = "api-platform@company.com"

  # SKU Configuration
  sku_name = "Premium_1"

  # Virtual Network Integration
  virtual_network_type = "External"
  virtual_network_configuration = {
    subnet_id = azurerm_subnet.apim.id
  }

  # Multi-region deployment
  additional_location = [
    {
      location = "West Europe"
      capacity = 1
    }
  ]

  # Managed Identity
  identity = {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apim.id]
  }

  # Developer Portal Settings
  sign_in = {
    enabled = true
  }

  sign_up = {
    enabled = true
    terms_of_service = {
      enabled          = true
      consent_required = true
      text             = "By signing up, you agree to our terms of service."
    }
  }

  # API Products
  products = {
    "free-tier" = {
      display_name          = "Free Tier"
      description           = "Basic API access for developers"
      approval_required     = false
      published             = true
      subscription_required = true
      subscriptions_limit   = 100
      terms                 = "Free tier limited to 1000 calls per month"
      subscriptions         = ["petstore-api"]
      policy = {
        xml_content = <<XML
<policies>
  <inbound>
    <rate-limit calls="1000" renewal-period="2592000" />
  </inbound>
</policies>
XML
      }
    }
    "premium-tier" = {
      display_name          = "Premium Tier"
      description           = "Full API access with advanced features"
      approval_required     = true
      published             = true
      subscription_required = true
      subscriptions_limit   = 50
      terms                 = "Premium tier with unlimited calls"
      subscriptions         = ["petstore-api", "weather-api"]
      policy = {
        xml_content = <<XML
<policies>
  <inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized">
      <openid-config url="https://login.microsoftonline.com/common/.well-known/openid_configuration" />
      <audiences>
        <audience>api://api-management</audience>
      </audiences>
    </validate-jwt>
  </inbound>
</policies>
XML
      }
    }
  }

  # APIs
  apis = {
    "petstore-api" = {
      name         = "petstore-api"
      display_name = "Petstore API"
      description  = "Sample Petstore API for demonstration"
      path         = "petstore"
      protocols    = ["https"]
      service_url  = "https://petstore.swagger.io/v2"
      policy = {
        xml_content = <<XML
<policies>
  <inbound>
    <cors allow-credentials="true">
      <allowed-origins>
        <origin>https://developer.company.com</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
      </allowed-methods>
    </cors>
  </inbound>
</policies>
XML
      }
      operations = {
        "get-pets" = {
          display_name = "Get Pets"
          method       = "GET"
          url_template = "/pets"
          description  = "Retrieve all pets"
          policy = {
            xml_content = <<XML
<policies>
  <inbound>
    <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" downstream-caching-type="public" must-revalidate="true">
      <vary-by-query-parameter>limit</vary-by-query-parameter>
    </cache-lookup>
  </inbound>
  <outbound>
    <cache-store duration="300" />
  </outbound>
</policies>
XML
          }
        }
        "create-pet" = {
          display_name = "Create Pet"
          method       = "POST"
          url_template = "/pets"
          description  = "Create a new pet"
        }
      }
    }
    "weather-api" = {
      name         = "weather-api"
      display_name = "Weather API"
      description  = "Weather information API"
      path         = "weather"
      protocols    = ["https"]
      service_url  = "https://api.weather.com/v1"
      operations = {
        "get-forecast" = {
          display_name = "Get Forecast"
          method       = "GET"
          url_template = "/forecast/{location}"
          description  = "Get weather forecast for a location"
        }
      }
    }
  }

  # Named Values (Properties)
  named_values = {
    "database-connection-string" = {
      display_name = "Database Connection String"
      value        = "Server=tcp:sql-server.database.windows.net,1433;Database=my-database;"
      secret       = true
      tags         = ["database", "connection"]
    }
    "external-api-key" = {
      display_name = "External API Key"
      value        = "external-api-key-12345"
      secret       = true
      tags         = ["api", "external"]
    }
    "environment-name" = {
      display_name = "Environment Name"
      value        = "production"
      secret       = false
      tags         = ["environment"]
    }
  }

  # Diagnostic Settings
  diagnostic_settings = {
    "diagnostics" = {
      name                       = "diag-apim"
      log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
      logs = [
        {
          category = "GatewayLogs"
        },
        {
          category = "WebSocketConnectionLogs"
        }
      ]
      metrics = [
        {
          category = "AllMetrics"
          enabled  = true
        }
      ]
    }
  }

  # Azure Policy Integration
  enable_policy_assignments  = true
  enable_custom_policies     = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  # Tags
  tags = {
    Environment       = "example"
    Project           = "enterprise-api-platform"
    CostCenter        = "api-management"
    Owner             = "platform-team"
    Confidentiality   = "internal"
    Compliance        = "sox-pci"
    Backup            = "daily"
    MaintenanceWindow = "sunday-02:00"
  }
}

# Outputs
output "api_management_id" {
  description = "API Management service ID"
  value       = module.api_management.api_management_id
}

output "api_management_name" {
  description = "API Management service name"
  value       = module.api_management.api_management_name
}

output "api_management_gateway_url" {
  description = "API Management gateway URL"
  value       = module.api_management.api_management_gateway_url
}

output "api_management_portal_url" {
  description = "API Management developer portal URL"
  value       = module.api_management.api_management_portal_url
}

output "api_management_management_api_url" {
  description = "API Management management API URL"
  value       = module.api_management.api_management_management_api_url
}

output "product_ids" {
  description = "API product IDs"
  value       = module.api_management.product_ids
}

output "api_ids" {
  description = "API IDs"
  value       = module.api_management.api_ids
}

output "named_value_ids" {
  description = "Named value IDs"
  value       = module.api_management.named_value_ids
}

output "private_ip_addresses" {
  description = "API Management private IP addresses"
  value       = module.api_management.api_management_private_ip_addresses
}