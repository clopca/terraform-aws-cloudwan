mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names    = ["us-east-1a", "us-east-1b", "us-east-1c"]
      zone_ids = ["use1-az1", "use1-az2", "use1-az3"]
    }
  }
}

# Issue #25 regression: a firewall policy ARN computed in the same plan must
# not poison the network_firewall for_each keys. The fixture plans successfully
# because instance keys come exclusively from var.aws_network_firewall.
run "computed_firewall_policy_arn_plans" {
  command = plan

  module {
    source = "./tests/fixtures/computed-firewall-policy"
  }
}
