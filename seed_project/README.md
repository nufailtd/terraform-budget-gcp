# Create a GCP Seed Project
Create a seed project in an organization to manage creation of other projects using terraform.  

You will most likely **not** need to run this.  
Use the `budget_gcp_project` instead.  
This module requires you to have previously set up an organization through;
1. [Google Workspace](https://workspace.google.com/) - Not Free
2. [Cloud Identity](https://cloud.google.com/identity/docs/overview) - Free Plan available

both of which are quite involving for our purposes.  
However, if you are able to set it up;
Create a `terraform.tfvars` in this directory and add  the following required variables;

```
org_id                  = "<ORGANIZATION_ID>"

billing_account         = "<BILLING_ACCOUNT>"

group_org_admins        = "admin@domain.com"

group_billing_admins    = "billing@domain.com"

default_region          = "us-central1"

sa_enable_impersonation = true
```
The above values are just examples, use your own.  
If you encounter an error, you will need to change the name.
You **must** have all these variables available to you or the next operations will fail.  


Run the following commands

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply --auto-approve` to apply the infrastructure build

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