terraform {
  required_providers {
    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.12.0"
    }
  }
}

provider "elasticstack" {
  elasticsearch {}
  kibana {}
}

resource "elasticstack_kibana_slo" "custom_kql" {
  name        = "custom kql devops chapter"
  description = "custom kql devops chapter"

  kql_custom_indicator {
    index           = "metrics-apm*,synthetics*"
    good            = "summary.up:1"
    total           = "summary.up:*"
    filter          = "monitor.name:\"File Share Service - Website - Testing - DownloadFile\""
  }

  time_window {
    duration = "30d"
    type     = "rolling"
  }

  budgeting_method = "occurrences"

  objective {
    target           = 0.95
    timeslice_target = 0.95
    timeslice_window = "5m"
  }

  settings {
    sync_delay = "5m"
    frequency  = "5m"
  }
}
