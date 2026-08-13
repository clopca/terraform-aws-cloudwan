mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names    = ["us-east-1a"]
      zone_ids = ["use1-az1"]
    }
  }
}

run "shared_services_excludes_reserved_subnets" {
  command = plan

  assert {
    condition = output.central_vpcs == {} && length(regexall(
      "k != \"public\" && k != \"core_network\"",
      file("${path.module}/main.tf")
    )) == 1
    error_message = "Shared-services routes must exclude both public and core_network subnet groups."
  }
}

run "firewall_key_must_match_central_vpc" {
  command = plan

  variables {
    aws_network_firewall = {
      missing = {
        name        = "missing"
        description = "Contract test"
        policy_arn  = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/test"
      }
    }
  }

  expect_failures = [output.aws_network_firewall]
}

run "firewall_requires_compatible_central_vpc_type" {
  command = plan

  variables {
    core_network_arn = "arn:aws:networkmanager::123456789012:core-network/core-network-0123456789abcdef0"
    central_vpcs = {
      shared = {
        type       = "shared_services"
        cidr_block = "10.0.0.0/24"
        az_count   = 1
        subnets = {
          services     = { netmask = 28 }
          core_network = { netmask = 28 }
        }
      }
    }

    aws_network_firewall = {
      shared = {
        name        = "shared"
        description = "Contract test"
        policy_arn  = "arn:aws:network-firewall:us-east-1:123456789012:firewall-policy/test"
      }
    }
  }

  expect_failures = [output.aws_network_firewall]
}
