locals {
  policy_document_sha256 = sha256(var.policy_document)
  canonical_json_sha256  = sha256(jsonencode(jsondecode(var.policy_document)))
  approval_digest = var.approval == null ? null : (
    var.approval.digest_kind == "policy_document_bytes" ?
    local.policy_document_sha256 :
    local.canonical_json_sha256
  )
}

resource "terraform_data" "policy_approval" {
  input = local.policy_document_sha256

  lifecycle {
    precondition {
      condition = var.approval == null ? true : (
        lower(trimspace(var.approval.sha256)) == local.approval_digest
      )
      error_message = "approval.sha256 does not match policy_document for the selected digest_kind."
    }
  }
}

resource "aws_networkmanager_core_network_policy_attachment" "this" {
  core_network_id = var.core_network_id
  policy_document = var.policy_document

  timeouts {
    update = var.timeouts.update
  }

  depends_on = [terraform_data.policy_approval]
}
