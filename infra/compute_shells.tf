# Compute shells for StreamMapKit runtime


# Container App Environment for Head pullers
resource "azurerm_container_app_environment" "msk_env" {
  name                = "cae-msk-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags                = var.tags
}

# Head pullers host (Azure Container App)
resource "azurerm_container_app" "head_puller" {
  name                         = "ca-msk-head-${var.env}"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.msk_env.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ingest.id]
  }

  template {
    container {
      name   = "head"
      image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest" # placeholder, replace with your image
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "APPINSIGHTS_CONNECTION_STRING"
        value = azurerm_application_insights.appi_functions.connection_string
      }
    }
  }

  tags = var.tags
}

# GraphQL Consumer host (Azure Container App)
resource "azurerm_container_app" "graphql_consumer" {
  name                         = "ca-msk-graphql-${var.env}"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.msk_env.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gql.id]
  }

  ingress {
    external_enabled = true
    target_port      = 4000
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "graphql"
      image  = var.graphql_container_image
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "PORT"
        value = "4000"
      }

      env {
        name  = "COSMOS_ENDPOINT"
        value = azurerm_cosmosdb_account.cosmos.endpoint
      }

      env {
        name  = "COSMOS_DB"
        value = azurerm_cosmosdb_sql_database.db.name
      }

      env {
        name  = "COSMOS_CONTAINER"
        value = azurerm_cosmosdb_sql_container.raw_envelopes.name
      }

      env {
        name  = "APPINSIGHTS_CONNECTION_STRING"
        value = azurerm_application_insights.appi_functions.connection_string
      }
    }
  }

  tags = var.tags
}

# Adapter Ingress host (Azure Function App)
resource "azurerm_linux_function_app" "adapter_ingress" {
  name                       = "fa-msk-adapter-${var.env}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  service_plan_id          = azurerm_service_plan.func.id
  storage_account_name     = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.adapter.id]
  }

  site_config {
    application_stack {
      node_version = "18"
    }
  }

  app_settings = {
    EVENTHUB_NAMESPACE            = azurerm_eventhub_namespace.ehns.name
    EVENTHUB_NAME                 = azurerm_eventhub.events.name
    APPINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appi_functions.connection_string
    AzureWebJobsStorage           = azurerm_storage_account.st.primary_connection_string
    FUNCTIONS_EXTENSION_VERSION   = "~4"
    FUNCTIONS_WORKER_RUNTIME      = "node"
    WEBSITE_RUN_FROM_PACKAGE      = "1"
  }
}

resource "azurerm_linux_function_app" "tail_processor" {
  name                     = "fa-msk-tail-${var.env}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  service_plan_id          = azurerm_service_plan.func.id
  storage_account_name     = azurerm_storage_account.st.name
  storage_account_access_key = azurerm_storage_account.st.primary_access_key
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.processor.id]
  }
  site_config {
    application_stack {
      node_version = "18"
    }
  }
  app_settings = {
    EVENTHUB_NAMESPACE            = azurerm_eventhub_namespace.ehns.name
    EVENTHUB_NAME                 = azurerm_eventhub.events.name
    EVENTHUB_CONSUMER_GROUP       = azurerm_eventhub_consumer_group.processor.name
    COSMOS_ENDPOINT               = azurerm_cosmosdb_account.cosmos.endpoint
    COSMOS_DB                     = azurerm_cosmosdb_sql_database.db.name
    COSMOS_CONTAINER              = azurerm_cosmosdb_sql_container.raw_envelopes.name
    STORAGE_ACCOUNT               = azurerm_storage_account.st.name
    STORAGE_SCHEMAS_CONTAINER     = azurerm_storage_container.schemas.name
    STORAGE_DLQ_CONTAINER         = azurerm_storage_container.dlq.name
    STORAGE_CHECKPOINTS_CONTAINER = azurerm_storage_container.checkpoints.name
    APPINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appi_functions.connection_string
    AzureWebJobsStorage           = azurerm_storage_account.st.primary_connection_string
    FUNCTIONS_EXTENSION_VERSION   = "~4"
    FUNCTIONS_WORKER_RUNTIME      = "node"
    WEBSITE_RUN_FROM_PACKAGE      = "1"
  }
}

# App Service Plan for Function Apps
resource "azurerm_service_plan" "func" {
  name                = "asp-msk-func-${var.env}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}
