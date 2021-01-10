# Terraform Budget GCP

These modules create infrastructure on the Google Cloud Platform (GCP) that can be run for less than **10$** a month.( *[YMMV](https://nufailtd.github.io/budget-gcp/)* )
This repo contains instructions on how to actually create these resources.
Read the [companion article](https://nufailtd.github.io/budget-gcp/) to understand what choices were made to cut costs.

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
![Search Domain](./images/freenom/01-freenom-search-domain.png)
3. If the domain name is available click **Get it now!** and then click **Checkout. 
![Create Account](./images/freenom/02-freenom-checkout-domain.png) 
4. Set the period to 12 months. Then click **Continue**.  
5. Check **I have read and agree to the Terms & Conditions**. Then click **Complete Order**.  
6. Provide your email and set up a password.
![Provide email](./images/freenom/03-freenom-provide-email.png) 
7. You will receive an email notification to complete your order.
![Verify Email](./images/freenom/04-freenom-verify-email.png) 
8. Click on the confirmation link in the email and and provide your information to complete registration.
![Complete Setup](./images/freenom/05-freenom-complete.png) 
9. You should be able to view your registered domain
![Domain](./images/freenom/06-freenom-successful.png) 

 You **cannot** use cloudflare API if your domain is a 
`.cf, .ga, .gq, .ml, or .tk`  
**Skip** Steps 2 & 3 if you have any of these.

#### Step 2

1. Visit [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up).
2. Click **Add a site** in Account Dashboard.
3. Type in the domain you created above and click **Add site**.
4. Select the Free Plan and click **Confirm plan**.
5. Cloudflare will scan for existing DNS records. Wait until it finishes, and click **Continue**.  
6. Cloudflare will give you two nameservers to set up in Freenom.
#### Step 3
1. Go back to Freenom, Click **Services** > **My Domains**. Click **Manage Domain** on the domain that you’re configuring.
![Manage Domain](./images/freenom/07-freenom-manage-domain.png) 
2. Click **Management Tools** > **Nameservers** > **Use custom nameservers** (enter below). Now enter the nameservers provided by Cloudflare, and click **Change Nameservers**.
![Add Nameservers](./images/freenom/08-freenom-add-nameservers.png) 
3. Go back to Cloudflare, click **Done**, **check nameservers**. It may take a while, you will receive an email once your domain has been added.
4. Click **Profile** > **API Tokens** > **Create Token**
5. On **Edit zone DNS**, Click **Use Template** > Under **Zone Resources** > Select your domain
6. Click **Continue To Summary** > **Create Token** then copy and save the created token.

#### [Reference](https://dev.to/hieplpvip/get-a-free-domain-with-freenom-and-cloudflare-k1j)
</details>

**2. Sign up for a GCP Account**
<details>
  <summary>Click to expand</summary>

1. Visit [Google Cloud](https://console.cloud.google.com/freetrial/signup) to create your account.  
Provide the required information and you should be greeted with this page.

![Create Account](./images/google/00-gcp-welcome.png)

</details>



---

### Create the GCP Seed Project
**Please skip** this for now and return when/if you successfully create an organization.  
We are able to deploy our resources without it. 
<details>
  <summary>Click to show</summary>
Create a file `terraform.tfvars` with the following information from the organization you just created;

```
org_id                  = "<ORGANIZATION_ID>"

billing_account         = "<BILLING_ACCOUNT_ID>"

group_org_admins        = "<admin@domain.com>"

group_billing_admins    = "<billing@domain.com>"

default_region          = "us-central1"

sa_enable_impersonation = true
```

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/nufailtd/terraform-budget-gcp&open_in_editor=main.tf&cloudshell_workspace=seed_project)

Then perform the following commands on the seed_project folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build

</details>

---

### Create the GCP Project
Create a file `terraform.tfvars` with the following required variables;

```
email                       = "user@gmail.com"
billing_account             = " 02E280-9E2C47-1DF365"
name                        = "myproject"
```

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/nufailtd/terraform-budget-gcp&open_in_editor=main.tf&cloudshell_workspace=budget_gcp_project)

Then perform the following commands in the budget_gcp_project folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build

This operation will output the `project_id` to be used in the next steps.

Befor creating our resources it will be convenient to complete the following manual operations.  
This will help us automate the final step.

**Create an Oauth2 Client in GCP**
<details>
  <summary>Click to expand</summary>
  
1. Log in to your Google Cloud account and go to the [APIs & services](https://console.developers.google.com/projectselector/apis/credentials).
![Select Project](./images/google/01-oauth2-select-project.png)
 Navigate to **Consent** using the left-hand menu and select **External**
![Consent Screen](./images/google/02-oauth2-consent-screen.png)

2. Configure your **Oauth Consent Screen**  
Fill in "Application Name"  
Proceed to next page and under scopes make sure you select the following scopes **only**  
`openid, profile, email`  
![OAuth Consent Scopes ](./images/google/03-oauth2-add-scopes.png)
Add your email as a test user and complete.
![OAuth Consent Add Users](./images/google/04-oauth2-add-users.png)
A successful configuration should like below
![OAuth Consent Summary](./images/google/05-oauth2-summary.png)

3. Create New Credentials.  
On the **Credentials** page, click **Create credentials** and choose **OAuth [Client ID]**.
![Create New Credentials](./images/google/06-oauth2-create-credentials.png)

4. Configure Client ID  
On the **Create [Client ID]** page, select **Web application**.   
Under **Authorized redirect URIs**
set the following parameters substituting `domain.com` for domain you created above  
`https://authenticate.domain.com/oauth2/callback`  
`https://vault.domain.com//ui/vault/auth/oidc/oidc/callback`  
`https://authenticate.gc.domain.com/oauth2/callback`  
`https://vault.gc.domain.com//ui/vault/auth/oidc/oidc/callback`  
![Web App Credentials Configuration](./images/google/07-oauth2-configure-application.png)


5. Click **Create** to proceed. The [Client ID] and [Client Secret] settings will be displayed.  

Download the client_secret file to be used in a later configuration.
![Download Secret File](./images/google/08-oauth2-download-credentials.png)


</details>



**Create a zone in CloudDNS**
<details>
  <summary>Click to expand</summary>

  1. In your Google Cloud account go to [Net services](https://console.cloud.google.com/projectselector/net-services/dns/zones).
![Select Project](./images/dns/00-clouddns-select-project.png)
 Select the project created above then navigate to **Cloud DNS** using the left-hand menu and click **Create zone**
![Create Zone](./images/dns/01-clouddns-createzone.png)

2. Create New Zone.  
On the **Create a DNS Zone** page, enter a **Zone Name** (a nice approach is to replace the periods in your domain with a dash) then enter the domain you created above in **DNS name**.
![Enter Zone details](./images/dns/02-clouddns-createzone.png)

3. Get Nameservers.  
Nameservers in the format **ns-cloud-xx.googledomains.com** will be presented to you.  
 Take note of them as you will use them in the next step.
![Enter Zone details](./images/dns/03-clouddns-getnameservers.png)

</details>


**Update Nameservers in Freenom**
<details>
  <summary>Click to expand</summary>

1. Login to your Freenom account, Click **Services** > **My Domains**. Click **Manage Domain** on the domain that you’re configuring.
![Manage Domain](./images/freenom/07-freenom-manage-domain.png) 
2. Click **Management Tools** > **Nameservers** > **Use custom nameservers** (enter below). Now enter the nameservers from CloudDNS, and click **Change Nameservers**.
![Update Nameservers](./images/dns/04-freenom-updatenameservers.png)

 3. Confirm the nameservers have been set successfully.
![Create Zone](./images/dns/05-freenom-confirm.png)


</details>


---
### Create resources in the GCP Project
The variables for this step are derived from the previous steps, namely:
- `oauth2 ClientID`
- `oauth2 ClientSecret`
- `cloudflare Token`
- `domain`
- `project_id`

Create a file `terraform.tfvars` with the following content;

```
project_id       = "<project_name>"
region           = "us-central1"
zones            = ["us-central1-a"]
cluster_name     = "kluster"
domain           = "gc.<your domain>"
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

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/nufailtd/terraform-budget-gcp&open_in_editor=main.tf)

Then perform the following commands:

It is recommended to run this before performing the subsequent commands.  
This ensures that you use the project's service account to create resources. 
The token expires every hour so you'll have to re-issue these commands if you get an error.
 ```
 gcloud config set project [ YOUR_PROJECT_ID ]
 gcloud config set auth/impersonate_service_account project-service-account@[ YOUR_PROJECT_ID ].iam.gserviceaccount.com`
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
```

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
- `terraform apply --auto-approve` to apply the infrastructure build
We do this in 2 steps because of some limitations in terraform that will cause an error if certain resources do not exist.

To delete the projects and stop charges accruing to your account run

- `terraform destroy --auto-approve` to destroy the built infrastructure
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
