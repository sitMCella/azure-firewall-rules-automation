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

variable "workload_name" {
  description = "(Required) The name of the workload."
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
