variable "ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "viu-itsm-eastus2-rg"
    storage_account_name = "viutfstate001"  # TODO: Create this storage account first
    container_name       = "tfstate"
    key                  = "ubuntu-vm-test.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "ubuntu_vm" {
  source = "../../modules/vm"
  
  resource_group_name = "viu-itsm-eastus2-rg"
  location            = "eastus2"
  vm_name             = "viu-ubuntu-test-vm"
  vm_size             = "Standard_B4as_v2"
  admin_username      = "azureuser"
  ssh_public_key      = var.ssh_public_key
  
  # Network configuration
  vnet_name      = "vnet-showcase"
  subnet_name    = "snet-general"
  
  # Zone configuration
  availability_zone = "1"
  
  # OS Disk (matching your current VM)
  os_disk_size_gb      = 30
  os_disk_storage_type = "Premium_LRS"
  
  # Public IP
  create_public_ip = true
  
  tags = {
    Business_Criticality = "Low"
    Business_Unit        = "VIUBYHUB"
    createdDate          = "2025-10-21"
    Dynatrace            = "False"
    Environment          = "Dev"
    ManagedBy            = "Terraform"
    Operations_Team      = "ITSM"
    Owner                = "ITSM"
    Project              = "IaC-Recovery"
    Purpose              = "DR-Testing"
    Region               = "EastUS2"
  }
}

output "vm_public_ip" {
  description = "Public IP for SSH and Ansible"
  value       = module.ubuntu_vm.public_ip_address
}

output "vm_private_ip" {
  value = module.ubuntu_vm.private_ip_address
}

output "vm_name" {
  value = module.ubuntu_vm.vm_name
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i ~/.ssh/id_rsa ${module.ubuntu_vm.admin_username}@${module.ubuntu_vm.public_ip_address}"
}
