# Name: providers.tf
# Owner: Saurav Mitra
# Description: This terraform config will Configure Terraform Providers
# https://www.terraform.io/docs/language/providers/requirements.html

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.11.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}

# Configure Terraform AZURE Provider
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

# $ export ARM_SUBSCRIPTION_ID="SubscriptionId"
# $ export ARM_TENANT_ID="TenantId"
# $ export ARM_CLIENT_ID="ClientId"
# $ export ARM_CLIENT_SECRET="ClientSecret"

provider "azurerm" {
  # Configuration options
  features {}
}