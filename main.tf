
module "setup" {
  source     = "./modules/setup"
  project_id = var.project_id
  region     = var.region
}

output "setup_instructions" {
  value = module.setup.level_instructions
}

# ─────────────────────────────────────────────────────────────
# Deploy Level Module: a1openbucket
# ─────────────────────────────────────────────────────────────
module "a1openbucket" {
  source     = "./modules/a1openbucket"
  project_id = var.project_id
}


# ─────────────────────────────────────────────────────────────
# Deploy Level Module: a2finance
# ─────────────────────────────────────────────────────────────
module "a2finance" {
  source              = "./modules/a2finance"
  project_id          = var.project_id
  region              = var.region
  zone                = var.zone
  ssh_username        = var.ssh_username
}

output "a2finance_level_instructions" {
  value = module.a2finance.level_instructions
}

output "a2_bucket_name" {
  value = module.a2finance.a2_bucket_name
}


module "a3password" {
  source     = "./modules/a3password"
  project_id = var.project_id
  region     = var.region
  zone       = var.zone

  level_secret = var.level_secret
}

module "a4error" {
  source       = "./modules/a4error"
  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  level_secret = var.level_secret
}
