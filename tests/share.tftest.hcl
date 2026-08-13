mock_provider "aws" {
  override_during = plan

  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_resource "aws_ram_resource_share" {
    defaults = { arn = "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111" }
  }
  mock_resource "aws_ram_resource_association" {
    defaults = { id = "resource-association-mock" }
  }
  mock_resource "aws_ram_principal_association" {
    defaults = { id = "principal-association-mock" }
  }
}

run "create_share_with_all_principal_forms" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "production-cloudwan" }
    resources = {
      core = "arn:aws:networkmanager::123456789012:core-network/core-network-11111111111111111"
    }
    principals = {
      account = "123456789012"
      org     = "arn:aws:organizations::123456789012:organization/o-abcdefghij"
      ou      = "arn:aws:organizations::123456789012:ou/o-abcdefghij/ou-abcd-12345678"
    }
  }
  assert {
    condition = (
      length(aws_ram_resource_share.this) == 1 &&
      toset(keys(aws_ram_resource_association.this)) == toset(["core"]) &&
      toset(keys(aws_ram_principal_association.this)) == toset(["account", "org", "ou"])
    )
    error_message = "Share create mode must preserve caller-owned association keys."
  }
}

run "reference_existing_share" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = {
      create = false
      arn    = "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111"
    }
    resources = {
      core = "arn:aws:networkmanager::123456789012:core-network/core-network-11111111111111111"
    }
  }
  assert {
    condition     = length(aws_ram_resource_share.this) == 0 && output.resource_share_arn == "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111"
    error_message = "Reference mode must own no share and retain its ARN."
  }
}

run "empty_association_maps" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "empty-share" }
    resources      = {}
    principals     = {}
  }
  assert {
    condition     = output.resource_association_ids == {} && output.principal_association_ids == {}
    error_message = "Empty enabled collections must return empty maps."
  }
}

run "reject_create_without_name" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = {}
  }
  expect_failures = [var.resource_share]
}

run "reject_create_with_arn" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = {
      name = "invalid"
      arn  = "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111"
    }
  }
  expect_failures = [var.resource_share]
}

run "reject_reference_create_fields" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = {
      create = false
      arn    = "arn:aws:ram:us-east-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111"
      name   = "not-owned"
    }
  }
  expect_failures = [var.resource_share]
}

run "reject_resource_key" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "invalid-resource-key" }
    resources = {
      "Core Network" = "arn:aws:networkmanager::123456789012:core-network/core-network-11111111111111111"
    }
  }
  expect_failures = [var.resources]
}

run "reject_resource_arn" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "invalid-resource" }
    resources      = { core = "core-network-11111111111111111" }
  }
  expect_failures = [var.resources]
}

run "reject_account_principal" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "invalid-account" }
    principals     = { account = "1234" }
  }
  expect_failures = [var.principals]
}

run "reject_organization_principal" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "invalid-org" }
    principals     = { org = "arn:aws:organizations::123456789012:organization/bad" }
  }
  expect_failures = [var.principals]
}

run "reject_principal_key" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "invalid-key" }
    principals     = { "Bad Key" = "123456789012" }
  }
  expect_failures = [var.principals]
}

run "reject_non_us_east_1" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "wrong-region" }
  }
  override_data {
    target = data.aws_region.current
    values = { region = "us-west-2" }
  }
  expect_failures = [terraform_data.partition_and_region]
}

run "reject_govcloud_partition" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "govcloud-unverified" }
  }
  override_data {
    target = data.aws_partition.current
    values = { partition = "aws-us-gov" }
  }
  expect_failures = [terraform_data.partition_and_region]
}

run "reject_reference_partition_mismatch" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = {
      create = false
      arn    = "arn:aws-us-gov:ram:us-gov-west-1:123456789012:resource-share/11111111-1111-1111-1111-111111111111"
    }
  }
  expect_failures = [terraform_data.partition_and_region]
}

run "reject_organization_principal_partition_mismatch_a06" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "cross-partition-principal" }
    principals = {
      ou = "arn:aws-us-gov:organizations::123456789012:ou/o-abcdefghij/ou-abcd-12345678"
    }
  }
  expect_failures = [terraform_data.partition_and_region]
}

run "reject_impossible_ou_id_a08" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "impossible-ou" }
    principals = {
      ou = "arn:aws:organizations::123456789012:ou/o-abcdefghij/ou-----"
    }
  }
  expect_failures = [var.principals]
}

run "reject_zero_account_principal_a09" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "zero-account" }
    principals     = { account = "000000000000" }
  }
  expect_failures = [var.principals]
}

run "reject_zero_account_organization_principal_a09" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "zero-account-organization" }
    principals = {
      organization = "arn:aws:organizations::000000000000:organization/o-abcdefghij"
    }
  }
  expect_failures = [var.principals]
}

run "reject_zero_account_ou_principal_a09" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "zero-account-ou" }
    principals = {
      ou = "arn:aws:organizations::000000000000:ou/o-abcdefghij/ou-abcd-12345678"
    }
  }
  expect_failures = [var.principals]
}

run "reject_resource_partition_mismatch" {
  command = plan
  module { source = "./modules/core-network-share" }
  variables {
    resource_share = { name = "cross-partition-resource" }
    resources = {
      core = "arn:aws-us-gov:networkmanager::123456789012:core-network/core-network-11111111111111111"
    }
  }
  expect_failures = [terraform_data.partition_and_region]
}
