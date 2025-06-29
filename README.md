# Azure Firewall Policy Rule Update Automation

## Introduction

The following project configures an Azure Function to update the rules in one Azure Firewall Policy from the list of IP Address Ranges published by an IP Address Range Repository.

The Azure Function does not update the Azure Firewall Policy resource, instead creates a Pull Request in the Git Repository that contains the Terraform code of the Azure Firewall Policy.

The project makes use of the IP Address Range Repository "Azure IP Ranges and Service Tags – Public Cloud": https://www.microsoft.com/en-us/download/details.aspx?id=56519.

## GitHub Repository

Create a GitHub repository and push in the main branch the content of the directory "repository".

## Terraform

### Configuration

Assign the RBAC roles "Contributor", "User Access Administrator" to the User account on the Subscription level.

Create the file `terraform.tfvars` with the values for the following Terraform variables:

```sh
location="<azure_region>" # e.g. "westeurope"
location_abbreviation="<azure_region_abbreviation>" # e.g. "weu"
environment="<environment_name>" # e.g. "test"
workload_name="<workload_name>"
github_repository_owner="<GitHub_repository_owner>"
github_repository_name="<GitHub_repository_name>"
github_personal_access_token="<GitHub_PAT_Token>"
```

Before proceeding with the next sections, open a terminal and login in Azure with Azure CLI using the User account.

The variable "github_repository_name" corresponds to the name of the GitHub Repository created in the previous step.

The variable "github_repository_owner" corresponds to the name of the GitHub account that owns the GitHub Repository.

Generate a Fine-grained PAT Token in the GitHub account and assign the value to the variable "github_personal_access_token".

The Fine-grained token must be configured with the following Repositoy permissions:
- Read access to metadata
- Read and Write access to code (Contents), pull requests, and workflows

### Terraform Project Initialization

```sh
terraform init -reconfigure
```

### Verify the Updates in the Terraform Code

```sh
terraform plan
```

### Apply the Updates from the Terraform Code

```sh
terraform apply -auto-approve
```

### Format Terraform Code

```sh
find . -not -path "*/.terraform/*" -type f -name '*.tf' -print | uniq | xargs -n1 terraform fmt
```
