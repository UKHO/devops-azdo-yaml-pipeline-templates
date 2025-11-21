# Define the provider
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 5.0.0"
    }

    random = {
      source = "hashicorp/random"
      version = "3.7.2"
    }
  }

  backend "local" {
    path = "state/terraform.tfstate"
  }
}


provider "azurerm" {
  features {}
  subscription_id = "0eaeb992-8461-4308-ab7c-81d9f9b29356"
}

provider "random" {

}


resource "random_string" "random" {
  length  = 5
  special = false
}

locals {
  web_app_name = "adoptest${random_string.random.result}"
}

# Define variables
variable "Web_App_Description" {
  type        = string
  description = "The description of the web app."
  default     = "Default web app description"
}

data "azurerm_resource_group" "this" {
  name = "m-devopschapter-rg"
}

# Create an App Service Plan
resource "azurerm_service_plan" "this" {
  name                = "${local.web_app_name}-plan"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  os_type             = "Linux"
  sku_name            = "P1v2"
}

# Create the Web App
resource "azurerm_windows_web_app" "this" {
  name                = local.web_app_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
  service_plan_id     = azurerm_service_plan.this.id

  tags = {
    Description = var.Web_App_Description
  }

  site_config {}
}
