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


# Storage Setup:
- Create Azure Storage Account (Premium for production workloads)
- Configure Azure File Share for FSLogix profiles
- Set up appropriate networking and firewall rules
- Configure proper RBAC permissions

# FSLogix Client Configuration:
- Install FSLogix components on AVD session hosts
- Configure registry settings for profile containers
- Set up profile container size and location
- Configure profile container type (VHDX, dynamic)

# Security Considerations:
- Enable storage firewall and restrict to AVD subnet
- Implement Private Endpoints for enhanced security
- Configure NTFS permissions on file share
- Enable encryption at rest

# User and Group Setup:
- Configure RBAC for user access to profiles
- Set up folder redirection policies if needed
- Plan profile container organization

# Testing:
- Validate user profile roaming
- Test login/logout scenarios
- Verify application settings persistence
- Measure profile load times