output "public_ip" {
  value = [for instance in azurerm_linux_virtual_machine.vm : instance.public_ip_address]
}

output "private_ip" {
  value = [for instance in azurerm_linux_virtual_machine.vm : instance.private_ip_address]
}
