output "project_name" {
  value = module.project-factory.project_name
}

output "project_id" {
  value = module.project-factory.project_id
}

output "project_number" {
  value = module.project-factory.project_number
}

output "service_account_email" {
  value       = module.project-factory.service_account_email
  description = "The email of the default service account"
}

output "service_account_name" {
  value       = module.project-factory.service_account_name
  description = "The fully-qualified name of the default service account"
}

output "service_account_id" {
  value       = module.project-factory.service_account_id
  description = "The id of the default service account"
}

output "project_bucket_url" {
  value       = module.project-factory.project_bucket_url
  description = "Project's bucket url"
}

output "org_id" {
  description = "Project's organization id."
  value       = data.terraform_remote_state.seed.outputs.org_id
}

output "billing_account" {
  description = "Project billing account."
  value       = data.terraform_remote_state.seed.outputs.billing_account
}
