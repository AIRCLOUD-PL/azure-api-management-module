<p align="center">
  <a href="https://aircloud.com.pl"><img src=".github/assets/banner.png" alt="AIRCLOUD: DevOps, cloud and AI engineering" width="100%"></a>
</p>

# azure-api-management-module

**Azure API Management Terraform module — parameterised, azurerm 4.x, CI-validated.**

[![CI](https://github.com/AIRCLOUD-PL/azure-api-management-module/actions/workflows/ci.yml/badge.svg)](https://github.com/AIRCLOUD-PL/azure-api-management-module/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/AIRCLOUD-PL/azure-api-management-module?sort=semver)](https://github.com/AIRCLOUD-PL/azure-api-management-module/releases)

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

Pin the module to a release tag:

```hcl
module "api_management" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-api-management-module.git?ref=v1.0.0"

  # required inputs
  environment         = "..."
  location            = "..."
  publisher_email     = "..."
  publisher_name      = "..."
  resource_group_name = "..."
}
```

All inputs and outputs are listed in the generated reference below ([Inputs](#inputs), [Outputs](#outputs)). Worked examples live in [`examples/`](examples/).

### Basic API Management Service

```hcl
module "api_management" {
  source = "git::https://github.com/AIRCLOUD-PL/azure-api-management-module.git?ref=v1.0.0"

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
  source = "git::https://github.com/AIRCLOUD-PL/azure-api-management-module.git?ref=v1.0.0"

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

## Reference

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.81.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_api_management.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management) | resource |
| [azurerm_api_management_api.apis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api) | resource |
| [azurerm_api_management_api_operation.operations](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation) | resource |
| [azurerm_api_management_api_operation_policy.operation_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_operation_policy) | resource |
| [azurerm_api_management_api_policy.api_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_api_policy) | resource |
| [azurerm_api_management_named_value.named_values](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_named_value) | resource |
| [azurerm_api_management_policy.global](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_policy) | resource |
| [azurerm_api_management_product.products](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_product) | resource |
| [azurerm_api_management_product_api.product_apis](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_product_api) | resource |
| [azurerm_api_management_product_policy.product_policies](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management_product_policy) | resource |
| [azurerm_monitor_diagnostic_setting.diagnostic_settings](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_policy_definition.apim_sku_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) | resource |
| [azurerm_subscription_policy_assignment.apim_custom_domain](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.apim_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.apim_https_only](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.apim_managed_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.apim_public_network](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.apim_sku_assignment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [azurerm_subscription_policy_assignment.apim_vnet_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subscription_policy_assignment) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_location"></a> [additional\_location](#input\_additional\_location) | Additional location configurations for multi-region deployment | <pre>list(object({<br/>    location = string<br/>    capacity = optional(number, 1)<br/>    zones    = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_api_management_name"></a> [api\_management\_name](#input\_api\_management\_name) | Name of the API Management service. If null, will be auto-generated. | `string` | `null` | no |
| <a name="input_apis"></a> [apis](#input\_apis) | API configurations | <pre>map(object({<br/>    name         = string<br/>    display_name = string<br/>    description  = optional(string)<br/>    path         = string<br/>    protocols    = optional(list(string), ["https"])<br/>    revision     = optional(string, "1")<br/>    service_url  = optional(string)<br/>    subscription_key_parameter_names = optional(object({<br/>      header = string<br/>      query  = string<br/>      }), {<br/>      header = "Ocp-Apim-Subscription-Key"<br/>      query  = "subscription-key"<br/>    })<br/>    import = optional(object({<br/>      content_format = string<br/>      content_value  = string<br/>      wsdl_selector = optional(object({<br/>        service_name  = string<br/>        endpoint_name = string<br/>      }))<br/>    }))<br/>    policy = optional(object({<br/>      xml_content = string<br/>      xml_link    = optional(string)<br/>    }))<br/>    operations = optional(map(object({<br/>      display_name = string<br/>      method       = string<br/>      url_template = string<br/>      description  = optional(string)<br/>      policy = optional(object({<br/>        xml_content = string<br/>        xml_link    = optional(string)<br/>      }))<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_capacity"></a> [capacity](#input\_capacity) | Capacity of the API Management service | `number` | `1` | no |
| <a name="input_certificates"></a> [certificates](#input\_certificates) | Certificate configurations | <pre>map(object({<br/>    certificate = string<br/>    password    = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_delegation"></a> [delegation](#input\_delegation) | Delegation settings | <pre>object({<br/>    enabled        = bool<br/>    validation_key = optional(string)<br/>    url            = optional(string)<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings) | Diagnostic settings configurations | <pre>map(object({<br/>    name                       = string<br/>    log_analytics_workspace_id = string<br/>    logs = list(object({<br/>      category = string<br/>    }))<br/>    metrics = list(object({<br/>      category = string<br/>      enabled  = bool<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_enable_backend_tls11"></a> [enable\_backend\_tls11](#input\_enable\_backend\_tls11) | Enable TLS 1.1 for backend | `bool` | `false` | no |
| <a name="input_enable_backend_tls12"></a> [enable\_backend\_tls12](#input\_enable\_backend\_tls12) | Enable TLS 1.2 for backend | `bool` | `true` | no |
| <a name="input_enable_custom_policies"></a> [enable\_custom\_policies](#input\_enable\_custom\_policies) | Enable custom Azure Policy definitions | `bool` | `false` | no |
| <a name="input_enable_frontend_tls10"></a> [enable\_frontend\_tls10](#input\_enable\_frontend\_tls10) | Enable TLS 1.0 for frontend | `bool` | `false` | no |
| <a name="input_enable_frontend_tls11"></a> [enable\_frontend\_tls11](#input\_enable\_frontend\_tls11) | Enable TLS 1.1 for frontend | `bool` | `false` | no |
| <a name="input_enable_frontend_tls12"></a> [enable\_frontend\_tls12](#input\_enable\_frontend\_tls12) | Enable TLS 1.2 for frontend | `bool` | `true` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Enable HTTP/2 protocol | `bool` | `true` | no |
| <a name="input_enable_policy_assignments"></a> [enable\_policy\_assignments](#input\_enable\_policy\_assignments) | Enable Azure Policy assignments for API Management security | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., prod, dev, test) | `string` | n/a | yes |
| <a name="input_hostname_configurations"></a> [hostname\_configurations](#input\_hostname\_configurations) | Custom hostname configurations | <pre>list(object({<br/>    type                         = string<br/>    host_name                    = string<br/>    key_vault_id                 = optional(string)<br/>    certificate                  = optional(string)<br/>    certificate_password         = optional(string)<br/>    negotiate_client_certificate = optional(bool, false)<br/>    default_ssl_binding          = optional(bool, false)<br/>  }))</pre> | `[]` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | Managed identity configuration | <pre>object({<br/>    type         = string<br/>    identity_ids = optional(list(string), [])<br/>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where resources will be created | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics Workspace ID for diagnostic settings | `string` | `null` | no |
| <a name="input_min_api_version"></a> [min\_api\_version](#input\_min\_api\_version) | Minimum API version supported | `string` | `"2019-12-01"` | no |
| <a name="input_named_values"></a> [named\_values](#input\_named\_values) | Named values (properties) configuration | <pre>map(object({<br/>    display_name = string<br/>    value        = string<br/>    secret       = optional(bool, false)<br/>    tags         = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_naming_prefix"></a> [naming\_prefix](#input\_naming\_prefix) | Prefix for API Management naming | `string` | `"apim"` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | Global policy configuration | <pre>object({<br/>    xml_content = string<br/>    xml_link    = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_products"></a> [products](#input\_products) | API products configuration | <pre>map(object({<br/>    display_name          = string<br/>    description           = optional(string)<br/>    approval_required     = optional(bool, false)<br/>    published             = optional(bool, true)<br/>    subscription_required = optional(bool, true)<br/>    subscriptions_limit   = optional(number)<br/>    terms                 = optional(string)<br/>    state                 = optional(string, "published")<br/>    subscriptions         = optional(list(string), [])<br/>    policy = optional(object({<br/>      xml_content = string<br/>      xml_link    = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_publisher_email"></a> [publisher\_email](#input\_publisher\_email) | Publisher email for the API Management service | `string` | n/a | yes |
| <a name="input_publisher_name"></a> [publisher\_name](#input\_publisher\_name) | Publisher name for the API Management service | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | n/a | yes |
| <a name="input_sign_in"></a> [sign\_in](#input\_sign\_in) | Sign-in settings | <pre>object({<br/>    enabled = bool<br/>  })</pre> | <pre>{<br/>  "enabled": true<br/>}</pre> | no |
| <a name="input_sign_up"></a> [sign\_up](#input\_sign\_up) | Sign-up settings | <pre>object({<br/>    enabled = bool<br/>    terms_of_service = optional(object({<br/>      enabled          = bool<br/>      consent_required = bool<br/>      text             = string<br/>    }))<br/>  })</pre> | <pre>{<br/>  "enabled": false<br/>}</pre> | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU name for the API Management service | `string` | `"Developer_1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_network_configuration"></a> [virtual\_network\_configuration](#input\_virtual\_network\_configuration) | Virtual network configuration | <pre>object({<br/>    subnet_id = string<br/>  })</pre> | `null` | no |
| <a name="input_virtual_network_type"></a> [virtual\_network\_type](#input\_virtual\_network\_type) | Virtual network type for API Management | `string` | `"None"` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | Availability zones for the API Management service | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_ids"></a> [api\_ids](#output\_api\_ids) | API Management API IDs |
| <a name="output_api_management_additional_locations"></a> [api\_management\_additional\_locations](#output\_api\_management\_additional\_locations) | API Management additional locations |
| <a name="output_api_management_gateway_url"></a> [api\_management\_gateway\_url](#output\_api\_management\_gateway\_url) | API Management gateway URL |
| <a name="output_api_management_id"></a> [api\_management\_id](#output\_api\_management\_id) | API Management service resource ID |
| <a name="output_api_management_identity"></a> [api\_management\_identity](#output\_api\_management\_identity) | API Management managed identity |
| <a name="output_api_management_management_api_url"></a> [api\_management\_management\_api\_url](#output\_api\_management\_management\_api\_url) | API Management management API URL |
| <a name="output_api_management_name"></a> [api\_management\_name](#output\_api\_management\_name) | API Management service name |
| <a name="output_api_management_portal_url"></a> [api\_management\_portal\_url](#output\_api\_management\_portal\_url) | API Management developer portal URL |
| <a name="output_api_management_private_ip_addresses"></a> [api\_management\_private\_ip\_addresses](#output\_api\_management\_private\_ip\_addresses) | API Management private IP addresses |
| <a name="output_api_management_public_ip_addresses"></a> [api\_management\_public\_ip\_addresses](#output\_api\_management\_public\_ip\_addresses) | API Management public IP addresses |
| <a name="output_api_management_scm_url"></a> [api\_management\_scm\_url](#output\_api\_management\_scm\_url) | API Management SCM URL |
| <a name="output_environment"></a> [environment](#output\_environment) | Environment name |
| <a name="output_location"></a> [location](#output\_location) | Azure region |
| <a name="output_named_value_ids"></a> [named\_value\_ids](#output\_named\_value\_ids) | API Management named value (property) IDs |
| <a name="output_product_ids"></a> [product\_ids](#output\_product\_ids) | API Management product IDs |
| <a name="output_publisher_email"></a> [publisher\_email](#output\_publisher\_email) | Publisher email |
| <a name="output_publisher_name"></a> [publisher\_name](#output\_publisher\_name) | Publisher name |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name |
| <a name="output_sku_name"></a> [sku\_name](#output\_sku\_name) | SKU name |
| <a name="output_tags"></a> [tags](#output\_tags) | Resource tags |
<!-- END_TF_DOCS -->

---

## Part of the AIRCLOUD Azure module catalog

Browse all modules with usage snippets in the [module catalog](https://aircloud-pl.github.io/) or on [github.com/AIRCLOUD-PL](https://github.com/AIRCLOUD-PL). Built and maintained by [AIRCLOUD](https://aircloud.com.pl): DevOps, cloud and AI engineering. Need a hand with Azure landing zones or platform engineering? See [aircloud.com.pl/consulting](https://aircloud.com.pl/consulting).
