# terraform.tfvars
# Number of VMs to create
windows_vm_count = 1

# Spot Pricing
spot_max_price  = 0.07
priority        = "Spot"
eviction_policy = "Deallocate"

# SKU Size
sku_size = "Standard_D2als_v6"