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

variable "GitHub_ServiceConnection_Guid" {
  type        = string
  description = "Guid of the service connection that has permissions to the github repository for the pipeline yaml"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.GitHub_ServiceConnection_Guid))
    error_message = "The value must be a valid GUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)."
  }
}
