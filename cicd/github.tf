# GitHub Data Sources
# This file contains data sources and resources for GitHub integration

data "github_repository" "this" {
  full_name = local.repo_id
}

data "github_app" "azure_pipelines" {
  slug = "azure-pipelines"
}

resource "github_repository_ruleset" "this" {
  name        = "main"
  repository  = data.github_repository.this.name
  enforcement = "active"
  target      = "branch"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true

    required_status_checks {
      dynamic "required_check" {
        for_each = local.all_pipeline_names
        content {
          context        = required_check.value
          integration_id = data.github_app.azure_pipelines.id
        }
      }
    }

    pull_request {
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      require_last_push_approval        = true
      required_review_thread_resolution = true
      allowed_merge_methods             = ["squash", "rebase"]
    }

    copilot_code_review {
      review_on_push             = false
      review_draft_pull_requests = true
    }
  }
}

resource "github_repository_ruleset" "prevent_tag_deletion" {
  name        = "prevent-tag-deletion"
  repository  = data.github_repository.this.name
  enforcement = "active"
  target      = "tag"

  conditions {
    ref_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
    update           = true

    tag_name_pattern {
      operator = "regex"
      pattern  = "^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"
      negate   = false
    }
  }
}
