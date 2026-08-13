# --- root/variables.tf ---

# ---------- GLOBAL NETWORK ---------
variable "global_network_id" {
  type        = string
  description = "(Optional) Global Network ID. Conflicts with `var.global_network`."
  default     = null
}

variable "global_network" {
  description = <<-EOF
    Global Network definition - providing information to this variable will create a new Global Network. Conflicts with `var.global_network_id`.
    This variable expects the following attributes:
    - `description` = (string) Global Network's description.
    - `tags`        = (Optional|map(string)) Tags to apply to the Global Network.
EOF
  type        = any
  default     = {}

  validation {
    condition = var.global_network == null ? true : try(length(setsubtract(keys(var.global_network), [
      "description",
      "tags"
    ])) == 0, false)
    error_message = "Only valid key values for var.global_network are \"description\" and \"tags\"."
  }

  validation {
    condition = var.global_network == null || try(length(keys(var.global_network)) == 0, false) ? true : try(
      contains(keys(var.global_network), "description") &&
      var.global_network.description == tostring(var.global_network.description) &&
      (!contains(keys(var.global_network), "tags") || var.global_network.tags == null || alltrue([
        for value in values(var.global_network.tags) : value == tostring(value)
      ])),
      false
    )
    error_message = "A non-empty var.global_network must include string description; optional tags must be a map of strings."
  }
}

# ---------- CORE NETWORK ----------
variable "core_network_arn" {
  type        = string
  description = "(Optional) Core Network ARN. Conflicts with `var.core_network`."
  default     = null
}

variable "core_network" {
  description = <<-EOF
    Core Network definition - providing information to this variable will create a new Core Network. Conflicts with `var.core_network_arn`.
    This variable expects the following attributes:
    - `description`                              = (string) Core Network's description.
    - `policy_document`                          = (string) Core Network's policy in JSON format.
    - `base_policy_document`                     = (Optional|string) Explicit create-only base policy JSON. Conflicts with `base_policy_regions`.
    - `base_policy_regions`                      = (Optional|collection(string)) Create-only Regions used to generate the base policy. Conflicts with `base_policy_document`.
    - `resource_share_name`                      = (Optional|string) AWS Resource Access Manager (RAM) Resource Share name. Providing this value, RAM resources will be created to share the Core Network with the principals indicated in `var.core_network.ram_share_principals`.
    - `resource_share_allow_external_principals` = (Optional|bool) Indicates whether principals outside your AWS Organization can be associated with a Resource Share.
    - `ram_share_principals`                     = (Optional|list(string)) List of principals (AWS Account or AWS Organization) to share the Core Network with.
    - `tags`                                     = (Optional|map(string)) Tags to apply to the Core Network and RAM Resource Share (if created).
EOF
  type        = any
  default     = {}

  validation {
    condition = var.core_network == null ? true : try(length(setsubtract(keys(var.core_network), [
      "description",
      "policy_document",
      "base_policy_document",
      "base_policy_regions",
      "resource_share_name",
      "resource_share_allow_external_principals",
      "ram_share_principals",
      "tags"
    ])) == 0, false)
    error_message = "Only valid key values for var.core_network are \"description\", \"policy_document\", \"base_policy_document\", \"base_policy_regions\", \"resource_share_name\", \"resource_share_allow_external_principals\", \"ram_share_principals\", and \"tags\"."
  }

  validation {
    condition = var.core_network == null || try(length(keys(var.core_network)) == 0, false) ? true : try(
      contains(keys(var.core_network), "description") &&
      var.core_network.description == tostring(var.core_network.description) &&
      contains(keys(var.core_network), "policy_document") &&
      var.core_network.policy_document == tostring(var.core_network.policy_document) &&
      (!contains(keys(var.core_network), "base_policy_document") || var.core_network.base_policy_document == null || var.core_network.base_policy_document == tostring(var.core_network.base_policy_document)) &&
      (!contains(keys(var.core_network), "base_policy_regions") || var.core_network.base_policy_regions == null || (
        length(var.core_network.base_policy_regions) > 0 && alltrue([
          for region in var.core_network.base_policy_regions : region == tostring(region)
        ])
      )) &&
      !(try(var.core_network.base_policy_document, null) != null && try(var.core_network.base_policy_regions, null) != null) &&
      (!contains(keys(var.core_network), "resource_share_name") || var.core_network.resource_share_name == null || var.core_network.resource_share_name == tostring(var.core_network.resource_share_name)) &&
      (!contains(keys(var.core_network), "resource_share_allow_external_principals") || var.core_network.resource_share_allow_external_principals == null || var.core_network.resource_share_allow_external_principals == tobool(var.core_network.resource_share_allow_external_principals)) &&
      (!contains(keys(var.core_network), "ram_share_principals") || var.core_network.ram_share_principals == null || alltrue([
        for principal in var.core_network.ram_share_principals : principal == tostring(principal)
      ])) &&
      (!contains(keys(var.core_network), "tags") || var.core_network.tags == null || alltrue([
        for value in values(var.core_network.tags) : value == tostring(value)
      ])),
      false
    )
    error_message = "A non-empty var.core_network must include string description and policy_document. Optional share fields and tags must use their documented types; base_policy_document and base_policy_regions are mutually exclusive."
  }
}

