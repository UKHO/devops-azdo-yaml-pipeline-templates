terraform {
  required_providers {
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.14.3"
    }
  }

  backend "azurerm" {}
}

provider "elasticstack" {
  elasticsearch {
    api_key = var.api_key
    endpoints = [var.elastic_endpoint]
  }
  kibana {
    api_key = var.api_key
    endpoints = [var.kibana_endpoint]
  }
}

resource "elasticstack_kibana_slo" "custom_kql" {
  name        = "test-slo-devopschapter"
  description = "SLO terraform test"

  kql_custom_indicator {
    index  = "logs-*"
    good   = "http.response.status_code >= 200 and http.response.status_code < 300"
    total  = "http.response.status_code >= 100"
    filter = ""
  }

  time_window {
    duration = "30d"
    type     = "rolling"
  }

  budgeting_method = "occurrences"

  objective {
    target           = 0.99
    timeslice_target = 0.99
    timeslice_window = "5m"
  }

  settings {
    sync_delay = "5m"
    frequency  = "5m"
  }

  tags = ["testing", "availability", "terraform"]
}
