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

module "firewall_policy" {
  source = "./modules/firewall_policy"

  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = var.location
  location_abbreviation = var.location_abbreviation
  environment           = var.environment
  network_rule_collections = [
    {
      name     = "rulecollection1"
      priority = 100
      action   = "Allow"
      rules = [
        {
          name                  = "mysql-inbound-3306"
          protocols             = ["TCP"]
          source_addresses      = ["*"]
          destination_addresses = ["10.0.1.5/32"]
          destination_ports     = ["3306"]
        }
      ]
    },
    {
      name     = "azuremachinelearning"
      priority = 110
      action   = "Allow"
      rules = [
        {
          name                  = "azuremachinelearning-outbound-80"
          protocols             = ["TCP"]
          source_addresses      = ["10.0.0.0/18"]
          destination_addresses = ["13.69.64.192/28", "13.69.106.192/28", "20.86.88.160/28", "40.74.24.96/28"]
          destination_ports     = ["80"]
        },
        {
          name                  = "azuremachinelearning-outbound-443"
          protocols             = ["TCP"]
          source_addresses      = ["10.0.0.0/18"]
          destination_addresses = ["13.69.64.192/28", "13.69.106.192/28", "20.86.88.160/28", "40.74.24.96/28"]
          destination_ports     = ["443"]
        }
      ]
    },
    {
      name     = "rulecollection3"
      priority = 120
      action   = "Allow"
      rules = [
        {
          name                  = "workload-outbound-443"
          protocols             = ["TCP"]
          source_addresses      = ["10.0.1.6/32"]
          destination_addresses = ["*"]
          destination_ports     = ["443"]
        }
      ]
    }
  ]
  tags = local.tags
}
