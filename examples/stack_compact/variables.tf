variable "sharing" {
  description = "Optional one-state RAM sharing configuration. Set null to omit all RAM resources and state."
  nullable    = true

  type = object({
    name       = string
    principals = map(string)
  })

  default = {
    name = "compact-core-network"
    principals = {
      application = "123456789012"
    }
  }
}
