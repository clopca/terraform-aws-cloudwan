mock_provider "aws" {
  override_during = plan
  mock_data "aws_networkmanager_global_network" {
    defaults = {
      id  = "global-network-11111111111111111"
      arn = "arn:aws:networkmanager::123456789012:global-network/global-network-11111111111111111"
    }
  }
  mock_data "aws_networkmanager_core_network" {
    defaults = {
      core_network_id   = "core-network-11111111111111111"
      arn               = "arn:aws:networkmanager::123456789012:core-network/core-network-11111111111111111"
      global_network_id = "global-network-11111111111111111"
      state             = "AVAILABLE"
      edges             = []
      segments          = []
    }
  }
}

run "computed_reference_ids_keep_cardinality_known" {
  command = plan
  module { source = "./tests/fixtures/computed-reference" }
  assert {
    condition = (
      module.cloudwan.resources.global_network == null &&
      module.cloudwan.resources.core_network == null
    )
    error_message = "Computed reference IDs must not control resource cardinality."
  }
}
