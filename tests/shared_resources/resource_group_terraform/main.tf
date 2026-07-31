terraform {
  required_version = ">= 1.5.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4"
    }
  }

  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0"
}

resource "azurerm_resource_group" "rg" {
  name     = module.naming.resource_group.name_unique
  location = "UK South"
}
