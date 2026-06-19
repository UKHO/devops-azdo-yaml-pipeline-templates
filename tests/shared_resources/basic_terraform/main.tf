terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "VariableToOutput1" {
  type    = string
  default = ""
}

variable "VariableToOutput2" {
  type    = string
  default = ""
}

variable "Environment" {
  type    = string
  default = "dev"
}

variable "MaxRandom" {
  type    = number
  default = 100
}

variable "MinRandom" {
  type    = number
  default = 1
}

provider "random" {}

resource "random_integer" "example" {
  min = var.MinRandom
  max = var.MaxRandom
}

output "random_number" {
  value = random_integer.example.result
}

output "random_string" {
  value = var.Environment
}

output "OutputVariable1" {
  value = var.VariableToOutput1
}

output "OutputVariable2" {
  value = var.VariableToOutput2
}
