variable "network" {
}

variable "project_id" {
}

variable "region" {
  default = "us-central1"
}

variable "service_account" {
  type = object({
    email  = string
    scopes = set(string)
  })
}

variable "stateful_target_configs" {
  default = {
    "gcp-ticket-1" = {
      group = "live"
    },
    "gcp-ticket-2" = {
      group = "live"
    },
    "gcp-ticket-3" = {
      group = "live"
    },
    "gcp-ticket-4" = {
      group = "live"
    }
  }
}
