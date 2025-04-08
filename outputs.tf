output "bucket_name" {
  value       = module.a1openbucket.bucket_name
  description = "The name of the bucket for the current level"
}

output "level_instructions" {
  value       = module.a1openbucket.level_instructions
  description = "Instructions for the current level"
}

output "secret_value" {
  value     = module.a1openbucket.secret_value
  sensitive = true
}