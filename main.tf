terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.28"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "current" {}

# Enable Service Usage first
resource "google_project_service" "serviceusage" {
  service = "serviceusage.googleapis.com"
}

# Enable required APIs
resource "google_project_service" "core" {
  for_each = toset([
    "cloudapis.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "datastore.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "deploymentmanager.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "appengine.googleapis.com",
    "vision.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  service    = each.key
  depends_on = [google_project_service.serviceusage]
}

# Grant Deployment Manager service account owner role
resource "google_project_iam_member" "deployment_manager_owner" {
  project = data.google_project.current.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${data.google_project.current.number}@cloudservices.gserviceaccount.com"
}

# Add default-allow-http firewall rule
resource "google_compute_firewall" "default_allow_http" {
  name    = "default-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# App Engine (required for Firestore)
resource "google_app_engine_application" "default" {
  project     = var.project_id
  location_id = var.region
  depends_on  = [google_project_service.core]
}

# Enable audit logs for selected services
locals {
  audit_services = [
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com"
  ]
}

resource "google_project_iam_audit_config" "audit_logs" {
  for_each = toset(local.audit_services)

  project = var.project_id
  service = each.value

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

module "a1openbucket" {
  source     = "./modules/a1openbucket"
  project_id = var.project_id
}