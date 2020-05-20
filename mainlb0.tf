resource "azurerm_resource_group" "MDSLB" {
  name     = "MDSLoadBalancerRG"
  location = "West US"
}

resource "azurerm_public_ip" "MDSPIP" {
  name                = "PublicIPForLB"
  location            = "east US"
  resource_group_name = azurerm_resource_group.MDSLB.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "MDSLB1" {
  name                = "TestLoadBalancer"
  location            = "east US"
  resource_group_name = azurerm_resource_group.MDSLB.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.MDSPIP.id
  }
}

resource "azurerm_lb_backend_address_pool" "MDSLBBE" {
  resource_group_name = azurerm_resource_group.MDSLB.name
  loadbalancer_id     = azurerm_lb.MDSLB1.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "MDSLBRL" {
  resource_group_name            = azurerm_resource_group.MDSLB.name
  loadbalancer_id                = azurerm_lb.MDSLB1.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = "PublicIPAddress"
}
#### Note cant create ob rule on basic  load balancer, must be standard
#resource "azurerm_lb_outbound_rule" "MDSLBRLOB" {
#  resource_group_name     = azurerm_resource_group.MDSLB.name
#  loadbalancer_id         = azurerm_lb.MDSLB1.id
#  name                    = "OutboundRule"
#  protocol                = "Tcp"
#  backend_address_pool_id = azurerm_lb_backend_address_pool.MDSLBBE.id
#
#  frontend_ip_configuration {
#    name = "PublicIPAddress"
 # }
#}

resource "azurerm_lb_probe" "MDSLBPRB" {
  resource_group_name = azurerm_resource_group.MDSLB.name
  loadbalancer_id     = azurerm_lb.MDSLB1.id
  name                = "ssh-running-probe"
  port                = 22
}
### Functiion App ####
resource "azurerm_storage_account" "MDSFAStor" {
  name                     = "functionsappstor"
  resource_group_name      = azurerm_resource_group.MDSLB.name
  location                 = azurerm_resource_group.MDSLB.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "MDSSVCP" {
  name                = "azure-functions-test-service-plan"
  location            = azurerm_resource_group.MDSLB.location
  resource_group_name = azurerm_resource_group.MDSLB.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "MDSFA" {
  name                      = "mds-azure-functions"
  location                  = azurerm_resource_group.MDSLB.location
  resource_group_name       = azurerm_resource_group.MDSLB.name
  app_service_plan_id       = azurerm_app_service_plan.MDSSVCP.id
  storage_connection_string = azurerm_storage_account.MDSFAStor.primary_connection_string
}