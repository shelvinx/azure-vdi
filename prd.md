# Requirements
- Use Azure Verified Modules when available
- Create VNET
- Create Subnet
- Create NSG Rules for AVD
- Use naming module where applicable

# 1. AVD Host Pool Setup
- Create AVD host pool

# 1.1 AVD Workspace Setup
- Create AVD workspace

# 1.2 AVD Application Group Setup
- Create application group
- Associate workspace with application group

# 2. Session Host Configuration
- Create session host VMs
- Use Spot Pricing VMs
- Join to Entra ID
- Install AVD agent
- Register with host pool

# 3. User Assignment
- Assign users/groups to application groups
- Configure user permissions

# 4. Identity & Access
- Azure AD integration details
- RBAC assignments
- Conditional Access policies

# 5. Session Host Configuration
- Image management
- Scaling plan
- Update management

# 6. User Experience
- FSLogix profile configuration
- Migrate existing users to AVD
- Configure RDP settings

# 7. Optional Components
- Configure scaling
- Set up monitoring
- Configure storage for profiles

# 8. Testing & Validation
- Deploy infrastructure
- Verify access
- Test user experience