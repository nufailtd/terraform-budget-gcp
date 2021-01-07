module "bootstrap" {
  source  = "terraform-google-modules/bootstrap/google"
  version = "~> 1.7"

  org_id               = var.org_id
  billing_account      = var.billing_account
  group_org_admins     = var.group_org_admins
  group_billing_admins = var.group_billing_admins
  default_region       = var.default_region
}