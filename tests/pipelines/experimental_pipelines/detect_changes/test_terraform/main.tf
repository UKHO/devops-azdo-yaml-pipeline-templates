data "azuredevops_project" "this" {
  name = var.AzDO_Project_Name
}

resource "azuredevops_environment" "this" {
  name        = "experimental-environment"
  project_id  = data.azuredevops_project.this.project_id
  description = var.Environment_Description
}

# https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs#argument-reference
provider "azuredevops" {
  org_service_url = "https://dev.azure.com/ukhydro" # Required for finding the azure devops server, combined with entra id login
}

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

variable "AzDO_Project_Name" {
  type        = string
  description = "Name of the Azure DevOps project in Azure DevOps where the library variable groups and pipeline will be deployed"
  validation {
    condition = (
      length(var.AzDO_Project_Name) > 0 &&
      length(var.AzDO_Project_Name) <= 64 &&
      can(regex("^[A-Za-z0-9 _.-]+$", var.AzDO_Project_Name)) &&
      !startswith(var.AzDO_Project_Name, ".") &&
      !endswith(var.AzDO_Project_Name, ".")
    )
    error_message = "Project name must be 1-64 characters, use only letters, numbers, spaces, hyphens (-), underscores (_), periods (.), and cannot start or end with a period."
  }
}

variable "Environment_Description" {
  type    = string
  default = "Default description"
}

