terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 1.11.0"
    }
  }

  backend "local" {
    path = "state/terraform.tfstate"
  }
}
