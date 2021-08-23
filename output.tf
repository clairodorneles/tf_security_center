output "vm_linux_id" {
    value   = azurerm_linux_virtual_machine.vm-linux-1.id
}

output "vm_windows_id" {
    value   = azurerm_windows_virtual_machine.vm-windows-2.id
}

output "la-id" {
    value   = azurerm_log_analytics_workspace.law.id  
}

