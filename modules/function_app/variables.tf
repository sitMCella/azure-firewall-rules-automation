variable "resource_group_name" {
  description = "(Required) The name of the Resource Group."
  type        = string
}

variable "location" {
  description = "(Required) The location of the Azure resources (e.g. westeurope)."
  type        = string
}

variable "location_abbreviation" {
  description = "(Required) The location abbreviation (e.g. weu)."
  type        = string
}

variable "environment" {
  description = "(Required) The environment name (e.g. test)."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "(Required) The ID of the Azure Log Analytics workspace."
  type        = string
}

variable "github_repository_owner" {
  description = "(Required) The Owner of the GitHub repository."
  type        = string
}

variable "github_repository_name" {
  description = "(Required) The Name of the GitHub repository."
  type        = string
}

variable "github_personal_access_token" {
  description = "(Required) The GitHub PAT token."
  type        = string
}

variable "tags" {
  description = "(Optional) The Tags for the Azure resources."
  type        = map(string)
  default     = {}
}
