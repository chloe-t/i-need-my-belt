
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
}

resource "google_project_iam_member" "project" {
  project = "i-need-my-belt"
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${data.google_client_openid_userinfo.terraform_service_account.email}"
}

resource "google_compute_resource_policy" "gitlab-instance-scheduler" {
  name        = "policy"
  description = "Start and stop gitlab instance automatically"

  service_account {
    email  = data.google_client_openid_userinfo.terraform_service_account.email # "github-actions-service-account@i-need-my-belt.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
  instance_schedule_policy {
    vm_start_schedule {
      schedule = "45 7 * * 1-5"
    }
    vm_stop_schedule {
      schedule = "30 18 * * 0-6"
    }
    time_zone = "Europe/Paris"
  }
}

resource "google_compute_address" "static_ip" {
  name = "debian-vm"
}

output "static_ip" {
  value = google_compute_address.static_ip.address
}

resource "google_compute_network" "default" {
  name = "test-network"
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "22", "1000-2000"]
  }

  source_tags   = ["web"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "default" {
  name         = "i-need-my-belt-gitlab-instance"
  machine_type = "e2-micro"
  zone         = "us-west1-a"

  resource_policies = [
    google_compute_resource_policy.gitlab-instance-scheduler.id
  ]

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2210-kinetic-amd64-v20230126"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  service_account {
    email  = data.google_client_openid_userinfo.terraform_service_account.email # "github-actions-service-account@i-need-my-belt.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "${local.ssh_user_name}:${local.ssh_pub_key_without_new_line} ${local.ssh_user_name}"
  }

  provisioner "file" {
    source      = "./docker-compose.yml"
    destination = "/tmp/docker-compose.yml"
    connection {
      type        = "ssh"
      user        = local.ssh_user_name # gcp user
      host        = google_compute_address.static_ip.address
      timeout     = "500s"
      private_key = local.ssh_private_key
    }
  }

  metadata_startup_script = file("./install_docker.sh")
}

