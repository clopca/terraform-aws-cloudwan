variable "core_network_id" {
  nullable    = false
  description = "Core Network whose policy deployment this module requests."
  type        = string

  validation {
    condition     = can(regex("^core-network-[0-9a-f]{8,17}$", var.core_network_id))
    error_message = "core_network_id must match the AWS core-network ID pattern."
  }
}

variable "policy_document" {
  nullable    = false
  description = "Service-native Cloud WAN policy JSON."
  type        = string

  validation {
    condition     = can(jsondecode(var.policy_document))
    error_message = "policy_document must be valid JSON."
  }

  validation {
    condition = try(
      contains(["2021.12", "2025.11"], jsondecode(var.policy_document).version) &&
      length(jsondecode(var.policy_document)["core-network-configuration"]["edge-locations"]) > 0 &&
      alltrue([
        for edge in jsondecode(var.policy_document)["core-network-configuration"]["edge-locations"] :
        length(trimspace(edge.location)) > 0
      ]) &&
      can(jsondecode(var.policy_document).segments[0]) &&
      length(jsondecode(var.policy_document).segments) > 0 &&
      alltrue([
        for segment in jsondecode(var.policy_document).segments :
        length(trimspace(segment.name)) > 0
      ]),
      false
    )
    error_message = "policy_document requires a supported version, at least one named edge location, and a non-empty list of named segments."
  }
}

variable "approval" {
  nullable    = true
  description = "Optional independent digest evidence. Production policy-as-code may require it."

  type = object({
    sha256      = string
    digest_kind = string
  })
  default = null

  validation {
    condition = var.approval == null ? true : (
      can(regex("^[0-9a-fA-F]{64}$", trimspace(var.approval.sha256))) &&
      contains(["policy_document_bytes", "terraform_canonical_json"], var.approval.digest_kind)
    )
    error_message = "approval.sha256 must be 64 hexadecimal characters and digest_kind must be policy_document_bytes or terraform_canonical_json."
  }
}

variable "timeouts" {
  nullable    = false
  description = "Provider update timeout. Default 30m; 60m is recommended for large global rollouts."

  type = object({
    update = optional(string, "30m")
  })
  default = {}

  validation {
    condition = try(
      timecmp(
        timeadd("2000-01-01T00:00:00Z", var.timeouts.update),
        "2000-01-01T00:00:00Z"
      ) > 0,
      false
    )
    error_message = "timeouts.update must be a positive Terraform duration."
  }
}
