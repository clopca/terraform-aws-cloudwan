terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59"
    }
  }
}

resource "terraform_data" "ids" {
  input = {
    global = "global-network-11111111111111111"
    core   = "core-network-11111111111111111"
  }
}

module "cloudwan" {
  source = "../../.."

  global_network = {
    create = false
    id     = terraform_data.ids.output.global
  }
  core_network = {
    create = false
    id     = terraform_data.ids.output.core
  }
}
