
# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aksname
  location            = var.kubelocation
  resource_group_name = azurerm_resource_group.rg1.name
  dns_prefix          = "aksdemo"

  identity {  type = "SystemAssigned"  }
  network_profile { network_plugin = "azure" }
  tags = {  env = "dev"   }
  oidc_issuer_enabled = true

  default_node_pool {
  name                = "systempool"
  node_count          = 1
  vm_size             = "Standard_B2als_v2"

  temporary_name_for_rotation = "rotpool"   # 👈 REQUIRED FIX
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "aks_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

# User Node Pool (like AWS node group)
resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id

  vm_size    = "Standard_D2s_v5"
  node_count = 1
  mode = "User"
  tags = {  purpose = "app-nodes"   }
}

# OPTIONAL: ACR (Container Registry)
resource "azurerm_container_registry" "acr" {
  name                = var.acrname
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_kubernetes_cluster.aks.location
  sku                 = "Basic"
  admin_enabled       = false
}

