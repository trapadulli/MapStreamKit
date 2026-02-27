resource "random_uuid" "cosmos_processor_role_assignment" {}

locals {
  # Cosmos NoSQL RBAC scope for a container
  cosmos_scope_raw = "/dbs/${local.cosmos_db}/colls/${local.cosmos_raw}"
}

resource "azurerm_cosmosdb_sql_role_assignment" "processor_raw_contributor" {
  name                = random_uuid.cosmos_processor_role_assignment.result
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name

  principal_id = azurerm_user_assigned_identity.processor.principal_id

  # Built-in Cosmos NoSQL Data Contributor (data-plane) role
  role_definition_id = "${azurerm_cosmosdb_account.cosmos.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"

  scope = local.cosmos_scope_raw
}