# ---------- CENTRAL VPCS ----------
variable "central_vpcs" {
  description = <<-EOF
    Central VPCs definition. This variable expects a map of VPCs. You can specify the following attributes:
    - `type`                     = (string) VPC type (`inspection`, `egress`, `egress_with_inspection`, `ingress`, `ingress_with_inspection`, `shared_services`) - each one of them with a specific VPC routing. For more information about the configuration of each VPC type, check the README.
    - `name`                     = (Optional|string) Name of the VPC. If not defined, the key of the map will be used.
    - `cidr_block`               = (Optional|string) IPv4 CIDR range. **Cannot set if vpc_ipv4_ipam_pool_id is set.**
    - `vpc_ipv4_ipam_pool_id`    = (Optional|string) Set to use IPAM to get an IPv4 CIDR block. **Cannot set if cidr_block is set.**
    - `vpc_ipv4_netmask_length`  = (Optional|number) Set to use IPAM to get an IPv4 CIDR block using a specified netmask. Must be set with `var.vpc_ipv4_ipam_pool_id`.
    - `az_count`                 = (number) Searches the number of AZs in the region and takes a slice based on this number - the slice is sorted a-z.
    - `vpc_enable_dns_hostnames` = (Optional|bool) Indicates whether the instances launched in the VPC get DNS hostnames. Enabled by default.
    - `vpc_enable_dns_support`   = (Optional|bool) Indicates whether DNS resolution is supported for the VPC. Enabled by default.
    - `vpc_instance_tenancy`     = (Optional|string) The allowed tenancy of instances launched into the VPC.
    - `vpc_flow_logs`            = (Optional|object(any)) Configuration of the VPC Flow Logs of the VPC configured.
    - `subnets`                  = (any) Open subnet map passed through to the VPC module. Known address fields are validated without closing the nested shape.
    - `tags`                     = (Optional|map(string)) Tags to apply to all the Central VPC resources.
EOF
  type        = any
  default     = {}

  validation {
    condition = var.central_vpcs == null ? true : try(alltrue([
      for vpc in var.central_vpcs : length(setsubtract(keys(vpc), [
        "type",
        "name",
        "cidr_block",
        "az_count",
        "vpc_ipv4_ipam_pool_id",
        "vpc_ipv4_netmask_length",
        "vpc_enable_dns_hostnames",
        "vpc_enable_dns_support",
        "vpc_instance_tenancy",
        "vpc_flow_logs",
        "subnets",
        "tags"
      ])) == 0
    ]), false)
    error_message = "Valid key values for Central VPCs are \"type\", \"name\", \"cidr_block\", \"az_count\", \"vpc_ipv4_ipam_pool_id\", \"vpc_ipv4_netmask_length\", \"vpc_enable_dns_hostnames\", \"vpc_enable_dns_support\", \"vpc_instance_tenancy\", \"subnets\", \"vpc_flow_logs\", and \"tags\"."
  }

  validation {
    condition = var.central_vpcs == null ? true : try(alltrue([
      for vpc in var.central_vpcs :
      contains(keys(vpc), "type") &&
      vpc.type == tostring(vpc.type) &&
      contains(["inspection", "egress", "egress_with_inspection", "shared_services", "ingress", "ingress_with_inspection"], vpc.type) &&
      contains(keys(vpc), "az_count") &&
      vpc.az_count == tonumber(vpc.az_count) &&
      vpc.az_count > 0 && floor(vpc.az_count) == vpc.az_count &&
      contains(keys(vpc), "subnets") && length(keys(vpc.subnets)) > 0
    ]), false)
    error_message = "Each var.central_vpcs entry must include a supported string type, a positive integer az_count, and a non-empty subnets map."
  }

  validation {
    condition = var.central_vpcs == null ? true : try(alltrue([
      for vpc in var.central_vpcs :
      (try(vpc.cidr_block, null) != null) != (try(vpc.vpc_ipv4_ipam_pool_id, null) != null) &&
      (try(vpc.cidr_block, null) == null || vpc.cidr_block == tostring(vpc.cidr_block)) &&
      (try(vpc.vpc_ipv4_ipam_pool_id, null) == null || vpc.vpc_ipv4_ipam_pool_id == tostring(vpc.vpc_ipv4_ipam_pool_id)) &&
      (try(vpc.vpc_ipv4_ipam_pool_id, null) == null || (
        try(vpc.vpc_ipv4_netmask_length, null) != null &&
        vpc.vpc_ipv4_netmask_length == tonumber(vpc.vpc_ipv4_netmask_length) &&
        floor(vpc.vpc_ipv4_netmask_length) == vpc.vpc_ipv4_netmask_length
      ))
    ]), false)
    error_message = "Each var.central_vpcs entry must set exactly one addressing mode: cidr_block, or vpc_ipv4_ipam_pool_id together with integer vpc_ipv4_netmask_length."
  }

  validation {
    condition = var.central_vpcs == null ? true : try(alltrue(flatten([
      for vpc in var.central_vpcs : [
        for subnet in values(vpc.subnets) :
        (try(subnet.cidrs, null) == null || (
          length(subnet.cidrs) == vpc.az_count && alltrue([
            for cidr in subnet.cidrs : cidr == tostring(cidr)
          ])
        )) &&
        (try(subnet.netmask, null) == null || (
          subnet.netmask == tonumber(subnet.netmask) && floor(subnet.netmask) == subnet.netmask
        )) &&
        !(try(subnet.cidrs, null) != null && try(subnet.netmask, null) != null) &&
        (try(subnet.tags, null) == null || alltrue([
          for value in values(subnet.tags) : value == tostring(value)
        ]))
      ]
    ])), false)
    error_message = "Known subnet fields must use compatible types: cidrs is a string list with az_count entries, netmask is an integer, cidrs and netmask are mutually exclusive, and tags is a map of strings. Additional subnet fields remain supported."
  }

  validation {
    condition = var.central_vpcs == null ? true : try(alltrue([
      for vpc in var.central_vpcs :
      (try(vpc.name, null) == null || vpc.name == tostring(vpc.name)) &&
      (try(vpc.vpc_enable_dns_hostnames, null) == null || vpc.vpc_enable_dns_hostnames == tobool(vpc.vpc_enable_dns_hostnames)) &&
      (try(vpc.vpc_enable_dns_support, null) == null || vpc.vpc_enable_dns_support == tobool(vpc.vpc_enable_dns_support)) &&
      (try(vpc.vpc_instance_tenancy, null) == null || vpc.vpc_instance_tenancy == tostring(vpc.vpc_instance_tenancy)) &&
      (try(vpc.vpc_flow_logs, null) == null || can(keys(vpc.vpc_flow_logs))) &&
      (try(vpc.tags, null) == null || alltrue([
        for value in values(vpc.tags) : value == tostring(value)
      ]))
    ]), false)
    error_message = "Optional var.central_vpcs fields must use their documented string, boolean, object, and map(string) shapes."
  }
}

