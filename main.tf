terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.25.0"
    }
  }
}

provider "google" {
  # Configuration options
  region = "us-central1"

  # enter project name
  #     e.g., "my-project-####"
  project = "terra-dome-420900"

  # enter project's key
  #     e.g., "my-project-####-####.json"
  credentials = "terra-dome-420900-6642f8c08c0c.json"
}

resource "google_service_account" "service_account" {
  account_id   = "custom-vm-sa"
  display_name = "VM Service Account"
}

## VPC Setup
module "vpc_network" {
  source         = "./modules/vpc_network"
  vpc_name       = "funky-finger-prod-net"
  enable_subnets = false
}

# Get VPC Network ID(s)
data "google_compute_network" "vpc_info" {
  name       = "funky-finger-prod-net"
  depends_on = [module.vpc_network]
}

# Create Subnets
module "vpc_subnet" {
  source                   = "./modules/vpc_subnet"
  name                     = "funky-finger-prod-net" 
  network_id               = data.google_compute_network.vpc_info.id
  ip_cidr_range            = "10.106.1.0/24" 
  region                   = "us-central1" 
  private_ip_google_access = true
  depends_on               = [module.vpc_network]
}

# Get Subnet ID(s)
data "google_compute_subnetwork" "subnet_info" {
  name       = "funky-finger-prod-net-sub-sg" 
  depends_on = [module.vpc_subnet]
}

# Create Firewall Rules
resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = data.google_compute_network.vpc_info.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [22, 80, 3389]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Get Debian 12 image
data "google_compute_image" "debian-12" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  tags = ["net", "worth"]

  boot_disk {
  
    # add Debian 12 image to boot disk
    initialize_params {
      image = data.google_compute_image.debian-12.self_link
      size  = 10
      type = "pd-balanced"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnet_info.id
    access_config {
      // Ephemeral public IP
      network_tier = "STANDARD"
    }
  }

  metadata = {
    startup-script = file("startup_script.sh")
    }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }
  depends_on = [module.vpc_subnet, module.vpc_network]
}

 output "Task_2" {
  value = "Solutions."
}

 output "_1_public_ip" {
  value = format("http://%s", google_compute_instance.default.network_interface[0].access_config[0].nat_ip)
}

output "_2_vpc" {
  value = google_compute_instance.default.network_interface[0].network
}

output "_3_subnet" {
  value = google_compute_instance.default.network_interface[0].subnetwork
}

output "_4_internal_ip" {
  value = google_compute_instance.default.network_interface[0].network_ip
}