
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

# An example resource that does nothing.
resource "google_compute_instance" "default" {
  name         = "i-need-my-belt-gitlab-instance"
  machine_type = "e2-micro"
  zone         = "us-west1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2210-kinetic-amd64-v20230126"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = "github-actions-service-account@i-need-my-belt.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = file("./install_docker.sh")

  provisioner "file" {
    source      = "./docker-compose.yml"
    destination = "/docker-compose.yml"
  }
}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000"]
  }

  source_tags = ["web"]
}

resource "google_compute_network" "default" {
  name = "test-network"
}