# ---------- NETWORK DEFINITION (IPV4) ----------
variable "ipv4_network_definition" {
  type        = string
  description = "Definition of the IPv4 CIDR blocks of the AWS network - needed for the VPC routes in Ingress and Egress VPC types. You can specify either a CIDR range or a Prefix List ID."
  default     = null
}

# ---------- AWS NETWORK FIREWALL ----------
variable "aws_network_firewall" {
  description = <<-EOF
    AWS Network Firewall configuration. This variable expects a map of Network Firewall definitions to create a firewall resource (and corresponding VPC routing to firewall endpoints) in the corresponding VPC. The central VPC is selected by using the same map key as in var.central_vpcs. Resources are created only in VPC types `inspection`, `egress_with_inspection`, and `ingress_with_inspection`.
    Each map item expects the following attributes:
    - `name`                     = (string) Name of the AWS Network Firewall resource.
    - `description`              = (string) Description of the AWS Network Firewall resource.
    - `policy_arn`               = (string) ARN of the Network Firewall Policy.
    - `delete_protection`        = (Optional|bool) Indicates whether it is possible to delete the firewall. Defaults to `false`.
    - `policy_change_protection` = (Optional|bool) Indicates whether it is possible to change the firewall policy. Defaults to `false`.
    - `subnet_change_protection` = (Optional|bool) Indicates whether it is possible to change the associated subnet(s) after creation. Defaults to `false`.
    - `tags`                     = (Optional|map(string)) Tags to apply to the AWS Network Firewall resource.
EOF
  type        = any
  default     = {}

  validation {
    condition = var.aws_network_firewall == null ? true : try(alltrue([
      for firewall in var.aws_network_firewall : length(setsubtract(keys(firewall), [
        "name",
        "description",
        "policy_arn",
        "delete_protection",
        "policy_change_protection",
        "subnet_change_protection",
        "tags"
      ])) == 0
    ]), false)
    error_message = "Valid keys for each AWS Network Firewall definition are \"name\", \"description\", \"policy_arn\", \"delete_protection\", \"policy_change_protection\", \"subnet_change_protection\", and \"tags\"."
  }

  validation {
    condition = var.aws_network_firewall == null ? true : try(alltrue([
      for firewall in var.aws_network_firewall :
      contains(keys(firewall), "name") && firewall.name == tostring(firewall.name) &&
      contains(keys(firewall), "description") && firewall.description == tostring(firewall.description) &&
      contains(keys(firewall), "policy_arn") && firewall.policy_arn == tostring(firewall.policy_arn) &&
      (try(firewall.delete_protection, null) == null || firewall.delete_protection == tobool(firewall.delete_protection)) &&
      (try(firewall.policy_change_protection, null) == null || firewall.policy_change_protection == tobool(firewall.policy_change_protection)) &&
      (try(firewall.subnet_change_protection, null) == null || firewall.subnet_change_protection == tobool(firewall.subnet_change_protection)) &&
      (try(firewall.tags, null) == null || alltrue([
        for value in values(firewall.tags) : value == tostring(value)
      ]))
    ]), false)
    error_message = "Each var.aws_network_firewall entry must include string name, description, and policy_arn; optional protections must be booleans and tags must be a map of strings."
  }
}

# ---------- TAGS ----------
variable "tags" {
  description = "(Optional) Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
