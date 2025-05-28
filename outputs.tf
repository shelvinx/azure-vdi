# Output Session Host Public IP for each VM
output "sessionhost_pip" {
  value = { for k, v in module.host_public_ip : k => v.public_ip_address }
}

# Output FSLogix Storage Account Name
output "fslogix_storage_account_name" {
  value = module.fslogix_storage.name
}