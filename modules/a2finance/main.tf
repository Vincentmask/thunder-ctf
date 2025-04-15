
resource "random_id" "nonce" {
  byte_length = 4
}

# Bucket for leaked Git repo
resource "google_storage_bucket" "leak_bucket" {
  name                        = "a2-bucket-${random_id.nonce.hex}"
  location                    = "US"
  project                     = var.project_id
  force_destroy               = true
  uniform_bucket_level_access = true
}

# VM with fluentd agent
resource "google_compute_instance" "logging_instance" {
  name         = "a2-logging-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  metadata = {
    startup-script = file("${path.module}/startup.sh")
  }

  network_interface {
    network       = "default"
    access_config {}
  }

  tags = ["http-server"]
}

# Compromised service account
resource "google_service_account" "a2finance_sa" {
  account_id   = "a2-access"
  display_name = "Compromised service account for a2finance"
}

# Custom role: replicates DM setup
resource "google_project_iam_custom_role" "a2_custom_viewer" {
  role_id     = "a2CustomViewer"
  title       = "A2Finance Custom Role"
  description = "Mimics original DM YAML permissions"
  project     = var.project_id

  permissions = [
    "compute.instances.get",
    "compute.instances.list",
    "compute.zones.list",
    "compute.zones.get",
    "storage.buckets.list",
    "storage.objects.list",
    "storage.objects.get"
  ]
}

# Bind custom role to the a2 service account
resource "google_project_iam_member" "assign_custom" {
  project = var.project_id
  role    = google_project_iam_custom_role.a2_custom_viewer.name
  member  = "serviceAccount:${google_service_account.a2finance_sa.email}"
}

# Assign logging.viewer to the VM’s default SA so it can log
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

resource "google_project_iam_member" "vm_logging_viewer" {
  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}


# Service account key to leak
resource "google_service_account_key" "a2finance_key" {
  service_account_id = google_service_account.a2finance_sa.name
}

resource "local_file" "service_account_key_file" {
  content  = base64decode(google_service_account_key.a2finance_key.private_key)
  filename = "${path.root}/start/a2-access.json"
}

# Outputs
output "a2_bucket_name" {
  value = google_storage_bucket.leak_bucket.name
}

output "a2_vm_ip" {
  value = google_compute_instance.logging_instance.network_interface[0].access_config[0].nat_ip
}

output "a2_service_account_email" {
  value = google_service_account.a2finance_sa.email
}

output "level_instructions" {
  value = "place holder for level2\n"
}


resource "null_resource" "track_active_level" {
  provisioner "local-exec" {
    command = "mkdir -p config && echo a2finance > config/active_level.txt"
  }

  triggers = {
    always_run = timestamp()
  }
}

