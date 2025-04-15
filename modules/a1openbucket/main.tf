# ─────────────────────────────────────────────────────────────
# Input variable: GCP Project ID where the resources will be deployed
# ─────────────────────────────────────────────────────────────
variable "project_id" {
  type = string
}

# ─────────────────────────────────────────────────────────────
# Generate a random 4-byte (8-character hex) suffix for uniqueness
# Used to avoid bucket name collisions
# ─────────────────────────────────────────────────────────────
resource "random_id" "nonce" {
  byte_length = 4
}

# ─────────────────────────────────────────────────────────────
# Create a GCS bucket with a unique name
# Uses random nonce to ensure no naming conflict
# ─────────────────────────────────────────────────────────────
resource "google_storage_bucket" "bucket" {
  name     = "a1-bucket-${random_id.nonce.hex}"
  location = "US"
  project  = var.project_id

  # Enforce uniform access — disables fine-grained ACLs
  uniform_bucket_level_access = true
}

# ─────────────────────────────────────────────────────────────
# Make the bucket publicly readable by assigning the storage.objectViewer role to "allUsers"
# ─────────────────────────────────────────────────────────────
resource "google_storage_bucket_iam_binding" "public_read" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    "allUsers",
  ]
}

# ─────────────────────────────────────────────────────────────
# Upload the secret file (secret.txt) to the public bucket
# Content can be customized per level — currently a fun quote
# ─────────────────────────────────────────────────────────────
resource "google_storage_bucket_object" "secret_txt" {
  name    = "secret.txt"
  bucket  = google_storage_bucket.bucket.name

  # The actual secret content
  content = "The answer to life, the universe, and everything: 42\n"
}

# ─────────────────────────────────────────────────────────────
# Output the bucket name so it can be accessed or displayed externally
# ─────────────────────────────────────────────────────────────
output "a1_bucket_name" {
  value = google_storage_bucket.bucket.name
}

# ─────────────────────────────────────────────────────────────
# Output a user instruction string, written with a newline for display formatting
# ─────────────────────────────────────────────────────────────
output "level_instructions" {
  value = "The secret for this level can be found in the Google Cloud Storage (GCS) bucket ${google_storage_bucket.bucket.name}\n"
}


# ─────────────────────────────────────────────────────────────
# Track the active level deployment by writing to a local file
# This file is later used by destroy scripts to determine what to clean up
# ─────────────────────────────────────────────────────────────
resource "null_resource" "track_active_level" {
  provisioner "local-exec" {
    # Write the module name to active_level.txt after deployment
    command = "mkdir -p config && echo a1openbucket > config/active_level.txt"
  }

  # Always trigger this resource so it's updated every time
  triggers = {
    always_run = timestamp()
  }
}
