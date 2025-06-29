locals {
  tags = {
    environment = var.environment
  }
}

resource "azurerm_resource_group" "resource_group" {
  name     = "rg-${var.workload_name}-${var.environment}-${var.location_abbreviation}-001"
  location = var.location
  tags     = local.tags
}

module "monitor" {
  source = "./modules/monitor"

  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  location_abbreviation = var.location_abbreviation
  environment           = var.environment
  tags                  = local.tags
}

module "function_app" {
  source = "./modules/function_app"

  resource_group_name          = azurerm_resource_group.resource_group.name
  location                     = var.location
  location_abbreviation        = var.location_abbreviation
  log_analytics_workspace_id   = module.monitor.log_analytics_workspace_id
  environment                  = var.environment
  github_repository_owner      = var.github_repository_owner
  github_repository_name       = var.github_repository_name
  github_personal_access_token = var.github_personal_access_token
  tags                         = local.tags
}
