variable "global_network" {
  nullable    = false
  description = "Global Network create-or-reference boundary passed to the fabric module."
  type = object({
    create      = optional(bool, true)
    id          = optional(string)
    description = optional(string)
    tags        = optional(map(string), {})
  })
}

variable "core_network" {
  nullable    = false
  description = "Core Network create-or-reference boundary passed to the fabric module."
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
}

variable "policy_document" {
  nullable    = false
  description = "Service-native Cloud WAN policy document deployed after fabric creation or lookup."
  type        = string
}

variable "approval" {
  nullable    = true
  description = "Optional independent policy digest evidence passed to the policy module."
  type = object({
    sha256      = string
    digest_kind = string
  })
  default = null
}

variable "policy_timeouts" {
  nullable    = false
  description = "Policy provider update timeout. Default 30m; 60m is recommended for global rollouts."
  type = object({
    update = optional(string, "30m")
  })
  default = {}
}

variable "sharing" {
  nullable    = true
  description = "Optional Core Network RAM sharing. null disables all sharing resources."
  type = object({
    resource_share = object({
      create                    = optional(bool, true)
      arn                       = optional(string)
      name                      = optional(string)
      allow_external_principals = optional(bool, false)
      tags                      = optional(map(string), {})
    })
    principals = optional(map(string), {})
  })
  default = null
}

variable "tags" {
  nullable    = false
  description = "Tags passed to the fabric module below resource-specific tags."
  type        = map(string)
  default     = {}
}
