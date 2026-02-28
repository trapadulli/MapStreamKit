# Azure Monitor Diagnostic Settings for Event Hubs + Cosmos -> Log Analytics

data "azurerm_monitor_diagnostic_categories" "ehns" {
  resource_id = azurerm_eventhub_namespace.ehns.id
}

/*
NOTE:
Event Hub diagnostic settings are automatically deployed in this subscription
via Azure Policy (DeployIfNotExists).

Managing them in Terraform causes:
"A resource with the ID ... already exists"

We intentionally do NOT manage EHNS diagnostics in Terraform.
*/
// resource "azurerm_monitor_diagnostic_setting" "ehns" {
//   name                       = "diag-${local.name_prefix}-ehns"
//   target_resource_id         = azurerm_eventhub_namespace.ehns.id
//   log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
//
//   # Use resource-specific tables where supported
//   log_analytics_destination_type = "Dedicated"
//
//   dynamic "enabled_log" {
//     for_each = toset(data.azurerm_monitor_diagnostic_categories.ehns.log_category_types)
//     content {
//       category = enabled_log.value
//     }
//   }
//
//   dynamic "metric" {
//     for_each = toset(data.azurerm_monitor_diagnostic_categories.ehns.metrics)
//     content {
//       category = metric.value
//       enabled  = true
//     }
//   }
// }

data "azurerm_monitor_diagnostic_categories" "cosmos" {
  resource_id = azurerm_cosmosdb_account.cosmos.id
}

resource "azurerm_monitor_diagnostic_setting" "cosmos" {
  name                       = "diag-${local.name_prefix}-cosmos"
  target_resource_id         = azurerm_cosmosdb_account.cosmos.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.cosmos.log_category_types)
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.cosmos.metrics)
    content {
      category = metric.value
      enabled  = true
    }
  }
}
