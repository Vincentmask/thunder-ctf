

variable "project_id" {
  type        = string
  description = "The GCP project ID to deploy Thunder CTF into"
}

variable "region" {
  type        = string
  default     = "us-central"
  description = "Region for App Engine and other regional resources"
}

