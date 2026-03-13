terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 1.12.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8.1"
    }
  }

  backend "local" {
    path = "state/terraform_azdo.tfstate"
  }
}

# https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs#argument-reference
provider "azuredevops" {
  org_service_url = var.org_service_url # Required for finding the azure devops server, combined with entra id login
}

provider "random" {
}
