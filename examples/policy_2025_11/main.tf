data "aws_networkmanager_core_network_policy_document" "routing_and_inspection" {
  version = "2025.11"

  core_network_configuration {
    asn_ranges = ["64512-64520"]

    edge_locations {
      location = "us-west-2"
    }

    edge_locations {
      location = "us-east-1"
    }
  }

  segments {
    name                          = "application"
    require_attachment_acceptance = true
  }

  segments {
    name                          = "sharedservices"
    require_attachment_acceptance = true
  }

  network_function_groups {
    name                          = "inspection"
    description                   = "Central inspection attachments"
    require_attachment_acceptance = true
  }

  routing_policies {
    routing_policy_name        = "preferprivate"
    routing_policy_description = "Prefer private application routes"
    routing_policy_direction   = "inbound"
    routing_policy_number      = 100

    routing_policy_rules {
      rule_number = 100

      rule_definition {
        match_conditions {
          type  = "prefix-in-cidr"
          value = "10.0.0.0/8"
        }

        action {
          type  = "set-local-preference"
          value = "200"
        }
      }
    }
  }

  attachment_routing_policy_rules {
    rule_number    = 100
    description    = "Apply private-route preference to trusted attachments"
    edge_locations = ["us-west-2", "us-east-1"]

    conditions {
      type  = "routing-policy-label"
      value = "trusted"
    }

    action {
      associate_routing_policies = ["preferprivate"]
    }
  }

  segment_actions {
    action  = "send-via"
    mode    = "single-hop"
    segment = "application"

    when_sent_to {
      segments = ["sharedservices"]
    }

    via {
      network_function_groups = ["inspection"]
    }
  }

  segment_actions {
    action               = "share"
    mode                 = "attachment-route"
    segment              = "sharedservices"
    share_with           = ["application"]
    routing_policy_names = ["preferprivate"]
  }

  attachment_policies {
    rule_number = 50

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "network-function"
      value    = "inspection"
    }

    action {
      add_to_network_function_group = "inspection"
    }
  }

  attachment_policies {
    rule_number = 100

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = "application"
    }

    action {
      association_method = "constant"
      segment            = "application"
    }
  }

  attachment_policies {
    rule_number = 200

    conditions {
      type     = "tag-value"
      operator = "equals"
      key      = "segment"
      value    = "sharedservices"
    }

    action {
      association_method = "constant"
      segment            = "sharedservices"
    }
  }
}

module "cloudwan" {
  source = "../.."

  global_network = { description = "policy-2025-11-global-network" }
  core_network = {
    description = "policy-2025-11-core-network"
    base_policy = {
      policy_document = data.aws_networkmanager_core_network_policy_document.routing_and_inspection.json
    }
  }
}

module "policy" {
  source = "../../modules/policy-deployment"

  core_network_id = module.cloudwan.core_network_id
  policy_document = data.aws_networkmanager_core_network_policy_document.routing_and_inspection.json
  approval = {
    sha256      = sha256(data.aws_networkmanager_core_network_policy_document.routing_and_inspection.json)
    digest_kind = "policy_document_bytes"
  }
  timeouts = { update = "60m" }
}
