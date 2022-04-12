locals {
  target_size_adjusted = length([for k, i in var.stateful_target_configs : k if i["group"] == "canary"])
}

module "live_instance_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  version            = "7.1.0"
  name_prefix        = "live-instance-template"
  project_id         = var.project_id
  subnetwork         = var.network
  subnetwork_project = var.project_id
  region             = var.region
  service_account    = var.service_account
}

module "canary_instance_template" {
  source             = "terraform-google-modules/vm/google//modules/instance_template"
  version            = "7.1.0"
  name_prefix        = "canary-instance-template"
  project_id         = var.project_id
  subnetwork         = var.network
  subnetwork_project = var.project_id
  region             = var.region
  service_account    = var.service_account
}

resource "google_compute_region_instance_group_manager" "appserver" {
  name               = "test-igm"
  base_instance_name = "app"
  region             = var.region
  target_size        = null
  project            = var.project_id
  wait_for_instances = true

  update_policy {
    instance_redistribution_type = "NONE"
    max_surge_fixed              = 0
    max_surge_percent            = null
    max_unavailable_fixed        = 3
    max_unavailable_percent      = null
    min_ready_sec                = 30
    minimal_action               = "REPLACE"
    replacement_method           = "RECREATE"
    type                         = "OPPORTUNISTIC"
  }

  version {
    instance_template = module.live_instance_template.self_link
  }

  version {
    instance_template = module.canary_instance_template.self_link
    target_size {
      fixed = local.target_size_adjusted
    }
  }
}


resource "google_compute_region_per_instance_config" "instance_configs" {
  for_each                      = var.stateful_target_configs
  region_instance_group_manager = google_compute_region_instance_group_manager.appserver.name
  name                          = each.key
  region                        = var.region
  project                       = var.project_id
  minimal_action                = "REPLACE"

  # So here we are supplying something in the metadata field by default (in case user doesn't supply anything). Whenever the metadata gets updated, it should trigger a replace for the instance
  preserved_state {
    metadata = {
      instance_template = each.value.group == "canary" ? module.canary_instance_template.self_link : module.live_instance_template.self_link
    }
  }
}
