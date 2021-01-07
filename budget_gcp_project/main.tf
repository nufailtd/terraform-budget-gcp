data "terraform_remote_state" "seed" {
  backend = "local"

  config = {
    path = "${path.module}/../seed_project/terraform.tfstate"
  }
}


module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.2"

  name                              = "vault-gc"
  impersonate_service_account       = data.terraform_remote_state.seed.outputs.terraform_sa_email
  bucket_project                    = "vault-gc"
  billing_account                   = data.terraform_remote_state.seed.outputs.billing_account
  org_id                            = data.terraform_remote_state.seed.outputs.org_id
  default_service_account           = "disable"
  sa_role                           = "roles/editor"
  use_tf_google_credentials_env_var = false

  activate_apis = [
    "serviceusage.googleapis.com",
    "servicenetworking.googleapis.com",
    "compute.googleapis.com",
    "logging.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "iam.googleapis.com",
    "admin.googleapis.com",
    "appengine.googleapis.com",
    "storage-api.googleapis.com",
    "monitoring.googleapis.com",
    "cloudkms.googleapis.com",
    "run.googleapis.com",
    "container.googleapis.com",
    "cloudbuild.googleapis.com",
    "sourcerepo.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "iap.googleapis.com",
    "dns.googleapis.com",
    "identitytoolkit.googleapis.com",
    "secretmanager.googleapis.com",
  ]

  activate_api_identities = [
    {
      api   = "container.googleapis.com"
      roles = ["roles/cloudkms.cryptoKeyEncrypterDecrypter", "roles/container.serviceAgent"]
    },
  ]

}

resource "google_app_engine_application" "app" {
  project     = module.project-factory.project_id
  location_id = "us-central"
}

resource "google_service_account_iam_member" "org_admin_sa_impersonate_permissions" {

  service_account_id = module.project-factory.service_account_name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "group:${var.group_org_admins}"
}

resource "google_project_iam_member" "grant_roles_to_sa" {
  for_each = toset(var.additional_roles)

  project = module.project-factory.project_id
  role    = each.value
  member  = "serviceAccount:${module.project-factory.service_account_email}"
}
