mock_provider "aws" {
  override_during = plan
  mock_resource "aws_networkmanager_core_network_policy_attachment" {
    defaults = { state = "AVAILABLE" }
  }
}

run "policy_2021_12" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
  }
  assert {
    condition     = output.policy_schema_version == "2021.12" && output.core_network_state == "AVAILABLE"
    error_message = "A 2021.12 policy must expose its schema and Core Network state."
  }
}

run "policy_2025_11" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2025.11\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
  }
}

run "reject_invalid_json" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "not-json"
  }
  expect_failures = [var.policy_document]
}

run "reject_unsupported_version" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2030.01\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
  }
  expect_failures = [var.policy_document]
}

run "reject_empty_edge_locations" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[]},\"segments\":[{\"name\":\"shared\"}]}"
  }
  expect_failures = [var.policy_document]
}

run "reject_blank_edge_location" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\" \"}]},\"segments\":[{\"name\":\"shared\"}]}"
  }
  expect_failures = [var.policy_document]
}

run "reject_segments_object" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":{\"shared\":{}}}"
  }
  expect_failures = [var.policy_document]
}

run "reject_empty_segments" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[]}"
  }
  expect_failures = [var.policy_document]
}

run "reject_segment_without_name" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{}]}"
  }
  expect_failures = [var.policy_document]
}

run "approval_absent" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
    approval        = null
  }
}

run "approval_exact_bytes_match" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
    approval = {
      sha256      = "c44a3c119a92ff28947cf6a4333bd9ca607bb58cc54cc34cb6862bcc8a440c68"
      digest_kind = "policy_document_bytes"
    }
  }
}

run "approval_canonical_json_match" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\n  \"segments\": [{\"name\": \"shared\"}],\n  \"version\": \"2021.12\",\n  \"core-network-configuration\": {\"edge-locations\": [{\"location\": \"us-west-2\"}]}\n}"
    approval = {
      sha256      = "ede9b0ad099074beef256db38815bb7eedd81920b96c5055105c4f63aa95bc91"
      digest_kind = "terraform_canonical_json"
    }
  }
}

run "reject_approval_mismatch" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
    approval = {
      sha256      = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      digest_kind = "policy_document_bytes"
    }
  }
  expect_failures = [terraform_data.policy_approval]
}

run "reject_approval_digest_shape" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
    approval = {
      sha256      = "short"
      digest_kind = "policy_document_bytes"
    }
  }
  expect_failures = [var.approval]
}

run "reject_approval_digest_kind" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
    approval = {
      sha256      = "c44a3c119a92ff28947cf6a4333bd9ca607bb58cc54cc34cb6862bcc8a440c68"
      digest_kind = "unknown"
    }
  }
  expect_failures = [var.approval]
}

run "compound_timeout_1h30m" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
    timeouts        = { update = "1h30m" }
  }
}

run "reject_zero_timeout" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
    timeouts        = { update = "0m" }
  }
  expect_failures = [var.timeouts]
}

run "reject_invalid_timeout" {
  command = plan
  module { source = "./modules/policy" }
  variables {
    core_network_id = "core-network-11111111111111111"
    policy_document = "{\"version\":\"2021.12\",\"core-network-configuration\":{\"edge-locations\":[{\"location\":\"us-west-2\"}]},\"segments\":[{\"name\":\"shared\"}]}"
    timeouts        = { update = "tomorrow" }
  }
  expect_failures = [var.timeouts]
}
