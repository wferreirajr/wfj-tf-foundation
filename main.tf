# main.tf

provider "azurerm" {
  features {}
}

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

  add_subscription  = true
  alias             = "WFJ-PRD"
  subscription_name = "PRD"
  subscription_id   = "35a89c93-cf4c-47cf-a4b0-c1db8f4241d2"

  additional_tags = {
    environment = "prd"
    owner-id    = "cloud-foundation"
  }

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
/*
module "management_lock" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/management_lock"

  count = length(module.resource_group.resource_group_id)

  name = "lock-iac-foundation"
  scope      = module.resource_group.resource_group_id[count.index]
  lock_level = "CanNotDelete"
  note       = "Create lock by Cloud Foundation Teams"

}
*/
#  FIM lock resource group

# INICIO criação do Virtual Network

module "virtual_network" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/virtual_network"

  vnet_name           = "wfj-vnet"
  vnet_cidr           = "10.0.0.0/16"
  location            = "eastus"
  resource_group_name = "network"

  # dns_servers = ["1.1.1.1", "8.8.8.8"]

subnets = [
    {
      name          = "wfj-subnet-prd"
      address_prefix = "10.0.1.0/24"
    },
    {
      name          = "wfj-subnet-des"
      address_prefix = "10.0.2.0/24"
    }
  ]

  additional_tags = {
    environment = "prd"
    project     = "fundacao"
    owner-id    = "cloud-foundation"
  }

  depends_on = [module.resource_group]

}

# FIM criação do Virtual Network

# INICIO para a criacao do storage account para o container de fundação da Cloud.

module "storage_account" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/storage_account"

  stg_name                 = "wfjstorage"
  rg_name                  = "foundation"
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

#  INICIO da bloco de codigo para criação do Network Security Group.

module "my_nsg" {
  source = "git::https://github.com/wferreirajr/wfj-tf-module.git//azure/network_security_group"

  nsg_name           = "wfj-nsg-vnet"
  location           = "eastus"
  resource_group_name = "network"

  security_rules = [
    {
      name                       = "wfj-allowSSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "wfj-allowHTTP"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]

  additional_tags = {
    environment = "prd"
    project     = "fundacao"
    owner-id    = "cloud-foundation"
  }
}

#  FIM da bloco de codigo para criação do Network Security Group.

/*
provider "http" {}

data "http" "external_ip" {
  url = "https://api.ipify.org?format=json"
}

output "external_ip" {
  value = jsondecode(data.http.external_ip.response_body).ip
}
*/
