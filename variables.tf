variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "flask-webapp"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "environment_name" {
  description = "AZD environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "West Europe"
}

variable "app_service_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "F1"
  
  validation {
    condition = contains([
      "F1", "D1", "B1", "B2", "B3",
      "S1", "S2", "S3", "P1", "P2", "P3"
    ], var.app_service_sku)
    error_message = "App Service SKU must be a valid SKU."
  }
}

# GitHub repository configuration
variable "github_repo_url" {
  description = "GitHub repository URL for the Flask application"
  type        = string
  default     = "https://github.com/yourusername/flask-visitor-app.git"
}

variable "github_branch" {
  description = "GitHub branch to deploy from"
  type        = string
  default     = "main"
}

# Cosmos DB configuration
variable "cosmos_database_name" {
  description = "Name of the Cosmos DB database"
  type        = string
  default     = "webapp-db"
}

variable "cosmos_container_name" {
  description = "Name of the Cosmos DB container"
  type        = string
  default     = "visitor-logs"
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "00000000-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Replace with your actual subscription ID
  
}