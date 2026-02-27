# Compute shells for StreamMapKit runtime

# Adapter Ingress host (Azure Function App HTTP trigger)
resource "azurerm_function_app" "adapter_ingress" {
  name                       = "fa-msk-adapter-${var.env}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.func.id
  storage_account_name       = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.adapter.id]
  }
  app_settings = {
    EVENTHUB_NAMESPACE        = azurerm_eventhub_namespace.ehns.name
    EVENTHUB_NAME             = azurerm_eventhub.events.name
    EVENTHUB_CONSUMER_GROUP   = azurerm_eventhub_consumer_group.processor.name
    COSMOS_ENDPOINT           = azurerm_cosmosdb_account.cosmos.endpoint
    COSMOS_DB                 = azurerm_cosmosdb_sql_database.db.name
    COSMOS_CONTAINER          = azurerm_cosmosdb_sql_container.raw_envelopes.name
    STORAGE_ACCOUNT           = azurerm_storage_account.st.name
    STORAGE_SCHEMAS_CONTAINER = azurerm_storage_container.schemas.name
    STORAGE_DLQ_CONTAINER     = azurerm_storage_container.dlq.name
    STORAGE_CHECKPOINTS_CONTAINER = azurerm_storage_container.checkpoints.name
    APPINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appi_func.connection_string
    AzureWebJobsStorage           = azurerm_storage_account.st.primary_connection_string
    FUNCTIONS_EXTENSION_VERSION   = "~4"
    FUNCTIONS_WORKER_RUNTIME      = "node"
    WEBSITE_RUN_FROM_PACKAGE      = "1"
  }
}

# Head Puller host (Azure Function App Timer trigger)
resource "azurerm_function_app" "head_puller" {
  name                       = "fa-msk-head-${var.env}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.func.id
  storage_account_name       = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ingest.id]
  }
  app_settings = {
    EVENTHUB_NAMESPACE        = azurerm_eventhub_namespace.ehns.name
    EVENTHUB_NAME             = azurerm_eventhub.events.name
    COSMOS_ENDPOINT           = azurerm_cosmosdb_account.cosmos.endpoint
    COSMOS_DB                 = azurerm_cosmosdb_sql_database.db.name
    COSMOS_CONTAINER          = azurerm_cosmosdb_sql_container.raw_envelopes.name
    STORAGE_ACCOUNT           = azurerm_storage_account.st.name
    STORAGE_SCHEMAS_CONTAINER = azurerm_storage_container.schemas.name
    APPINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appi_func.connection_string
    AzureWebJobsStorage           = azurerm_storage_account.st.primary_connection_string
    FUNCTIONS_EXTENSION_VERSION   = "~4"
    FUNCTIONS_WORKER_RUNTIME      = "node"
    WEBSITE_RUN_FROM_PACKAGE      = "1"
  }
}

# Tail Processor host (Azure Function App EventHubTrigger)
resource "azurerm_function_app" "tail_processor" {
  name                       = "fa-msk-tail-${var.env}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.func.id
  storage_account_name       = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.processor.id]
  }
  app_settings = {
    EVENTHUB_NAMESPACE        = azurerm_eventhub_namespace.ehns.name
    EVENTHUB_NAME             = azurerm_eventhub.events.name
    EVENTHUB_CONSUMER_GROUP   = azurerm_eventhub_consumer_group.processor.name
    COSMOS_ENDPOINT           = azurerm_cosmosdb_account.cosmos.endpoint
    COSMOS_DB                 = azurerm_cosmosdb_sql_database.db.name
    COSMOS_CONTAINER          = azurerm_cosmosdb_sql_container.raw_envelopes.name
    STORAGE_ACCOUNT           = azurerm_storage_account.st.name
    STORAGE_SCHEMAS_CONTAINER = azurerm_storage_container.schemas.name
    STORAGE_DLQ_CONTAINER     = azurerm_storage_container.dlq.name
    STORAGE_CHECKPOINTS_CONTAINER = azurerm_storage_container.checkpoints.name
    APPINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appi_func.connection_string
    AzureWebJobsStorage           = azurerm_storage_account.st.primary_connection_string
    FUNCTIONS_EXTENSION_VERSION   = "~4"
    FUNCTIONS_WORKER_RUNTIME      = "node"
    WEBSITE_RUN_FROM_PACKAGE      = "1"
  }
}

# App Service Plan for Function Apps
resource "azurerm_app_service_plan" "func" {
  name                = "asp-msk-func-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}
