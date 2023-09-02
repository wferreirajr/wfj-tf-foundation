terraform {
  backend "azurerm" {
    resource_group_name  = "my-portfolio"
    storage_account_name = "wfjteste"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}