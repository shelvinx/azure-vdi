locals {
  windows_vm_instances = {
    for i in range(var.windows_vm_count) : "vm${i + 1}" => {}
  }
}
