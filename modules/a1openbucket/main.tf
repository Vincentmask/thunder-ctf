variable "project_id" {
  type = string
}


resource "random_id" "nonce" {
  byte_length = 4
}


resource "google_storage_bucket" "bucket" {
  name     = "a1-bucket-${random_id.nonce.hex}"
  location = "US"
  project  = var.project_id
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_iam_binding" "public_read" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    "allUsers",
  ]
}

resource "google_storage_bucket_object" "secret_txt" {
  name    = "secret.txt"
  bucket  = google_storage_bucket.bucket.name
  content = "The answer to life, the universe, and everything: 42\n"
}

output "bucket_name" {
  value = google_storage_bucket.bucket.name
}

output "level_instructions" {
  value = "The secret for this level can be found in the Google Cloud Storage (GCS) bucket ${google_storage_bucket.bucket.name}\n"
}

output "secret_value" {
  value       = google_storage_bucket_object.secret_txt.content
  sensitive   = false
  description = "This is the fun SSN-style secret"
}
