
variable "github_organisation_name" {
  type        = string
  description = "Name of the GitHub organization where the repository is hosted"
  validation {
    condition = (
      length(var.github_organisation_name) > 0 &&
      length(var.github_organisation_name) <= 39 &&
      can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$", var.github_organisation_name))
    )
    error_message = "GitHub organization name must be 1-39 characters, start and end with alphanumeric, and can contain hyphens"
  }
}
variable "azdo_project_name" {
  type        = string
  description = "Name of the Azure DevOps project in Azure DevOps where the azdo components will be deployed"
  validation {
    condition = (
      length(var.azdo_project_name) > 0 &&
      length(var.azdo_project_name) <= 128 &&
      !startswith(var.azdo_project_name, "_") &&
      !startswith(var.azdo_project_name, ".") &&
      !endswith(var.azdo_project_name, ".") &&
      can(regex("^[^'\"/\\\\\\[\\]:|<>+=;?*]+$", var.azdo_project_name))
    )
    error_message = "Project name must be 1-128 characters, cannot start with underscore (_), cannot start or end with period (.), and cannot contain: ' \" / \\ [ ] : | < > + = ; ? *"
  }
}

variable "github_serviceconnection_name" {
  type        = string
  description = "Name of the service connection that has permissions to the GitHub repository for the pipeline YAML"
  validation {
    condition = (
      length(var.github_serviceconnection_name) > 0 &&
      length(var.github_serviceconnection_name) <= 128 &&
      can(regex("^[^'\"/\\\\\\[\\]:|<>+=;?*]+$", var.github_serviceconnection_name))
    )
    error_message = "Service connection name must be 1-128 characters and cannot contain: ' \" / \\ [ ] : | < > + = ; ? *"
  }
}

variable "org_service_url" {
  type        = string
  description = "The Azure DevOps organization service URL (e.g., https://dev.azure.com/organization_name)"
  validation {
    condition = (
      length(var.org_service_url) > 0 &&
      can(regex("^https://dev\\.azure\\.com/[a-zA-Z0-9_-]+/?$", var.org_service_url))
    )
    error_message = "Organization service URL must be a valid Azure DevOps URL in format: https://dev.azure.com/organization_name"
  }
}

variable "target_branch" {
  type        = string
  description = "Target git branch for the pipeline (e.g., main, develop, feature/branch-name)"
  validation {
    condition = (
      length(var.target_branch) > 0 &&
      length(var.target_branch) <= 255 &&
      can(regex("^[a-zA-Z0-9._/-]+$", var.target_branch))
    )
    error_message = "Target branch must be 1-255 characters and can only contain alphanumeric characters, dots, underscores, forward slashes, and hyphens"
  }
}
