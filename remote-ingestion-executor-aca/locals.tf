# ============================================================================
# DataHub Remote Ingestion Executor - Azure Container Apps
# Local Values
# ============================================================================

locals {
  # ============================================================================
  # Resource Naming
  # ============================================================================

  # Full resource name prefix including environment
  full_name_prefix = "${var.name_prefix}-${var.environment}"

  # ============================================================================
  # Container App Environment
  # ============================================================================

  # Use existing environment ID or the one we create
  container_app_environment_id = var.create_container_app_environment ? azurerm_container_app_environment.executor[0].id : var.container_app_environment_id

  # ============================================================================
  # ACR Configuration
  # ============================================================================

  # Default ACR resource group to main resource group if not specified
  acr_resource_group = var.acr_resource_group_name != "" ? var.acr_resource_group_name : var.resource_group_name

  # ============================================================================
  # Common Tags
  # ============================================================================

  common_tags = merge(var.tags, {
    environment = var.environment
    app         = "datahub-executor"
    managed_by  = "terraform"
    module      = "remote-ingestion-executor-aca"
  })

  # ============================================================================
  # Network Configuration
  # ============================================================================

  # Whether any proxy is configured
  proxy_enabled = var.http_proxy != "" || var.https_proxy != ""

  # Whether custom CA certificates are configured
  custom_ca_enabled = var.custom_ca_cert_path != "" || var.azure_files_share_name != ""

  # ============================================================================
  # Secrets Configuration
  # ============================================================================

  # Determine if using Key Vault for DataHub token
  use_key_vault_for_token = var.datahub_access_token == "" && var.key_vault_id != ""

  # ============================================================================
  # Validation Helpers
  # ============================================================================

  # Validate that either access token or Key Vault is provided
  validate_token_config = (
    var.datahub_access_token != "" || var.key_vault_id != ""
  ) ? true : tobool("ERROR: Either datahub_access_token or key_vault_id must be provided")

  # Validate VNet integration requirements
  validate_vnet_config = (
    !var.enable_vnet_integration || var.infrastructure_subnet_id != ""
  ) ? true : tobool("ERROR: infrastructure_subnet_id is required when enable_vnet_integration is true")

  # Validate container app environment
  validate_environment_config = (
    var.create_container_app_environment || var.container_app_environment_id != ""
  ) ? true : tobool("ERROR: Either create_container_app_environment must be true or container_app_environment_id must be provided")

  # Validate ACR configuration
  validate_acr_config = (
    !var.enable_managed_identity_acr || var.acr_name != ""
  ) ? true : tobool("ERROR: acr_name is required when enable_managed_identity_acr is true")

  # Validate registry credentials when not using managed identity
  validate_registry_creds = (
    var.enable_managed_identity_acr || (var.container_registry_username != "" && var.container_registry_password != "")
  ) ? true : tobool("ERROR: container_registry_username and container_registry_password are required when enable_managed_identity_acr is false")
}
