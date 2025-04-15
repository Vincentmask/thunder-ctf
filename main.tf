# ─────────────────────────────────────────────────────────────
# Terraform configuration: Define required providers
# Ensures the correct Google provider is installed
# ─────────────────────────────────────────────────────────────
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.28"  # Lock to a known working version
    }
  }
}

# ─────────────────────────────────────────────────────────────
# Provider configuration: Sets the project and region to use
# ─────────────────────────────────────────────────────────────
provider "google" {
  project = var.project_id
  region  = var.region
}

# ─────────────────────────────────────────────────────────────
# Lookup the current project (used for IAM and metadata)
# ─────────────────────────────────────────────────────────────
data "google_project" "current" {}

# ─────────────────────────────────────────────────────────────
# Enable the Service Usage API first (required to enable other APIs)
# ─────────────────────────────────────────────────────────────
resource "google_project_service" "serviceusage" {
  service = "serviceusage.googleapis.com"
}

# ─────────────────────────────────────────────────────────────
# Enable all core APIs required for Thunder CTF functionality
# Depends on the Service Usage API being enabled first
# ─────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────
# Grant the Deployment Manager service account full owner role
# This is necessary if you're transitioning from or integrating with DM
# ─────────────────────────────────────────────────────────────
resource "google_project_iam_member" "deployment_manager_owner" {
  project = data.google_project.current.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${data.google_project.current.number}@cloudservices.gserviceaccount.com"
}

# ─────────────────────────────────────────────────────────────
# Create a firewall rule to allow HTTP traffic (port 80)
# Typically used for VM-based challenges or services
# ─────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────
# Create an App Engine application (required for Firestore and more)
# ─────────────────────────────────────────────────────────────
resource "google_app_engine_application" "default" {
  project     = var.project_id
  location_id = var.region
  depends_on  = [google_project_service.core]
}

# ─────────────────────────────────────────────────────────────
# Enable audit logging for selected services to track access and changes
# Includes Admin, Read, and Write logs for each service
# ─────────────────────────────────────────────────────────────
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

# ─────────────────────────────────────────────────────────────
# Deploy Level Module: a1openbucket
# ─────────────────────────────────────────────────────────────
# module "a1openbucket" {
#   source     = "./modules/a1openbucket"
#   project_id = var.project_id
# }

# output "a1openbucket_level_instructions" {
#   value = module.a1openbucket.level_instructions
# }

# # ─────────────────────────────────────────────────────────────
# # Deploy Level Module: a2finance
# # ─────────────────────────────────────────────────────────────
# module "a2finance" {
#   source              = "./modules/a2finance"
#   project_id          = var.project_id
#   region              = var.region
#   zone                = var.zone
#   ssh_username        = var.ssh_username
# }

# output "a2finance_level_instructions" {
#   value = module.a2finance.level_instructions
# }

# output "a2_bucket_name" {
#   value = module.a2finance.a2_bucket_name
# }