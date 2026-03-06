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

  dynamic "registry" {
    for_each = startswith(var.head_container_image, "${azurerm_container_registry.acr.login_server}/") ? [1] : []
    content {
      server   = azurerm_container_registry.acr.login_server
      identity = azurerm_user_assigned_identity.ingest.id
    }
  }

  template {
    container {
      name   = "head"
      image  = var.head_container_image
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

resource "azurerm_container_app" "dab_api" {
  count                        = var.enable_dab ? 1 : 0
  name                         = "ca-msk-dab-${var.env}"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.msk_env.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gql.id]
  }

  dynamic "registry" {
    for_each = startswith(var.dab_container_image, "${azurerm_container_registry.acr.login_server}/") ? [1] : []
    content {
      server   = azurerm_container_registry.acr.login_server
      identity = azurerm_user_assigned_identity.gql.id
    }
  }

  ingress {
    external_enabled = true
    target_port      = 5000
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "dab"
      image  = var.dab_container_image
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "COSMOS_CONNECTION_STRING"
        value = azurerm_cosmosdb_account.cosmos.primary_sql_connection_string
      }

      env {
        name  = "DAB_ENVIRONMENT"
        value = "Development"
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
    EVENTHUB__fullyQualifiedNamespace = "${azurerm_eventhub_namespace.ehns.name}.servicebus.windows.net"
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
    EVENTHUB__fullyQualifiedNamespace = "${azurerm_eventhub_namespace.ehns.name}.servicebus.windows.net"
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
