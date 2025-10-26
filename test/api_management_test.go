package test

import (
	"testing"
	"fmt"
	"strings"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestApiManagementModule(t *testing.T) {
	t.Parallel()

	// Generate unique names for resources
	uniqueId := random.UniqueId()
	resourceGroupName := fmt.Sprintf("rg-apim-test-%s", uniqueId)
	apiManagementName := fmt.Sprintf("apim-test-%s", uniqueId)
	location := "East US"

	// Configure Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"resource_group_name": resourceGroupName,
			"location":           location,
			"environment":       "test",
			"api_management_name": apiManagementName,
			"publisher_name":    "Test Publisher",
			"publisher_email":   "test@example.com",
			"sku_name":          "Developer_1",
			"tags": map[string]string{
				"Environment": "test",
				"Module":      "api-management",
			},
		},
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy resources
	terraform.InitAndApply(t, terraformOptions)

	// Validate API Management
	validateApiManagement(t, terraformOptions, apiManagementName, resourceGroupName)

	// Validate outputs
	validateOutputs(t, terraformOptions)
}

func TestApiManagementWithProductsAndApis(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()
	resourceGroupName := fmt.Sprintf("rg-apim-full-test-%s", uniqueId)
	apiManagementName := fmt.Sprintf("apim-full-test-%s", uniqueId)
	location := "East US"

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"resource_group_name": resourceGroupName,
			"location":           location,
			"environment":       "test",
			"api_management_name": apiManagementName,
			"publisher_name":    "Test Publisher",
			"publisher_email":   "test@example.com",
			"sku_name":          "Developer_1",
			"products": map[string]interface{}{
				"starter": map[string]interface{}{
					"display_name":          "Starter Product",
					"description":           "Basic API product for testing",
					"approval_required":     false,
					"published":             true,
					"subscription_required": true,
					"subscriptions_limit":   10,
				},
			},
			"apis": map[string]interface{}{
				"petstore": map[string]interface{}{
					"name":         "petstore-api",
					"display_name": "Petstore API",
					"description":  "Sample Petstore API",
					"path":         "petstore",
					"protocols":    []string{"https"},
					"service_url":  "https://petstore.swagger.io/v2",
					"operations": map[string]interface{}{
						"get-pets": map[string]interface{}{
							"display_name": "Get Pets",
							"method":       "GET",
							"url_template": "/pets",
							"description":  "Retrieve all pets",
						},
					},
				},
			},
			"named_values": map[string]interface{}{
				"api-key": map[string]interface{}{
					"display_name": "API Key",
					"value":        "test-api-key-123",
					"secret":       true,
				},
			},
			"tags": map[string]string{
				"Environment": "test",
				"Module":      "api-management-full",
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	validateApiManagementWithProducts(t, terraformOptions, apiManagementName, resourceGroupName)
	validateApiManagementWithApis(t, terraformOptions, apiManagementName, resourceGroupName)
}

func TestApiManagementWithVNet(t *testing.T) {
	t.Parallel()

	uniqueId := random.UniqueId()
	resourceGroupName := fmt.Sprintf("rg-apim-vnet-test-%s", uniqueId)
	apiManagementName := fmt.Sprintf("apim-vnet-test-%s", uniqueId)
	location := "East US"

	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"resource_group_name": resourceGroupName,
			"location":           location,
			"environment":       "test",
			"api_management_name": apiManagementName,
			"publisher_name":    "Test Publisher",
			"publisher_email":   "test@example.com",
			"sku_name":          "Premium_1",
			"virtual_network_type": "External",
			"tags": map[string]string{
				"Environment": "test",
				"Module":      "api-management-vnet",
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	validateApiManagementVNet(t, terraformOptions, apiManagementName, resourceGroupName)
}

func validateApiManagement(t *testing.T, terraformOptions *terraform.Options, apiManagementName, resourceGroupName string) {
	// Get API Management details
	apiManagement := azure.GetApiManagement(t, apiManagementName, resourceGroupName, "")

	// Validate basic properties
	assert.Equal(t, apiManagementName, apiManagement.Name)
	assert.Equal(t, "Developer_1", apiManagement.SKU.Name)
	assert.Equal(t, "Test Publisher", apiManagement.PublisherName)
	assert.Equal(t, "test@example.com", apiManagement.PublisherEmail)
	assert.NotEmpty(t, apiManagement.GatewayURL)
	assert.NotEmpty(t, apiManagement.PortalURL)
}

func validateApiManagementWithProducts(t *testing.T, terraformOptions *terraform.Options, apiManagementName, resourceGroupName string) {
	// Validate products exist
	products := terraform.Output(t, terraformOptions, "product_ids")
	assert.NotEmpty(t, products)
	assert.Contains(t, products, "starter")
}

func validateApiManagementWithApis(t *testing.T, terraformOptions *terraform.Options, apiManagementName, resourceGroupName string) {
	// Validate APIs exist
	apis := terraform.Output(t, terraformOptions, "api_ids")
	assert.NotEmpty(t, apis)
	assert.Contains(t, apis, "petstore")
}

func validateApiManagementVNet(t *testing.T, terraformOptions *terraform.Options, apiManagementName, resourceGroupName string) {
	apiManagement := azure.GetApiManagement(t, apiManagementName, resourceGroupName, "")

	// Validate VNet integration
	assert.Equal(t, "External", apiManagement.VirtualNetworkType)
	assert.NotEmpty(t, apiManagement.PrivateIPAddresses)
}

func validateOutputs(t *testing.T, terraformOptions *terraform.Options) {
	// Validate required outputs
	apiManagementId := terraform.Output(t, terraformOptions, "api_management_id")
	assert.NotEmpty(t, apiManagementId)
	assert.Contains(t, apiManagementId, "Microsoft.ApiManagement/service")

	apiManagementName := terraform.Output(t, terraformOptions, "api_management_name")
	assert.NotEmpty(t, apiManagementName)

	gatewayUrl := terraform.Output(t, terraformOptions, "api_management_gateway_url")
	assert.NotEmpty(t, gatewayUrl)
	assert.Contains(t, gatewayUrl, "https://")

	portalUrl := terraform.Output(t, terraformOptions, "api_management_portal_url")
	assert.NotEmpty(t, portalUrl)
	assert.Contains(t, portalUrl, "https://")

	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	assert.NotEmpty(t, resourceGroupName)

	location := terraform.Output(t, terraformOptions, "location")
	assert.NotEmpty(t, location)

	publisherName := terraform.Output(t, terraformOptions, "publisher_name")
	assert.Equal(t, "Test Publisher", publisherName)
}