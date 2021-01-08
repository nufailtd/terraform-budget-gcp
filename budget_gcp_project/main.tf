module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 9.2"

  name                              = var.name
  impersonate_service_account       = var.impersonate_service_account
  bucket_project                    = var.name
  billing_account                   = var.billing_account
  org_id                            = var.org_id
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
  member             = var.org_id == "" ? "user:${var.email}" : "group:${var.group_org_admins}"
}


resource "google_project_iam_member" "grant_roles_to_sa" {
  for_each = toset(var.additional_roles)

  project = module.project-factory.project_id
  role    = each.value
  member  = "serviceAccount:${module.project-factory.service_account_email}"
}
