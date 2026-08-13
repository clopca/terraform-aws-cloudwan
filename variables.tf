variable "global_network" {
  nullable    = false
  description = "Global Network create-or-reference boundary. create must be plan-known."

  type = object({
    create      = optional(bool, true)
    id          = optional(string)
    description = optional(string)
    tags        = optional(map(string), {})
  })

  validation {
    condition = var.global_network.create ? (
      var.global_network.id == null
      ) : (
      var.global_network.id != null &&
      can(regex("^global-network-[0-9a-f]{8,17}$", var.global_network.id)) &&
      var.global_network.description == null &&
      length(var.global_network.tags) == 0
    )
    error_message = "Create mode requires id=null; reference mode requires a valid global-network ID and no create-only description/tags."
  }
}

variable "core_network" {
  nullable    = false
  description = "Core Network create-or-reference boundary. base_policy is CREATE-ONLY."

  type = object({
    create      = optional(bool, true)
    id          = optional(string)
    description = optional(string)
    base_policy = optional(object({
      policy_document = optional(string)
      regions         = optional(set(string))
      approved_sha256 = optional(string)
    }))
    tags = optional(map(string), {})
  })

  validation {
    condition = var.core_network.create ? (
      var.core_network.id == null
      ) : (
      var.core_network.id != null &&
      can(regex("^core-network-[0-9a-f]{8,17}$", var.core_network.id)) &&
      var.core_network.description == null &&
      var.core_network.base_policy == null &&
      length(var.core_network.tags) == 0
    )
    error_message = "Create mode requires id=null; reference mode requires a valid core-network ID and no create-only fields."
  }

  validation {
    condition = var.core_network.base_policy == null ? true : (
      (var.core_network.base_policy.policy_document != null ? 1 : 0) +
      (var.core_network.base_policy.regions != null ? 1 : 0) == 1
    )
    error_message = "base_policy must set exactly one of policy_document or regions."
  }

  validation {
    condition = var.core_network.base_policy == null || var.core_network.base_policy.policy_document == null ? true : (
      can(jsondecode(var.core_network.base_policy.policy_document))
    )
    error_message = "base_policy.policy_document must be valid JSON."
  }

  validation {
    condition = var.core_network.base_policy == null || var.core_network.base_policy.regions == null ? true : (
      length(var.core_network.base_policy.regions) > 0 &&
      alltrue([
        for region in var.core_network.base_policy.regions :
        trimspace(region) == region &&
        can(regex("^[a-z]{2}(-gov)?-[a-z0-9-]+-[0-9]+$", region))
      ])
    )
    error_message = "base_policy.regions must contain non-empty, lexically valid AWS Region names without surrounding whitespace."
  }

  validation {
    condition = var.core_network.base_policy == null || var.core_network.base_policy.approved_sha256 == null ? true : (
      var.core_network.base_policy.policy_document != null &&
      can(regex("^[0-9a-fA-F]{64}$", trimspace(var.core_network.base_policy.approved_sha256)))
    )
    error_message = "base_policy.approved_sha256 requires policy_document and must contain exactly 64 hexadecimal characters."
  }
}

variable "tags" {
  nullable    = false
  description = "Tags applied below resource-specific tags."
  type        = map(string)
  default     = {}
}
