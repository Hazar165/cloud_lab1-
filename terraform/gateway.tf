resource "azurerm_public_ip" "agw" {
  name                = "${local.name}-agw-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

locals {
  agw_pool     = "lab1-pool"
  agw_frontend = "public"
  agw_port     = "port-80"
  agw_http     = "http"
  agw_listener = "http"
  agw_probe    = "health"
  agw_rule     = "http"
}

resource "azurerm_application_gateway" "main" {
  name                = "${local.name}-agw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = azurerm_subnet.agw.id
  }

  frontend_port {
    name = local.agw_port
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.agw_frontend
    public_ip_address_id = azurerm_public_ip.agw.id
  }

  backend_address_pool {
    name         = local.agw_pool
    ip_addresses = [azurerm_container_app_environment.main.static_ip_address]
  }

  backend_http_settings {
    name                  = local.agw_http
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    host_name             = azurerm_container_app.api.ingress[0].fqdn
    probe_name            = local.agw_probe
  }

  probe {
    name                                      = local.agw_probe
    protocol                                  = "Http"
    path                                      = "/health"
    host                                      = azurerm_container_app.api.ingress[0].fqdn
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
  }

  http_listener {
    name                           = local.agw_listener
    frontend_ip_configuration_name = local.agw_frontend
    frontend_port_name             = local.agw_port
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.agw_rule
    rule_type                  = "Basic"
    http_listener_name         = local.agw_listener
    backend_address_pool_name  = local.agw_pool
    backend_http_settings_name = local.agw_http
    priority                   = 100
  }
}
