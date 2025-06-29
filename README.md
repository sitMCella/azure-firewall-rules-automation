# Azure Firewall Policy Rule Update Automation

## Table of contents

* [Introduction](#introduction)
* [Requirements](#requirements)
* [GitHub Repository](#github-repository)
* [Terraform](#terraform)

## Introduction

The following project provisions an Azure Function App that updates the rules defined in one Azure Firewall Policy with a list of updated IP Address Ranges published by an IP Address Range Repository.

The Azure Function App does not update the Azure Firewall Policy resource, instead creates a Pull Request in the Git Repository that contains the Terraform code of the Azure Firewall Policy.

The Azure Function is configured with an example IP Address Range Repository "Azure IP Ranges and Service Tags – Public Cloud": https://www.microsoft.com/en-us/download/details.aspx?id=56519. The IP address ranges are extracted from the service tag feed downloadable file.

## Requirements

- Terraform

## GitHub Repository

Create a GitHub repository and push in the main branch the content of the directory "repository".

Generate a Fine-grained PAT Token in the GitHub account.

The Fine-grained token must be configured with the following Repository permissions:
- Read access to metadata
- Read and Write access to code (Contents), pull requests, and workflows

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

The variable "github_personal_access_token" corresponds to the GitHub PAT Token created in the previous step.

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
