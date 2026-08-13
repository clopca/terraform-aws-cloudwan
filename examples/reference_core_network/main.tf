module "cloudwan" {
  source = "../.."

  global_network = {
    create = false
    id     = var.global_network_id
  }

  core_network = {
    create = false
    id     = var.core_network_id
  }
}
