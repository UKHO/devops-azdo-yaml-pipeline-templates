plugin "terraform" {
  enabled = true
  version = "0.14.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

plugin "azurerm" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "azurerm-security" {
  enabled = true
  version = "0.1.6"
  source  = "github.com/pregress/tflint-ruleset-azurerm-security"
}
