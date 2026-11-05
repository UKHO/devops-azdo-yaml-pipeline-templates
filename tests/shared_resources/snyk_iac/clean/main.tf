// Fixture for the SnykIac check: a single resource group, which no Snyk IaC rule flags, so the scan passes.
// Nothing here is ever applied; the build only runs init, validate and the checks.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "fixture" {
  name     = "rg-snyk-iac-clean-fixture"
  location = "uksouth"
}
