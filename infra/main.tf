locals {
  # MapStreamKit naming
  name_prefix = "msk-${var.env}"

  # Resource group
  rg_name = "rg-${local.name_prefix}"

  # Event Hubs
  ehns_name = "ehns-${local.name_prefix}"
  eh_name   = "eh-msk-events"

  # Observability
  law_name  = "law-${local.name_prefix}"
  appi_func = "appi-msk-func-${var.env}"
  appi_gql  = "appi-msk-gql-${var.env}"

  # Uniqueness suffix (lowercase letters/digits)
  # KV and Cosmos allow hyphens; storage does not.
  kv_name = "kv-${local.name_prefix}-${random_string.suffix.result}"

  storage_name = "stmsk${var.env}${random_string.suffix.result}"

  cosmos_name = "cosmos-${local.name_prefix}-${random_string.suffix.result}"
  cosmos_db   = "msk"
  cosmos_raw  = "raw_envelopes"

  # Managed identities
  uami_ingest    = "uami-msk-ingest-${var.env}"
  uami_adapter   = "uami-msk-adapter-${var.env}"
  uami_processor = "uami-msk-processor-${var.env}"
  uami_gql       = "uami-msk-gql-${var.env}"
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = var.tags
}

# -------------------------
# Observability
# -------------------------
resource "azurerm_log_analytics_workspace" "law" {
  name                = local.law_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "appi_functions" {
  name                = local.appi_func
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
  tags                = var.tags
}

resource "azurerm_application_insights" "appi_gql" {
  name                = local.appi_gql
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
  tags                = var.tags
}

# -------------------------
# Storage account + containers
# -------------------------
resource "azurerm_storage_account" "st" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "schemas" {
  name                  = "schemas"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "dlq" {
  name                  = "dlq"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "checkpoints" {
  name                  = "checkpoints"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "replay" {
  count                 = var.enable_replay ? 1 : 0
  name                  = "replay"
  storage_account_name  = azurerm_storage_account.st.name
  container_access_type = "private"
}

# -------------------------
# Event Hubs (dumb pipe)
# -------------------------
resource "azurerm_eventhub_namespace" "ehns" {
  name                = local.ehns_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku      = "Standard"
  capacity = 1

  tags = var.tags
}

resource "azurerm_eventhub" "events" {
  name                = local.eh_name
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  resource_group_name = azurerm_resource_group.rg.name

  partition_count   = var.eventhub_partitions
  message_retention = var.eventhub_retention_days
}

resource "azurerm_eventhub_consumer_group" "processor" {
  name                = "processor"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  eventhub_name       = azurerm_eventhub.events.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_eventhub_consumer_group" "replay" {
  count               = var.enable_replay ? 1 : 0
  name                = "replay"
  namespace_name      = azurerm_eventhub_namespace.ehns.name
  eventhub_name       = azurerm_eventhub.events.name
  resource_group_name = azurerm_resource_group.rg.name
}

# -------------------------
# Cosmos DB (serverless) + raw_envelopes
# -------------------------
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = local.cosmos_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  offer_type = "Standard"
  kind       = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = local.cosmos_db
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "raw_envelopes" {
  name                = local.cosmos_raw
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name

  partition_key_path    = "/partitionKey"
  partition_key_version = 2

  indexing_policy {
    indexing_mode = "consistent"
    included_path { path = "/*" }
    excluded_path { path = "/\"_etag\"/?" }
  }
}

# -------------------------
# Key Vault (RBAC model)
# -------------------------
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = local.kv_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  enable_rbac_authorization = true
  tags                       = var.tags
}

# -------------------------
# Managed Identities (User Assigned)
# -------------------------
resource "azurerm_user_assigned_identity" "ingest" {
  name                = local.uami_ingest
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "adapter" {
  name                = local.uami_adapter
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "processor" {
  name                = local.uami_processor
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "gql" {
  name                = local.uami_gql
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# -------------------------
# RBAC assignments (MVP)
# -------------------------

# Event Hubs
resource "azurerm_role_assignment" "eh_sender_adapter" {
  scope                = azurerm_eventhub_namespace.ehns.id
  role_definition_name = "Azure Event Hubs Data Sender"
  principal_id         = azurerm_user_assigned_identity.adapter.principal_id
}

resource "azurerm_role_assignment" "eh_receiver_processor" {
  scope                = azurerm_eventhub_namespace.ehns.id
  role_definition_name = "Azure Event Hubs Data Receiver"
  principal_id         = azurerm_user_assigned_identity.processor.principal_id
}

# Storage: ingest writes schemas; processor reads schemas + writes dlq/checkpoints
resource "azurerm_role_assignment" "st_blob_contrib_ingest" {
  scope                = azurerm_storage_account.st.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.ingest.principal_id
}

resource "azurerm_role_assignment" "st_blob_reader_processor" {
  scope                = azurerm_storage_account.st.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.processor.principal_id
}

resource "azurerm_role_assignment" "st_blob_contrib_processor" {
  scope                = azurerm_storage_account.st.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.processor.principal_id
}

# Cosmos

# Key Vault secret read (broad for MVP; tighten later)
resource "azurerm_role_assignment" "kv_secrets_user_ingest" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.ingest.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user_processor" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.processor.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user_gql" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.gql.principal_id
}
