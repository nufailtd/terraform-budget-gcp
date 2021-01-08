# Create a Budget GCP Project
Create a project to host our infrastructure.  

[![Open this project in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://github.com/nufailtd/terraform-budget-gcp&open_in_editor=main.tf&cloudshell_workspace=budget_gcp_project)

Get your billing account by running  
`gcloud beta billing accounts list`
```
user@cloudshell:~$ gcloud beta billing accounts list
ACCOUNT_ID            NAME                OPEN  MASTER_ACCOUNT_ID
02E280-9E2C47-1DF365  My Billing Account  True
```
Create a `terraform.tfvars` in this directory and add  the following required variables;

```
email                       = "user@gmail.com"
billing_account             = " 02E280-9E2C47-1DF365"
name                        = "myproject"
```
The above values are just examples, use your own.  
If you encounter an error, you will need to change the name.
Do **not** set any optional variables if you do not have them.  
Run the following commands

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build  
Example output
```
Apply complete! Resources: 56 added, 0 changed, 0 destroyed.

Outputs:

billing_account = 02E280-9E2C47-1DF365
org_id = 
project_bucket_url = [
  "gs://myproject-state",
]
project_id = myproject
project_name = myproject
project_number = 1039118523779
service_account_email = project-service-account@myproject.iam.gserviceaccount.com
service_account_id = project-service-account
service_account_name = projects/myproject/serviceAccounts/project-service-account@myproject.iam.gserviceaccount.com
```


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