
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

# variable "gce_ssh_user" {}
# variable "gce_ssh_pub_key_file" {}

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
    ports    = ["80", "8080", "22" ,"1000-2000"]
  }

  source_tags = ["web"]
  source_ranges = [ "0.0.0.0/0" ]
}



# resource "google_compute_address" "gitlab-static-ip-address" {
#   name = "gitlab-static-ip-address"
# }


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

  metadata = {
    #ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
    #ssh-keys = "ubuntu:${file("ubuntu.pub")}"
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "file" {
    source      = "./docker-compose.yml"
    destination = "/tmp/files/docker-compose.yml"
    connection {
      type    = "ssh"
      user    = "ubuntu"
      host    = self.network_interface.0.access_config.0.nat_ip
      timeout = "500s"
      private_key = "${file("~/.ssh/authorized_keys")}"
      # private_key = "${file("~/.ssh/google_compute_engine")}"
    }
  }
  

  metadata_startup_script = file("./install_docker.sh")
}
