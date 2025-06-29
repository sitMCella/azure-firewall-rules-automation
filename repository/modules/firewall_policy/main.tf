resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "afwp-${var.environment}-${var.location_abbreviation}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "firewall_policy_rule_collection_group" {
  name               = "rcg-azure-${var.environment}-${var.location_abbreviation}-001"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = 100

  dynamic "network_rule_collection" {
    for_each = var.network_rule_collections

    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value["name"]
          protocols             = rule.value["protocols"]
          source_addresses      = rule.value["source_addresses"]
          destination_addresses = rule.value["destination_addresses"]
          destination_ports     = rule.value["destination_ports"]
        }
      }
    }
  }
}