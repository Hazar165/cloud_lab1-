resource "azuread_application_registration" "github" {
  display_name = "${local.name}-github"
}

resource "azuread_service_principal" "github" {
  client_id = azuread_application_registration.github.client_id
}

resource "azuread_application_federated_identity_credential" "github" {
  application_id = azuread_application_registration.github.id
  display_name   = "github-main"
  description    = "GitHub Actions deployments from main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repo}:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "github_contributor" {
  scope                            = azurerm_resource_group.main.id
  role_definition_name             = "Contributor"
  principal_id                     = azuread_service_principal.github.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "github_acr_push" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPush"
  principal_id                     = azuread_service_principal.github.object_id
  skip_service_principal_aad_check = true
}
