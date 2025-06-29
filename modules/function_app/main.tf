resource "azurerm_service_plan" "app_service_plan" {
  name                = "asp-appservice-${var.environment}-${var.location_abbreviation}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = var.tags
}

resource "azurerm_application_insights" "application_insights" {
  name                = "appi-appservice-${var.environment}-${var.location_abbreviation}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "other"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_storage_account" "storage_account_function_app" {
  name                          = "stfunc${var.environment}${var.location_abbreviation}001"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Standard"
  account_kind                  = "StorageV2"
  account_replication_type      = "LRS"
  access_tier                   = "Hot"
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
  shared_access_key_enabled     = true
  public_network_access_enabled = true
  blob_properties {
    delete_retention_policy {
      days = 14
    }
    container_delete_retention_policy {
      days = 7
    }
  }
  tags = var.tags
}

resource "azurerm_user_assigned_identity" "function_app_user_assigned_identity" {
  name                = "id-function-${var.environment}-${var.location_abbreviation}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "function_app_identity_role_assignment_001" {
  scope                = azurerm_storage_account.storage_account_function_app.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.function_app_user_assigned_identity.principal_id
}

resource "random_string" "random_function_app_name" {
  length  = 7
  special = false
  upper   = false
}

data "archive_file" "function_package" {
  type        = "zip"
  source_dir  = "${path.cwd}/modules/function_app/function"
  output_path = "function-${random_string.random_function_app_name.result}.zip" # Development: "function-${uuid()}.zip"
}

resource "azurerm_linux_function_app" "function_app" {
  name                       = "func-${random_string.random_function_app_name.result}-${var.environment}-${var.location_abbreviation}-001"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  service_plan_id            = azurerm_service_plan.app_service_plan.id
  storage_account_name       = azurerm_storage_account.storage_account_function_app.name
  storage_account_access_key = azurerm_storage_account.storage_account_function_app.primary_access_key

  site_config {
    always_on = false
    application_stack {
      python_version = "3.12"
    }
    application_insights_connection_string = azurerm_application_insights.application_insights.connection_string
    application_insights_key               = azurerm_application_insights.application_insights.instrumentation_key
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "1"
    GITHUB_REPOSITORY_OWNER  = var.github_repository_owner
    GITHUB_REPOSITORY_NAME   = var.github_repository_name
    GITHUB_PAT               = var.github_personal_access_token
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_app_user_assigned_identity.id]
  }

  zip_deploy_file = data.archive_file.function_package.output_path

  tags = var.tags

  lifecycle {
    ignore_changes = [tags]
  }
}
