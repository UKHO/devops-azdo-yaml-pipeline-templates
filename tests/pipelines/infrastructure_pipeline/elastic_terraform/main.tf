terraform {
  required_providers {
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.12.0"
    }
  }

  backend "azurerm" {}
}

provider "elasticstack" {
  elasticsearch {
    endpoints = [
      "https://ukho-nonlive-elastic.es.uksouth.azure.elastic-cloud.com"
    ]
  }
  kibana {
    endpoints = [
      "https://ukho-nonlive-elastic.kb.uksouth.azure.elastic-cloud.com:9243"
    ]
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
