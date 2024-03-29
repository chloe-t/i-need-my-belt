terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }

  backend "remote" {
    # The name of your Terraform Cloud organization.
    organization = "i-need-my-belt"

    # The name of the Terraform Cloud workspace to store Terraform state files in.
    workspaces {
      name = "i-need-my-belt-workspace"
    }
  }
}

data "google_client_openid_userinfo" "terraform_service_account" {
}

resource "tls_private_key" "ephemeral" {
  rsa_bits  = 2048
  algorithm = "RSA"
}

locals {
  ssh_private_key              = tls_private_key.ephemeral.private_key_openssh
  ssh_pub_key                  = tls_private_key.ephemeral.public_key_openssh
  ssh_pub_key_without_new_line = replace(local.ssh_pub_key, "\n", "")
  ssh_user_name                = "chloe_trouilh"
  project_name                 = "i-need-my-belt"
}

resource "google_compute_resource_policy" "gitlab-instance-scheduler" {
  name        = "gitlab-instance-schedule"
  description = "Start and stop gitlab instance automatically"

  instance_schedule_policy {
    # vm_start_schedule { #Comment auto-start, not usefull daily
    #   schedule = "45 7 * * 1-5"
    # }
    vm_stop_schedule {
      schedule = "30 18 * * 0-6"
    }
    time_zone = "Europe/Paris"
  }
}

resource "google_compute_network" "gitlab-network" {
  name = "gitlab-network"
}

resource "google_compute_firewall" "gitlab-network-firewall" {
  name    = "gitlab-firewall"
  network = google_compute_network.gitlab-network.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000", "8929"]
  }

  source_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "gitlab_compute_instance" {
  name         = "${local.project_name}-gitlab-instance"
  machine_type = "e2-medium"
  zone         = "us-west1-a"

  resource_policies = [
    google_compute_resource_policy.gitlab-instance-scheduler.id
  ]

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-jammy-v20230214"
    }
  }

  network_interface {
    network = google_compute_network.gitlab-network.name
    access_config {
      # nat_ip = google_compute_address.static_ip.address # Remove static ip since it's more expensive $$ 
    }
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  service_account {
    email  = data.google_client_openid_userinfo.terraform_service_account.email # "github-actions-service-account@i-need-my-belt.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  tags = [
    "web",
    "http-server",
    "https-server"
  ]

  metadata = {
    ssh-keys = "${local.ssh_user_name}:${local.ssh_pub_key_without_new_line} ${local.ssh_user_name}"
    hostname = "gitlab.${local.project_name}.com"
  }

  metadata_startup_script = file("./install_gitlab.sh")
}
