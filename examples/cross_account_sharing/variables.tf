variable "organization_arn" {
  description = "AWS Organizations organization ARN allowed to use the Core Network share."
  type        = string
  default     = "arn:aws:organizations::123456789012:organization/o-a1b2c3d4e5"
}

variable "application_ou_arn" {
  description = "AWS Organizations OU ARN allowed to use the Core Network share."
  type        = string
  default     = "arn:aws:organizations::123456789012:ou/o-a1b2c3d4e5/ou-abcd-12345678"
}
