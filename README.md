# Azure API Management Module

This Terraform module creates a comprehensive Azure API Management service with enterprise-grade features including security, monitoring, API products, policies, and governance.

## Features

- **Virtual Network Integration**: Secure deployment within virtual networks
- **Multi-region Deployment**: Global API distribution with additional locations
- **API Products & APIs**: Complete API lifecycle management
- **Custom Policies**: XML-based policies for request/response manipulation
- **Named Values**: Secure property management for configuration
- **Developer Portal**: Customizable developer experience
- **Monitoring**: Comprehensive diagnostic settings and Azure Policy integration
- **Security**: Managed identity, CORS, rate limiting, and authentication
- **Compliance**: Built-in Azure Policy assignments for governance

## Architecture

The module creates the following Azure resources:

- API Management Service (with VNet integration)
- API Products (with policies and subscriptions)
- APIs (with operations and policies)
- Named Values (properties for configuration)
- Diagnostic Settings (logs and metrics)
- Azure Policy Assignments (optional)

## Usage

### Basic API Management Service

```hcl
module "api_management" {
  source = "./modules/integration/api-management"

  resource_group_name = "rg-apim"
  location           = "East US"
  environment       = "prod"

  publisher_name  = "My Company"
  publisher_email = "api@company.com"
  sku_name        = "Developer_1"

  tags = {
    Environment = "prod"
  }
}
```

### Enterprise API Management with Products and APIs

```hcl
module "api_management_enterprise" {
  source = "./modules/integration/api-management"

  resource_group_name = "rg-apim"
  location           = "East US"
  environment       = "prod"
  api_management_name = "apim-enterprise"

  publisher_name  = "Enterprise API Platform"
  publisher_email = "api-platform@company.com"
  sku_name        = "Premium_1"

  # Virtual Network Integration
  virtual_network_type = "External"
  virtual_network_configuration = {
    subnet_id = azurerm_subnet.apim.id
  }

  # Multi-region
  additional_location = [
    {
      location = "West Europe"
      capacity = 1
    }
  ]

  # Managed Identity
  identity = {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.apim.id]
  }

  # Developer Portal
  sign_in = {
    enabled = true
  }

  sign_up = {
    enabled = true
    terms_of_service = {
      enabled          = true
      consent_required = true
      text             = "Terms of service text"
    }
  }

  # API Products
  products = {
    "free-tier" = {
      display_name          = "Free Tier"
      description           = "Basic API access"
      approval_required     = false
      published             = true
      subscription_required = true
      subscriptions_limit   = 100
      policy = {
        xml_content = "<policies><inbound><rate-limit calls=\"1000\" renewal-period=\"2592000\" /></inbound></policies>"
      }
    }
  }

  # APIs
  apis = {
    "petstore" = {
      name         = "petstore-api"
      display_name = "Petstore API"
      description  = "Sample API"
      path         = "petstore"
      protocols    = ["https"]
      service_url  = "https://api.example.com"
      operations = {
        "get-pets" = {
          display_name = "Get Pets"
          method       = "GET"
          url_template = "/pets"
        }
      }
    }
  }

  # Named Values
  named_values = {
    "api-key" = {
      display_name = "API Key"
      value        = "secret-key"
      secret       = true
    }
  }

  # Monitoring
  diagnostic_settings = {
    "diagnostics" = {
      name                       = "diag-apim"
      log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
      logs = [
        { category = "GatewayLogs" },
        { category = "WebSocketConnectionLogs" }
      ]
      metrics = [
        { category = "AllMetrics", enabled = true }
      ]
    }
  }

  # Security & Compliance
  enable_policy_assignments = true
  enable_custom_policies    = true

  tags = {
    Environment = "prod"
    Compliance  = "sox-pci"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.80.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.80.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| api_management_name | Name of the API Management service | `string` | `null` | no |
| publisher_name | Publisher name | `string` | n/a | yes |
| publisher_email | Publisher email | `string` | n/a | yes |
| sku_name | SKU name | `string` | `"Developer_1"` | no |
| virtual_network_type | Virtual network type | `string` | `"None"` | no |
| virtual_network_configuration | Virtual network configuration | `object({...})` | `null` | no |
| additional_location | Additional locations | `list(object({...}))` | `[]` | no |
| zones | Availability zones | `list(string)` | `[]` | no |
| identity | Managed identity configuration | `object({...})` | `null` | no |
| sign_in | Sign-in settings | `object({...})` | `{enabled = true}` | no |
| sign_up | Sign-up settings | `object({...})` | `{enabled = false}` | no |
| products | API products configuration | `map(object({...}))` | `{}` | no |
| apis | APIs configuration | `map(object({...}))` | `{}` | no |
| named_values | Named values configuration | `map(object({...}))` | `{}` | no |
| diagnostic_settings | Diagnostic settings | `map(object({...}))` | `{}` | no |
| enable_policy_assignments | Enable Azure Policy assignments | `bool` | `false` | no |
| enable_custom_policies | Enable custom policies | `bool` | `false` | no |
| log_analytics_workspace_id | Log Analytics Workspace ID | `string` | `null` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_management_id | API Management service ID |
| api_management_name | API Management service name |
| api_management_gateway_url | Gateway URL |
| api_management_portal_url | Developer portal URL |
| api_management_management_api_url | Management API URL |
| api_management_scm_url | SCM URL |
| api_management_private_ip_addresses | Private IP addresses |
| product_ids | API product IDs |
| api_ids | API IDs |
| named_value_ids | Named value IDs |

## Testing

The module includes comprehensive Terratest coverage:

```bash
# Run all tests
cd test
go test -v

# Run specific test
go test -v -run TestApiManagementModule

# Run tests in parallel
go test -v -parallel 3
```

Test scenarios include:
- Basic API Management deployment
- Products and APIs validation
- Virtual network integration
- Output validation

## Security Considerations

- Use Virtual Network integration for private deployments
- Implement managed identity for secure authentication
- Configure CORS policies for web applications
- Use rate limiting and throttling policies
- Enable diagnostic logging for monitoring
- Implement JWT validation for API security
- Use named values for secure configuration management

## Cost Optimization

- Choose appropriate SKU based on API call volume
- Use Developer SKU for development/testing
- Configure rate limiting to prevent abuse
- Enable caching for frequently accessed data
- Use multi-region deployment for global performance

## Troubleshooting

### Common Issues

1. **Subnet delegation**: Ensure subnet is delegated to Microsoft.ApiManagement/service
2. **Certificate errors**: Verify certificate validity and trust chain
3. **Policy validation**: Check XML policy syntax
4. **VNet integration**: Confirm subnet size and NSG rules

### Diagnostic Logs

Enable diagnostic settings to collect:
- Gateway logs (requests/responses)
- WebSocket connection logs
- Performance metrics
- Error logs

## Contributing

1. Follow the existing code style and patterns
2. Add tests for new features
3. Update documentation
4. Ensure backward compatibility

## License

This module is licensed under the MIT License.