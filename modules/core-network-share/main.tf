data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  resource_share_arn = var.resource_share.create ? aws_ram_resource_share.this[0].arn : var.resource_share.arn
}

resource "terraform_data" "partition_and_region" {
  input = {
    partition = data.aws_partition.current.partition
    region    = data.aws_region.current.region
  }

  lifecycle {
    precondition {
      condition     = data.aws_partition.current.partition == "aws"
      error_message = "v4.0 core-network-share supports only the commercial aws partition; GovCloud is not yet verified and aws-cn is unsupported."
    }

    precondition {
      condition     = data.aws_region.current.region == "us-east-1"
      error_message = "Commercial-partition Core Network shares must use a provider configured in us-east-1."
    }

    precondition {
      condition = var.resource_share.create ? true : can(regex(
        "^arn:${data.aws_partition.current.partition}:ram:${data.aws_region.current.region}:[0-9]{12}:resource-share/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
        var.resource_share.arn
      ))
      error_message = "resource_share.arn must match the effective partition and region."
    }

    precondition {
      condition = alltrue([
        for arn in values(var.resources) : can(regex(
          "^arn:${data.aws_partition.current.partition}:networkmanager::[0-9]{12}:core-network/core-network-[0-9a-f]{8,17}$",
          arn
        ))
      ])
      error_message = "Every resource ARN must match the effective AWS partition."
    }

    precondition {
      condition = alltrue([
        for principal in values(var.principals) :
        !startswith(principal, "arn:") || can(regex(
          "^arn:${data.aws_partition.current.partition}:organizations::[0-9]{12}:(organization/o-[a-z0-9]{10,32}|ou/o-[a-z0-9]{10,32}/ou-[a-z0-9]{4,32}-[a-z0-9]{8,32})$",
          principal
        ))
      ])
      error_message = "Every Organizations principal ARN must match the effective AWS partition."
    }
  }
}

resource "aws_ram_resource_share" "this" {
  count = var.resource_share.create ? 1 : 0

  name                      = var.resource_share.name
  allow_external_principals = var.resource_share.allow_external_principals
  tags                      = var.resource_share.tags

  depends_on = [terraform_data.partition_and_region]
}

resource "aws_ram_resource_association" "this" {
  for_each = var.resources

  resource_arn       = each.value
  resource_share_arn = local.resource_share_arn

  depends_on = [terraform_data.partition_and_region]
}

resource "aws_ram_principal_association" "this" {
  for_each = var.principals

  principal          = each.value
  resource_share_arn = local.resource_share_arn

  depends_on = [terraform_data.partition_and_region]
}
