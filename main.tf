terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

provider "google" {
  credentials = file("t2-plan-svc-acc.json")
  project     = "t2-plan"
  region      = "us-central1"
  zone        = "us-central1-a"
}

resource "google_compute_network" "vpc_network" {
  name                    = "practice-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private-subnet" {
  name          = "private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.name
}

resource "google_compute_router" "router" {
  project = "t2-plan"
  name    = "my-router"
  region  = google_compute_subnetwork.private-subnet.region
  network = google_compute_network.vpc_network.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

}

resource "google_compute_instance" "my_vm" {
  project      = "t2-plan"
  zone         = "us-central1-a"
  name         = "private-vm-nat-demo"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.private-subnet.name
  }
}

resource "google_compute_firewall" "rules" {
  project = "t2-plan"
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}




resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.name
}

resource "google_compute_instance" "my_vm1" {
  project      = "t2-plan"
  zone         = "us-central1-a"
  name         = "public-vm"
  machine_type = "e2-micro"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // this provides an external ip for vm
    }
  }
}
