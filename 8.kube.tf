
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

  # 🔥 Azure RBAC ENABLED HERE
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = false
    admin_group_object_ids = [ azuread_group.aks_admins.object_id ]  # optional: Azure AD admin group IDs
  }
}

resource "azuread_group" "aks_admins" {
  display_name     = "aks-admins"
  security_enabled = true
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

# Give AKS access to ACR (IMPORTANT REAL WORLD STEP)
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

