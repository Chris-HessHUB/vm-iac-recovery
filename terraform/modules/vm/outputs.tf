output "vm_id" {
  description = "The ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "public_ip_address" {
  description = "The public IP address of the VM"
  value       = var.create_public_ip ? azurerm_public_ip.vm_public_ip[0].ip_address : null
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "vm_name" {
  description = "The name of the VM"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "admin_username" {
  description = "The admin username"
  value       = var.admin_username
}
