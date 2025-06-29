resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "log-monitor-${var.environment}-${var.location_abbreviation}-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}
