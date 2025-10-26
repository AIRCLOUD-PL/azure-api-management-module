variable "api_management_name" {
  description = "Name of the API Management service. If null, will be auto-generated."
  type        = string
  default     = null
}

variable "naming_prefix" {
  description = "Prefix for API Management naming"
  type        = string
  default     = "apim"
}

variable "environment" {
  description = "Environment name (e.g., prod, dev, test)"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "publisher_name" {
  description = "Publisher name for the API Management service"
  type        = string
}

variable "publisher_email" {
  description = "Publisher email for the API Management service"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the API Management service"
  type        = string
  default     = "Developer_1"
  validation {
    condition = contains([
      "Consumption_0", "Developer_1", "Basic_1", "Basic_2", "Standard_1", "Standard_2",
      "Standard_4", "Premium_1", "Premium_2", "Premium_4", "Premium_8", "Premium_16",
      "Isolated_1", "Isolated_2", "Isolated_4", "Isolated_8", "Isolated_16"
    ], var.sku_name)
    error_message = "SKU name must be a valid API Management SKU."
  }
}

variable "capacity" {
  description = "Capacity of the API Management service"
  type        = number
  default     = 1
}

variable "enable_http2" {
  description = "Enable HTTP/2 protocol"
  type        = bool
  default     = true
}

variable "enable_backend_tls11" {
  description = "Enable TLS 1.1 for backend"
  type        = bool
  default     = false
}

variable "enable_backend_tls12" {
  description = "Enable TLS 1.2 for backend"
  type        = bool
  default     = true
}

variable "enable_frontend_tls10" {
  description = "Enable TLS 1.0 for frontend"
  type        = bool
  default     = false
}

variable "enable_frontend_tls11" {
  description = "Enable TLS 1.1 for frontend"
  type        = bool
  default     = false
}

variable "enable_frontend_tls12" {
  description = "Enable TLS 1.2 for frontend"
  type        = bool
  default     = true
}

variable "min_api_version" {
  description = "Minimum API version supported"
  type        = string
  default     = "2019-12-01"
}

variable "virtual_network_type" {
  description = "Virtual network type for API Management"
  type        = string
  default     = "None"
  validation {
    condition     = contains(["None", "External", "Internal"], var.virtual_network_type)
    error_message = "Virtual network type must be None, External, or Internal."
  }
}

variable "virtual_network_configuration" {
  description = "Virtual network configuration"
  type = object({
    subnet_id = string
  })
  default = null
}

variable "additional_location" {
  description = "Additional location configurations for multi-region deployment"
  type = list(object({
    location = string
    capacity = optional(number, 1)
    zones    = optional(list(string))
  }))
  default = []
}

variable "zones" {
  description = "Availability zones for the API Management service"
  type        = list(string)
  default     = []
}

variable "hostname_configurations" {
  description = "Custom hostname configurations"
  type = list(object({
    type                         = string
    host_name                    = string
    key_vault_id                 = optional(string)
    certificate                  = optional(string)
    certificate_password         = optional(string)
    negotiate_client_certificate = optional(bool, false)
    default_ssl_binding          = optional(bool, false)
  }))
  default = []
}

variable "identity" {
  description = "Managed identity configuration"
  type = object({
    type         = string
    identity_ids = optional(list(string), [])
  })
  default = null
}

variable "sign_in" {
  description = "Sign-in settings"
  type = object({
    enabled = bool
  })
  default = {
    enabled = true
  }
}

variable "sign_up" {
  description = "Sign-up settings"
  type = object({
    enabled = bool
    terms_of_service = optional(object({
      enabled          = bool
      consent_required = bool
      text             = string
    }))
  })
  default = {
    enabled = false
  }
}

variable "delegation" {
  description = "Delegation settings"
  type = object({
    enabled        = bool
    validation_key = optional(string)
    url            = optional(string)
  })
  default = {
    enabled = false
  }
}

variable "policy" {
  description = "Global policy configuration"
  type = object({
    xml_content = string
    xml_link    = optional(string)
  })
  default = null
}

variable "products" {
  description = "API products configuration"
  type = map(object({
    display_name          = string
    description           = optional(string)
    approval_required     = optional(bool, false)
    published             = optional(bool, true)
    subscription_required = optional(bool, true)
    subscriptions_limit   = optional(number)
    terms                 = optional(string)
    state                 = optional(string, "published")
    subscriptions         = optional(list(string), [])
    policy = optional(object({
      xml_content = string
      xml_link    = optional(string)
    }))
  }))
  default = {}
}

variable "apis" {
  description = "API configurations"
  type = map(object({
    name         = string
    display_name = string
    description  = optional(string)
    path         = string
    protocols    = optional(list(string), ["https"])
    revision     = optional(string, "1")
    service_url  = optional(string)
    subscription_key_parameter_names = optional(object({
      header = string
      query  = string
      }), {
      header = "Ocp-Apim-Subscription-Key"
      query  = "subscription-key"
    })
    import = optional(object({
      content_format = string
      content_value  = string
      wsdl_selector = optional(object({
        service_name  = string
        endpoint_name = string
      }))
    }))
    policy = optional(object({
      xml_content = string
      xml_link    = optional(string)
    }))
    operations = optional(map(object({
      display_name = string
      method       = string
      url_template = string
      description  = optional(string)
      policy = optional(object({
        xml_content = string
        xml_link    = optional(string)
      }))
    })), {})
  }))
  default = {}
}

variable "named_values" {
  description = "Named values (properties) configuration"
  type = map(object({
    display_name = string
    value        = string
    secret       = optional(bool, false)
    tags         = optional(list(string), [])
  }))
  default = {}
}

variable "certificates" {
  description = "Certificate configurations"
  type = map(object({
    certificate = string
    password    = optional(string)
  }))
  default = {}
}

variable "diagnostic_settings" {
  description = "Diagnostic settings configurations"
  type = map(object({
    name                       = string
    log_analytics_workspace_id = string
    logs = list(object({
      category = string
    }))
    metrics = list(object({
      category = string
      enabled  = bool
    }))
  }))
  default = {}
}

variable "enable_policy_assignments" {
  description = "Enable Azure Policy assignments for API Management security"
  type        = bool
  default     = false
}

variable "enable_custom_policies" {
  description = "Enable custom Azure Policy definitions"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}