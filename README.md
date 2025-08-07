# Azure Infrastructure for Flask Visitor App

This repository contains Terraform infrastructure code to deploy and host the Flask Visitor Info Web Application on Azure. The infrastructure automatically deploys the application from a public GitHub repository.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│   Azure App      │───▶│   Azure Cosmos  │
│  (Flask App)    │    │   Service        │    │   DB (Existing) │
└─────────────────┘    │                  │    │                 │
                       └──────────────────┘    └─────────────────┘
```

## Infrastructure Components

This Terraform configuration creates the following Azure resources optimized for learning and minimal cost:

- **Resource Group**: Container for all resources
- **App Service Plan**: Free tier (F1) hosting plan
- **App Service**: Web application hosting with Python 3.11 runtime
- **User-Assigned Managed Identity**: Secure authentication to Cosmos DB
- **Cosmos DB Account**: Serverless NoSQL database (pay-per-request)
- **Cosmos DB Database**: Database container for the application
- **Cosmos DB Container**: Collection for storing visitor data
- **Source Control Integration**: Automatic deployment from GitHub

## Prerequisites

- Azure subscription with sufficient permissions
- Terraform >= 1.0
- Azure CLI
- Public GitHub repository with the Flask application

**Note**: This configuration uses the cheapest/free tiers suitable for learning and development.

## Quick Start

### 1. Clone this repository

```bash
git clone <this-repository-url>
cd azure-flask-infrastructure
```

### 2. Configure Terraform variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
project_name     = "my-flask-app"
environment      = "dev"
location         = "East US"
app_service_sku  = "F1"  # Free tier

# Your GitHub repository
github_repo_url = "https://github.com/yourusername/flask-visitor-app.git"
github_branch   = "main"

# Cosmos DB configuration (serverless)
cosmos_database_name  = "webapp-db"
cosmos_container_name = "visitor-logs"
```

### 3. Deploy infrastructure

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

### 4. Access your application

After deployment, your Flask application will be available at the URL provided in the Terraform output.

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `github_repo_url` | Public GitHub repository URL | `https://github.com/user/repo.git` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Name prefix for resources | `flask-webapp` |
| `environment` | Environment name | `dev` |
| `location` | Azure region | `East US` |
| `app_service_sku` | App Service Plan SKU | `F1` (Free) |
| `github_branch` | GitHub branch to deploy | `main` |
| `cosmos_database_name` | Cosmos DB database name | `webapp-db` |
| `cosmos_container_name` | Cosmos DB container name | `visitor-logs` |

## Cost-Optimized Configuration

This configuration is optimized for learning with minimal costs:

1. **App Service Plan**: F1 (Free tier)
   - 1 GB disk space
   - 60 minutes compute time per day
   - Custom domains not supported
   - Always On disabled

2. **Cosmos DB**: Serverless configuration
   - Pay only for requests (RU/s) and storage used
   - Automatic scaling
   - No minimum charges
   - Eventual consistency for lowest cost

3. **No Monitoring**: Application Insights and Log Analytics removed to eliminate costs

### Learning Limitations

- **Free App Service**: Limited to 60 CPU minutes per day
- **No Always On**: App will sleep after 20 minutes of inactivity
- **No Monitoring**: No built-in telemetry or logging
- **Basic Backup**: Minimal Cosmos DB backup retention

## Security

The infrastructure implements several security best practices:

- **Managed Identity**: Uses Azure Managed Identity for secure Cosmos DB access
- **RBAC**: Assigns minimal required permissions (Cosmos DB Data Contributor)
- **No Secrets**: No connection strings or secrets stored in application settings
- **HTTPS**: Forces HTTPS for all communication
- **Application Insights**: Monitors security events and performance

### Viewing Logs

```bash
# Stream application logs
az webapp log tail --resource-group <resource-group> --name <app-service-name>

# View deployment logs
az webapp log deployment list --resource-group <resource-group> --name <app-service-name>
```

## Scaling

### Vertical Scaling (App Service Plan)

Modify the `app_service_sku` variable in `terraform.tfvars`:

```hcl
app_service_sku = "S1"  # Scale up to Standard tier
```

Then run `terraform apply`.

### Horizontal Scaling

```bash
# Scale out to multiple instances
az appservice plan update \
  --resource-group <resource-group> \
  --name <app-service-plan> \
  --number-of-workers 3
```

## Cost Optimization

- **Development**: Use `F1` (Free) or `D1` (Shared) SKUs for development
- **Production**: Use `B1` (Basic) or higher for production workloads
- **Cosmos DB**: Use manual throughput and scale based on actual usage
- **Monitoring**: 30-day retention configured for cost optimization

### Estimated Monthly Costs (East US)

| Component | SKU/Configuration | Estimated Cost |
|-----------|-------------------|----------------|
| App Service Plan | F1 (Free) | **$0** |
| Cosmos DB | Serverless (light usage) | ~$0.25-2 |
| **Total** | | **~$0.25-2** |

*Note: Free tier App Service includes 60 CPU minutes/day. Cosmos DB serverless charges only for actual usage.*

### Cost Breakdown
- **Free Tier Benefits**: F1 App Service is completely free
- **Cosmos DB**: Only pay for actual database operations
- **No Monitoring Costs**: Application Insights and Log Analytics removed
- **Minimal Storage**: Only visitor data stored

## Troubleshooting

### Common Issues

1. **Deployment from GitHub fails**:
   - Verify the GitHub repository URL is correct and public
   - Check that the repository contains the required files (`app.py`, `requirements.txt`)
   - Review deployment logs in Azure portal

2. **Application not starting**:
   - Check that you haven't exceeded the 60 CPU minutes daily limit
   - App goes to sleep after 20 minutes of inactivity (F1 limitation)
   - First request after sleep may take longer to respond
   - Review basic App Service logs in Azure portal

3. **Cosmos DB connection issues**:
   - Ensure Managed Identity has Data Contributor role on Cosmos DB
   - Verify Cosmos DB is properly created and accessible
   - Check that the database and container exist

### Free Tier Limitations

1. **App Service F1 Limitations**:
   - 60 CPU minutes per day limit
   - No custom SSL certificates
   - No deployment slots
   - No auto-scaling
   - App sleeps after 20 minutes of inactivity

2. **No Monitoring**:
   - No Application Insights telemetry
   - Basic App Service logs only
   - Limited debugging capabilities

### Debug Commands

```bash
# Check Terraform state
terraform show

# Validate Terraform configuration
terraform validate

# Check Azure resources
az resource list --resource-group <resource-group-name>

# Test Cosmos DB connectivity
az cosmosdb sql database show \
  --account-name <cosmos-account> \
  --resource-group <resource-group> \
  --name <database-name>

# Check container configuration
az cosmosdb sql container show \
  --account-name <cosmos-account> \
  --resource-group <resource-group> \
  --database-name <database-name> \
  --name <container-name>
```

## Cleanup

To destroy all created resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources created by this Terraform configuration.

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test with `terraform plan`
5. Submit a pull request

## Related Repositories

- **Flask Application**: [Flask Visitor Info App](https://github.com/BorisovCloud/flask-webapp-demo.git) - The web application deployed by this infrastructure

## Support

For issues related to:
- **Infrastructure**: Open an issue in this repository
- **Application**: Open an issue in the Flask application repository
- **Azure Services**: Contact Azure Support

## License

This project is licensed under the MIT License - see the LICENSE file for details.
