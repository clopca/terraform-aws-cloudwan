variable "resource_share" {
  nullable    = false
  description = "Core Network RAM share create-or-reference boundary."

  type = object({
    create                    = optional(bool, true)
    arn                       = optional(string)
    name                      = optional(string)
    allow_external_principals = optional(bool, false)
    tags                      = optional(map(string), {})
  })

  validation {
    condition = var.resource_share.create ? (
      var.resource_share.arn == null &&
      var.resource_share.name != null &&
      length(trimspace(var.resource_share.name)) > 0
      ) : (
      var.resource_share.arn != null &&
      can(regex("^arn:[a-z0-9-]+:ram:[a-z0-9-]+:[0-9]{12}:resource-share/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.resource_share.arn)) &&
      var.resource_share.name == null &&
      var.resource_share.allow_external_principals == false &&
      length(var.resource_share.tags) == 0
    )
    error_message = "Create mode requires name and arn=null; reference mode requires a full RAM resource-share ARN and no create-only fields."
  }
}

variable "resources" {
  nullable    = false
  description = "Core Network ARNs keyed by immutable caller-owned identity."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, arn in var.resources :
      can(regex("^[a-z0-9][a-z0-9_-]*$", key)) &&
      can(regex("^arn:[a-z0-9-]+:networkmanager::[0-9]{12}:core-network/core-network-[0-9a-f]{8,17}$", arn))
    ])
    error_message = "resources requires stable lowercase keys and full partition-aware Core Network ARNs."
  }
}

variable "principals" {
  nullable    = false
  description = "Account, Organization, or OU principals keyed by immutable caller-owned identity."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, principal in var.principals :
      can(regex("^[a-z0-9][a-z0-9_-]*$", key)) &&
      (
        (can(regex("^[0-9]{12}$", principal)) && principal != "000000000000") ||
        (
          !can(regex("^arn:[a-z0-9-]+:organizations::000000000000:", principal)) &&
          (
            can(regex("^arn:[a-z0-9-]+:organizations::[0-9]{12}:organization/o-[a-z0-9]{10,32}$", principal)) ||
            can(regex("^arn:[a-z0-9-]+:organizations::[0-9]{12}:ou/o-[a-z0-9]{10,32}/ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}$", principal))
          )
        )
      )
    ])
    error_message = "principals requires stable lowercase keys and a nonzero 12-digit account ID in every supported principal form."
  }
}
