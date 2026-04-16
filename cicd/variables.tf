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

variable "azurerm_serviceconnection_name" {
  type        = string
  description = "Name of the service connection that has permissions to the azure subscription which pipelines use to deploy resources via"
  validation {
    condition = (
      length(var.azurerm_serviceconnection_name) > 0 &&
      length(var.azurerm_serviceconnection_name) <= 128 &&
      can(regex("^[^'\"/\\\\\\[\\]:|<>+=;?*]+$", var.azurerm_serviceconnection_name))
    )
    error_message = "Service connection name must be 1-128 characters and cannot contain: ' \" / \\ [ ] : | < > + = ; ? *"
  }
}

variable "azdo_agent_pool_name" {
  type        = string
  description = "Name of the Azure DevOps agent pool to use for pipeline execution"
  validation {
    condition = (
      length(var.azdo_agent_pool_name) > 0 &&
      length(var.azdo_agent_pool_name) <= 128 &&
      can(regex("^[^'\"/\\\\\\[\\]:|<>+=;?*]+$", var.azdo_agent_pool_name))
    )
    error_message = "Agent pool name must be 1-128 characters and cannot contain: ' \" / \\ [ ] : | < > + = ; ? *"
  }
}

variable "azdo_environment_name" {
  type        = string
  description = "Name of the Azure DevOps environment for pipeline deployments"
  validation {
    condition = (
      length(var.azdo_environment_name) > 0 &&
      length(var.azdo_environment_name) <= 128 &&
      can(regex("^[^'\"/\\\\\\[\\]:|<>+=;?*]+$", var.azdo_environment_name))
    )
    error_message = "Environment name must be 1-128 characters and cannot contain: ' \" / \\ [ ] : | < > + = ; ? *"
  }
}

variable "devops_chapter_azure_subscription_id" {
  type        = string
  description = "GUID of the Azure subscription for the DevOps chapter"
  validation {
    condition = (
      can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", lower(var.devops_chapter_azure_subscription_id)))
    )
    error_message = "Subscription GUID must be a valid UUID format (e.g., 550e8400-e29b-41d4-a716-446655440000)"
  }
}
