variable "AzDO_Project_Name" {
  type = string
  description = "Name of the azdo project in azdo where the library variable groups and pipeline will be deployed"
}

variable "GitHub_ServiceConnection_Guid" {
  type = string
  description = "Guid of the service connection that has permissions to the github repository for the pipeline yaml"
}
