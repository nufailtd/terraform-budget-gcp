
variable "group_org_admins" {
  description = "Google Group for GCP Organization Administrators"
  type        = string
  default     = ""
}

variable "org_id" {
  description = "GCP Organization ID"
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "The ID of the billing account to associate projects with."
  type        = string
  default     = ""
}

variable "group_billing_admins" {
  description = "Google Group for GCP Billing Administrators"
  type        = string
  default     = ""
}

variable "default_region" {
  description = "Default region to create resources where applicable."
  type        = string
  default     = "us-central1"
}

variable "additional_roles" {
  description = "Additional roles for the service account"
  type        = list
  default = [
    "roles/iam.roleAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountTokenCreator",
    "roles/iam.serviceAccountUser",
    "roles/cloudkms.admin",
    "roles/container.admin",
    "roles/run.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/pubsub.editor",
    "roles/cloudscheduler.admin",
    "roles/storage.admin",
    "roles/cloudfunctions.admin",
    "roles/appengine.appAdmin",
    "roles/appengine.appCreator",
    "roles/secretmanager.admin",
  ]
}