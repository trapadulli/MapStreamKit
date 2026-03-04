output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "eventhub_namespace_name" {
  value = azurerm_eventhub_namespace.ehns.name
}

output "eventhub_namespace_id" {
  value = azurerm_eventhub_namespace.ehns.id
}

output "eventhub_name" {
  value = azurerm_eventhub.events.name
}

output "eventhub_consumer_group_processor" {
  value = azurerm_eventhub_consumer_group.processor.name
}

output "storage_account_name" {
  value = azurerm_storage_account.st.name
}

output "schemas_container" {
  value = azurerm_storage_container.schemas.name
}

output "dlq_container" {
  value = azurerm_storage_container.dlq.name
}

output "checkpoints_container" {
  value = azurerm_storage_container.checkpoints.name
}

output "cosmos_account_name" {
  value = azurerm_cosmosdb_account.cosmos.name
}

output "cosmos_db_name" {
  value = azurerm_cosmosdb_sql_database.db.name
}

output "cosmos_raw_container_name" {
  value = azurerm_cosmosdb_sql_container.raw_envelopes.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "graphql_container_app_name" {
  value = azurerm_container_app.graphql_consumer.name
}

output "graphql_container_app_fqdn" {
  value = azurerm_container_app.graphql_consumer.latest_revision_fqdn
}

output "appinsights_connection_string" {
  value     = azurerm_application_insights.appi_functions.connection_string
  sensitive = true
}

output "uami_ingest_client_id" {
  value = azurerm_user_assigned_identity.ingest.client_id
}
output "uami_adapter_client_id" {
  value = azurerm_user_assigned_identity.adapter.client_id
}
output "uami_processor_client_id" {
  value = azurerm_user_assigned_identity.processor.client_id
}
output "uami_gql_client_id" {
  value = azurerm_user_assigned_identity.gql.client_id
}
output "uami_ingest_principal_id" {
  value = azurerm_user_assigned_identity.ingest.principal_id
}
output "uami_adapter_principal_id" {
  value = azurerm_user_assigned_identity.adapter.principal_id
}
output "uami_processor_principal_id" {
  value = azurerm_user_assigned_identity.processor.principal_id
}
output "uami_gql_principal_id" {
  value = azurerm_user_assigned_identity.gql.principal_id
}
