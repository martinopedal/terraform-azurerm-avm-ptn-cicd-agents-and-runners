variable "version_control_system_organization" {
  type        = string
  description = "The version control system organization to deploy the agents too."
}

variable "version_control_system_type" {
  type        = string
  description = "The type of the version control system to deploy the agents too. Allowed values are 'azuredevops' or 'github'"
  nullable    = false

  validation {
    condition     = contains(local.valid_version_control_systems, var.version_control_system_type)
    error_message = "cicd_system must be one of 'azuredevops' or 'github'"
  }
}

variable "version_control_system_agent_name_prefix" {
  type        = string
  default     = null
  description = "The version control system agent name prefix."
}

variable "version_control_system_agent_target_queue_length" {
  type        = number
  default     = 1
  description = "The target value for the amound of pending jobs to scale on."
}

variable "version_control_system_authentication_method" {
  type        = string
  default     = null
  description = "Authentication method. For Azure DevOps: 'pat' or 'uami' (requires Azure DevOps prerequisites - see README). For GitHub: 'pat' or 'github_app'. If null (the default), Azure DevOps falls back to 'uami' and GitHub falls back to 'github_app'."

  validation {
    condition = (
      var.version_control_system_authentication_method == null ? true :
      var.version_control_system_type == "azuredevops" ? contains(["pat", "uami"], var.version_control_system_authentication_method) :
      contains(["pat", "github_app"], var.version_control_system_authentication_method)
    )
    error_message = "For Azure DevOps, authentication_method must be 'pat' or 'uami'. For GitHub, authentication_method must be 'pat' or 'github_app'. Leave null to use the default for the chosen version_control_system_type."
  }
}

variable "version_control_system_enterprise" {
  type        = string
  default     = null
  description = "The enterprise name for the version control system."
}

variable "version_control_system_github_application_id" {
  type        = string
  default     = ""
  description = "The application ID for the GitHub App authentication method."

  validation {
    condition = (
      coalesce(var.version_control_system_authentication_method, var.version_control_system_type == "azuredevops" ? "uami" : "github_app") == "github_app" ? length(var.version_control_system_github_application_id) > 0 : true
    )
    error_message = "Variable version_control_system_github_application_id must be defined when version_control_system_authentication_method is github_app."
  }
}

variable "version_control_system_github_application_installation_id" {
  type        = string
  default     = ""
  description = "The installation ID for the GitHub App authentication method."

  validation {
    condition = (
      coalesce(var.version_control_system_authentication_method, var.version_control_system_type == "azuredevops" ? "uami" : "github_app") == "github_app" ? length(var.version_control_system_github_application_installation_id) > 0 : true
    )
    error_message = "Variable version_control_system_github_application_installation_id must be defined when version_control_system_authentication_method is github_app."
  }
}

variable "version_control_system_github_application_key" {
  type        = string
  default     = null
  description = "The application key for the GitHub App authentication method."
  sensitive   = true

  validation {
    condition = (
      coalesce(var.version_control_system_authentication_method, var.version_control_system_type == "azuredevops" ? "uami" : "github_app") == "github_app" ? var.version_control_system_github_application_key != "" && var.version_control_system_github_application_key != null : true
    )
    error_message = "Variable version_control_system_github_application_key must be defined when version_control_system_authentication_method is github_app."
  }
}

variable "version_control_system_personal_access_token" {
  type        = string
  default     = null
  description = "The personal access token for the version control system. Required when authentication_method is 'pat'."
  sensitive   = true

  validation {
    condition = (
      coalesce(var.version_control_system_authentication_method, var.version_control_system_type == "azuredevops" ? "uami" : "github_app") == "pat" ? var.version_control_system_personal_access_token != "" && var.version_control_system_personal_access_token != null : true
    )
    error_message = "Variable version_control_system_personal_access_token must be defined when version_control_system_authentication_method is pat."
  }
}

variable "version_control_system_placeholder_agent_name" {
  type        = string
  default     = null
  description = "The version control system placeholder agent name."
}

variable "version_control_system_pool_name" {
  type        = string
  default     = null
  description = "The name of the agent pool in the version control system."
}

variable "version_control_system_repository" {
  type        = string
  default     = null
  description = "The version control system repository to deploy the agents too."
}

variable "version_control_system_runner_group" {
  type        = string
  default     = null
  description = "The runner group to add the runner to."
}

variable "version_control_system_runner_scope" {
  type        = string
  default     = "repo"
  description = "The scope of the runner. Must be `ent`, `org`, or `repo`. This is ignored for Azure DevOps."
}

variable "version_control_system_keda_labels" {
  type        = string
  default     = ""
  description = <<-EOT
  Optional KEDA `labels` metadata for the github-runner scaler. When set, KEDA
  only counts queued/in-progress jobs whose `runs-on` labels can be satisfied
  by this comma-separated label list (subject to `version_control_system_keda_no_default_labels`).
  Leave empty to keep upstream behaviour (KEDA only matches reserved labels
  `self-hosted,linux,x64` → blind to any custom label like `alz-p1`).
  Ignored for Azure DevOps.
EOT
}

variable "version_control_system_keda_no_default_labels" {
  type        = bool
  default     = false
  description = <<-EOT
  When true, KEDA's `noDefaultLabels` is set so the scaler does NOT auto-append
  `self-hosted,linux,x64` to `labels`. Use this with an explicit `labels` that
  already includes the reserved labels you want to honour. Ignored for Azure DevOps.
EOT
}

variable "version_control_system_keda_enable_etags" {
  type        = bool
  default     = false
  description = <<-EOT
  When true, KEDA's github-runner `enableEtags` is set so the scaler uses
  HTTP ETag conditional requests, reducing API consumption when nothing has
  changed since the previous poll. Available on KEDA >= 2.17. Ignored for Azure DevOps.
EOT
}
