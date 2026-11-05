// Fixture for the SnykIac check: a storage account with deliberate security misconfigurations
// (public blob access, TLS 1.0, HTTP allowed, open network access), so the scan reports issues.
// Nothing here is ever applied; the build only runs init, validate and the checks. Do not copy this.

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
  name     = "rg-snyk-iac-insecure-fixture"
  location = "uksouth"
}

resource "azurerm_storage_account" "insecure" {
  name                            = "stsnykiacinsecure"
  resource_group_name             = azurerm_resource_group.fixture.name
  location                        = azurerm_resource_group.fixture.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_0"
  https_traffic_only_enabled      = false
  allow_nested_items_to_be_public = true
  public_network_access_enabled   = true
}
