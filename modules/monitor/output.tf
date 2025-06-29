output "log_analytics_workspace_id" {
  description = "The ID of the Azure Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
}
