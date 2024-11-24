# Name: backends.tf
# Owner: Saurav Mitra
# Description: This terraform config will Configure Terraform Backend
# https://www.terraform.io/docs/language/settings/backends/index.html

terraform {
  backend "azurerm" {
    resource_group_name  = "tf-backend-rg"
    storage_account_name = "azureaksk8sdemotfbackend"
    container_name       = "tf-state"
    key                  = "terraform.tfstate"
  }
}