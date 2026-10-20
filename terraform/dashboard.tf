locals {
  dashboard_tiles = [
    {
      title       = "Requests"
      resource_id = azurerm_application_gateway.main.id
      namespace   = "microsoft.network/applicationgateways"
      metric      = "TotalRequests"
      aggregation = 1
      filter      = ""
      x           = 0
      y           = 0
    },
    {
      title       = "5xx responses"
      resource_id = azurerm_application_gateway.main.id
      namespace   = "microsoft.network/applicationgateways"
      metric      = "ResponseStatus"
      aggregation = 1
      filter      = "HttpStatusGroup eq '5xx'"
      x           = 6
      y           = 0
    },
    {
      title       = "Latency"
      resource_id = azurerm_application_gateway.main.id
      namespace   = "microsoft.network/applicationgateways"
      metric      = "ApplicationGatewayTotalTime"
      aggregation = 4
      filter      = ""
      x           = 0
      y           = 4
    },
    {
      title       = "CPU"
      resource_id = azurerm_container_app.api.id
      namespace   = "microsoft.app/containerapps"
      metric      = "CpuPercentage"
      aggregation = 4
      filter      = ""
      x           = 6
      y           = 4
    },
    {
      title       = "Memory"
      resource_id = azurerm_container_app.api.id
      namespace   = "microsoft.app/containerapps"
      metric      = "MemoryPercentage"
      aggregation = 4
      filter      = ""
      x           = 0
      y           = 8
    },
  ]
}

resource "azurerm_portal_dashboard" "main" {
  name                = "${local.name}-dashboard"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.tags

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          for index, tile in local.dashboard_tiles : tostring(index) => {
            position = {
              x       = tile.x
              y       = tile.y
              colSpan = 6
              rowSpan = 4
            }
            metadata = {
              type     = "Extension/HubsExtension/PartType/MonitorChartPart"
              settings = {}
              inputs = [
                {
                  name = "options"
                  value = {
                    chart = {
                      title    = tile.title
                      timespan = { relative = { duration = 86400000 } }
                      visualization = {
                        chartType = 2
                        legendVisualization = {
                          isVisible    = true
                          position     = 2
                          hideSubtitle = false
                        }
                        axisVisualization = {
                          x = { isVisible = true }
                          y = { isVisible = true }
                        }
                      }
                      metrics = [
                        merge(
                          {
                            resourceMetadata    = { id = tile.resource_id }
                            name                = tile.metric
                            aggregationType     = tile.aggregation
                            namespace           = tile.namespace
                            metricVisualization = { displayName = tile.title }
                          },
                          tile.filter == "" ? {} : { filter = tile.filter }
                        )
                      ]
                    }
                  }
                },
                {
                  name       = "sharedTimeRange"
                  isOptional = true
                }
              ]
            }
          }
        }
      }
    }
  })
}
