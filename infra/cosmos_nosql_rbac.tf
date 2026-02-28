
resource "random_uuid" "cosmos_role_assignment" {}

locals {
  cosmos_scope = "${azurerm_cosmosdb_account.cosmos.id}/dbs/${azurerm_cosmosdb_sql_database.db.name}/colls/${azurerm_cosmosdb_sql_container.raw_envelopes.name}"
}

resource "azurerm_cosmosdb_sql_role_assignment" "processor_data_contributor" {
  name                = random_uuid.cosmos_role_assignment.result
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name

  principal_id       = azurerm_user_assigned_identity.processor.principal_id
  role_definition_id = "${azurerm_cosmosdb_account.cosmos.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  scope              = local.cosmos_scope
}
