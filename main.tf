terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.38"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "azurerm" {
  subscription_id = var.azure_subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Random string for unique resource names
resource "random_string" "resource_token" {
  length  = 8
  special = false
  upper   = false
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Resource group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}-${random_string.resource_token.result}"
  location = var.location

  tags = {
    environment  = var.environment
    project      = var.project_name
    azd-env-name = var.environment_name
  }
}

# User-assigned managed identity
resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${var.project_name}-${var.environment}-${random_string.resource_token.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = azurerm_resource_group.main.tags
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "plan-${var.project_name}-${var.environment}-${random_string.resource_token.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku

  tags = azurerm_resource_group.main.tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project_name}-${var.environment}-${random_string.resource_token.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  site_config {
    always_on = false  # Free tier doesn't support always_on
    
    application_stack {
      python_version = "3.11"
    }

    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }
    
    # Startup command for Flask application
    app_command_line = "python app.py"
  }

  app_settings = {
    # Python configuration
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    
    # Application configuration
    "COSMOS_ENDPOINT"        = azurerm_cosmosdb_account.main.endpoint
    "COSMOS_DATABASE_NAME"   = var.cosmos_database_name
    "COSMOS_CONTAINER_NAME"  = var.cosmos_container_name
    "FLASK_ENV"              = var.environment == "production" ? "production" : "development"
    "PORT"                   = "8000"
    
    # Azure configuration
    "AZURE_CLIENT_ID" = azurerm_user_assigned_identity.main.client_id
  }

  tags = azurerm_resource_group.main.tags
}

# Configure deployment from GitHub
resource "azurerm_app_service_source_control" "main" {
  app_id                 = azurerm_linux_web_app.main.id
  repo_url               = var.github_repo_url
  branch                 = var.github_branch
  use_manual_integration = true
  use_mercurial          = false
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "main" {
  name                = "cosmos-${var.project_name}-${var.environment}-${random_string.resource_token.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  free_tier_enabled   = true
  
  consistency_policy {
    consistency_level = "Eventual"  # Cheapest consistency level
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }

  # Minimal backup configuration
  backup {
    type = "Periodic"
    interval_in_minutes = 1440  # 24 hours (maximum interval)
    retention_in_hours  = 8     # Minimum retention
    storage_redundancy  = "Local"  # Cheapest redundancy
  }

  tags = azurerm_resource_group.main.tags
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmos_database_name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

# Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "main" {
  name                = var.cosmos_container_name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths = ["/ip_address"]
  partition_key_version = 1

  # Serverless - no throughput setting needed, pay per request

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

# Grant Cosmos DB Data Contributor role to the managed identity
resource "azurerm_cosmosdb_sql_role_assignment" "main" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  role_definition_id  = "${azurerm_cosmosdb_account.main.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
  principal_id        = azurerm_user_assigned_identity.main.principal_id
  scope               = azurerm_cosmosdb_account.main.id
}
