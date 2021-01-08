# Terraform Budget GCP

These modules create infrastructure on the Google Cloud Platform (GCP) that can be run for less than **10$** a month.( *YMMV*)
This repo contains instructions on how to actually create these resources.
Read the [companion article](../../../budget-gcp) to understand what choices were made to cut costs.

It guides on how to create all the resources plus pre-requisites from scratch.  
Resources created  include;

- A Domain Name using Freenom
- A GCP Organization
- A GCP Seed Project from which other projects will be created.
- A GCP Project for our resources.
- A GKE Private Cluster.
- A Google Container Instance running Traefik.
- A Google CloudRun Service running Vault.


## Compatibility

 This module is meant for use with Terraform 0.12. 

## Requirements
* A Domain Name.
* A Google Cloud Platform Account.
* A Valid Debit or Credit Card to enable billing.
---
## Setup
### Pre-Requisites
You need the following before you can proceed. Skip if you already have these.  
**1. Get a Domain Name**
<details>
  <summary>Click to expand</summary>
 
 #### Step 1  
1. Visit [https://www.freenom.com](https://www.freenom.com).  
2. Search for a domain you like and click **Check Availability.  
3. If the domain name is available click **Get it now!** and then click **Checkout.  
4. Set the period to 12 months. Then click **Continue**.  
5. Check **I have read and agree to the Terms & Conditions**. Then click **Complete Order**.  
6. Provide your email and set up a password.
6. You will receive an email notification to complete your order.
7. Click on the confirmation link in the email and login in to the dashboard to manage your registered domain.
#### Step 2
1. Visit [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up).
2. Click **Add a site** in Account Dashboard.
3. Type in your domain and click **Add site**.
4. Select the Free Plan and click **Confirm plan**.
5. Cloudflare will scan for existing DNS records. Wait until it finishes, and click **Continue**.  
6. Cloudflare will give you two nameservers to set up in Freenom.
#### Step 3
1. Go back to Freenom, Click **Services** > **My Domains**. Click **Manage Domain** on the domain that you’re configuring.
2. Click **Management Tools** > **Nameservers** > **Use custom nameservers** (enter below). Now enter the nameservers provided by Cloudflare, and click **Change Nameservers**.
3. Go back to Cloudflare, click **Done**, **check nameservers**. It may take a while, you will receive an email once your domain has been added.
4. Click **Profile** > **API Tokens** > **Create Token**
5. On **Edit zone DNS**, Click **Use Template** > Under **Zone Resources** > Select your domain
6. Click **Continue To Summary** > **Create Token** then copy and save the created token.

#### [Reference](https://dev.to/hieplpvip/get-a-free-domain-with-freenom-and-cloudflare-k1j)
</details>

**2. Sign up for a GCP Account**
<details>
  <summary>Click to expand</summary>
1. Visit [https://console.cloud.google.com/freetrial/signup](https://console.cloud.google.com/freetrial/signup) to create your account.
</details>

**3. Create an Organization in GCP**
<details>
  <summary>Click to expand!</summary>
TODO
</details>

**4. Create an Oauth2 Client in GCP**
<details>
  <summary>Click to expand!</summary>
TODO
</details>

---

### Create the GCP Seed Project

Create a file `terraform.tfvars` with the following content from the steps completed above;

```
org_id                  = "<ORGANIZATION_ID>"

billing_account         = "<BILLING_ACCOUNT_ID>"

group_org_admins        = "<admin@domain>"

group_billing_admins    = "<billing@domain>"

default_region          = "us-central1"

sa_enable_impersonation = true

```

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/nufailtd/terraform-budget-gcp&open_in_editor=seed_project/terraform.tfvars)

Then perform the following commands on the seed_project folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
#### File structure
This module has the following folders and files:
```
- /seed_project/: root folder
- /seed_project/main.tf: main file for this module, creates the project's resources
- /seed_project/tfvars.example: an example of a file to generate terraform.tfvars
- /seed_project/variables.tf: all the variables for the module
- /seed_project/output.tf: the outputs of the module
- /seed_project/README.md: information about the module
```
---
### Create the GCP Project
Create a file `terraform.tfvars` with the following content;

```
org_id                      = "<ORGANIZATION_ID>"
billing_account             = "<BILLING_ACCOUNT_ID>"
group_org_admins            = "<admin@domain>"
impersonate_service_account = "<seed_project service account>"
name                        = "<project_name>"
bucket_project              = "<project_bucket_name>"
default_region              = "us-central1"
```

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/nufailtd/terraform-budget-gcp&open_in_editor=budget_gcp_project/terraform.tfvars)

Then perform the following commands in the budget_gcp_project folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
#### File structure
This module has the following folders and files:
```
- /budget_gcp_project/: root folder
- /budget_gcp_project/main.tf: main file for this module, creates the project's resources
- /budget_gcp_project/tfvars.example: an example of a file to generate terraform.tfvars
- /budget_gcp_project/variables.tf: all the variables for the module
- /budget_gcp_project/output.tf: the outputs of the module
- /budget_gcp_project/README.md: information about the module
```
---
### Create resources in the GCP Project
Create a file `terraform.tfvars` with the following content;

```
project_id       = "<project_name>"
region           = "us-central1"
zones            = ["us-central1-a"]
cluster_name     = "kluster"
domain           = "<your domain>"
domain_filter    = "<your domain>"
run_post_install = false
email            = "<your email>"
dns_auth              = [
    {
      name = "provider"
      value = "google"
     }
  ]
# OIDC Configuration
oidc_config           = [
    {
      name = "authenticate.idp.provider"
      value = "google"
     },
    {
      name = "authenticate.idp.clientID"
      value = "[project_id]-[hash].apps.googleusercontent.com"
    },
    {
      name = "authenticate.idp.clientSecret"
      value = "mysecret"
    }
  ]
```

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/nufailtd/terraform-budget-gcp&open_in_editor=terraform.tfvars)

Then perform the following commands on the kluster_project folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build

**Important!!**
Once completed modify `terraform.tfvars` and set
```
run_post_install = true
```
Then perform the following commands:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
We do this in 2 steps because of some limitations in terraform that will cause an error if certain resources do not exist.

To delete the projects and stop charges accruing to your account run

- `terraform destroy` to destroy the built infrastructure
#### File structure
The project has the following folders and files:
```
- /: root folder
- /modules/cert/: - creates certificated for our domain.
- /modules/cloud-run/: creates a ghost blog cloudrun service
- /modules/custom-nat/: creates an internet gateway for our private cluster
- /modules/dns/: creates domain records for our domain name
- /modules/kubeip/: assigns a static IP to instances in our cluster *not used*
- /modules/pomerium-app/: secures our applications to provide access to from allowed users only
- /modules/test-workload-identity/: tests the google workload identity feature
- /modules/traefik-sa/: creates a kubernetes service account used by traefik-vm
- /modules/traefik-vm/: creates an instance with a public ip to route traffic to our cluster
- /modules/vault-cloud-run/: creates a vault application running in cloudrun
- /modules/vault-sa/: creates a kubernetes service account to be used by the vault application
- /modules/workload-identity/: allows us to access google apis without requiring us to save key files
- /tfvars.example: an example of a file to generate terraform.tfvars
- /variables.tf: variables used by our main.tf file
- /main.tf/: creates gke cluster and the rest of the modules
- /outputs.tf: displays created resources
- /README.md: this file
```
---
