# main.tf

provider "azurerm" {
  features {}
}

// como armazenar o state do terraform em um storage account?

terraform {
  backend "azurerm" {
    resource_group_name  = "my-portfolio"
    storage_account_name = "wfjteste"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

# INICIO do bloco para gerenciar a subscription

module "subscription" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/subscription"

  add_subscription = true
  alias = "WFJ-PRD"
  subscription_name = "PRD" 
  subscription_id = "35a89c93-cf4c-47cf-a4b0-c1db8f4241d2"
  
}

# FIM do bloco para gerenciar a subscription

# INICIO da bloco de codigo para criação dos containers para toda a parte de fundação da Cloud.

module "resource_group" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/resource_group"

  resource_group_configs = [
    {
      name        = "foundation"
      location    = "eastus"
      description = "Container para hospedar "
    },
    {
      name        = "network"
      location    = "eastus"
      description = "Container para hospedar para de redes, exemplo VPC, VPN, Rotas etc."
    },
    {
      name        = "audit"
      location    = "eastus"
      description = "Container para hospedar toda parte de auditoria"
    },
    {
      name        = "log-archive"
      location    = "eastus"
      description = "Container para hospedar toda parte de armazenamento de logs"
    },
    {
      name        = "shared-services"
      location    = "eastus"
      description = "Container para hospedar todos os serviços compartilhados, exemplo VMs, Databases etc"
    },
    {
      name        = "monitoring"
      location    = "eastus"
      description = "Container para hospedar toda parte de observabilidade e monitoramento"
    }
  ]

  additional_tags = {
    environment = "prd"
    project     = "fundacao"
    owner-id    = "cloud-foundation"
  }

}

#  FIM da bloco de codigo para criação dos containers para toda a parte de fundação da Cloud.

#  INICIO lock resource group

module "azurerm_management_lock" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/azurerm_management_lock"

  # for_each = toset(module.resource_group.resource_group_id)
  count = length(module.resource_group.resource_group_id)

  name = "lock-iac-foundation"
  # scope      = each.value
  scope      = module.resource_group.resource_group_id[count.index]
  lock_level = "CanNotDelete"
  note       = "Create lock by Cloud Foundation Teams"

}

#  FIM lock resource group

# INICIO para a criacao do storage account para o container de fundação da Cloud.

module "storage_account" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/storage_account"

  stg_name                 = "wfjstorage"
  rg_name                  = "primary-foundation"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  additional_tags = {
    environment = "prd"
    project     = "fundacao"
    owner-id    = "cloud-foundation"
  }

  depends_on = [module.resource_group]
}

#  FIM para a criacao do storage account para o container de fundação da Cloud.

#  INICIO da bloco de codigo para criação e aplicação de politica de controle da Cloud.

module "assignment_policy" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/assignment_policy"

  assignment_policy_name            = "foundation-storage-encryption"
  assignment_policy_display_name    = "Foundation Storage Encryption"
  assignment_policy_description     = "For block storage without encryption"
  assignment_policy_definition_id   = "4733ea7b-a883-42fe-8cac-97454c2a9e4a"
  assignment_policy_subscription_id = "35a89c93-cf4c-47cf-a4b0-c1db8f4241d2"

}

#  FIM da bloco de codigo para criação e aplicação de politica de controle da Cloud.


provider "http" {}

data "http" "external_ip" {
  url = "https://api.ipify.org?format=json"
}

output "external_ip" {
  value = jsondecode(data.http.external_ip.response_body).ip
}

/*
data "azurerm_subscription" "current" {}

resource "azurerm_policy_definition" "example" {
  name         = "only-deploy-in-westeurope"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed resource types"

  policy_rule = <<POLICY_RULE
 {
    "if": {
      "not": {
        "field": "location",
        "equals": "westeurope"
      }
    },
    "then": {
      "effect": "Deny"
    }
  }
POLICY_RULE
}
*/