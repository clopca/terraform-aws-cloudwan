variable "global_network_id" {
  type        = string
  description = "Existing Global Network ID."
  default     = "global-network-0123456789abcdef0"
}

variable "core_network_id" {
  type        = string
  description = "Existing Core Network ID belonging to global_network_id."
  default     = "core-network-0123456789abcdef0"
}
