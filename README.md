# Azure Subscriptions Users Script Suite

## Overview
This repository contains three PowerShell scripts designed to extract detailed role assignments for users and groups within Azure subscriptions, management groups, and resource groups. These scripts ensure comprehensive visibility of Azure RBAC assignments, expand groups to list individual members, and address limitations in Microsoft's default behavior.

## Scripts Included
1. **Get_All_users.ps1**:
   - Loops through all Azure subscriptions accessible to your account and retrieves role assignments at the subscription level.
   - Expands nested groups (marked with "GRP") to include all individual users.

2. **Get_users_ManagementGroups.ps1**:
   - Targets Azure management groups to extract role assignments, including nested group members.

3. **Get_users_ResourceGroups.ps1**:
   - Focuses on role assignments at the resource group level, expanding nested groups for individual users.

## Important Notes on Group Handling
### Group Identification
In this specific implementation, **all groups in the environment include "GRP" in their name or UserPrincipalName**. This naming convention is used to:
- **Identify groups reliably** during processing.
- **Avoid treating groups as users**, which is a limitation of the default behavior of `Get-AzADGroupMember` that sometimes outputs groups as users.

### Warning
If your environment uses a different naming convention for groups:
- Update the group identification logic in the scripts to match your naming convention.
- Failing to do so may result in **nested groups being incorrectly treated as users**, which can lead to inaccurate role assignment exports.
- This issue stems from a limitation in Microsoft's implementation of `Get-AzADGroupMember`, which does not inherently distinguish between groups and users in some scenarios.

## Prerequisites

### Access Requirements
To run these scripts successfully, your Azure account must have:
- **Reader Role** (minimum) at the subscription level for listing role assignments.
- **Azure Active Directory permissions** to read group membership (e.g., Azure AD Reader or equivalent).

### Tools and Modules
Ensure the following are installed and available:
1. **PowerShell 7.x** or higher.
2. **Azure PowerShell Module**:
   - Install using `Install-Module -Name Az -AllowClobber -Scope CurrentUser`.

## Features
- **Subscription Looping**: Automatically loops through all subscriptions your account has access to, even if Azure enforces selecting a single subscription during login.
- **Group Expansion**: Extracts all nested members of Azure AD groups, recursively resolving group hierarchies.
- **Role Filtering**: Focuses only on relevant scopes (e.g., subscriptions, management groups, or resource groups).
- **CSV Export**: Outputs results in `CSV` format for further analysis.

## Script Details

### Get_All_users.ps1
#### Purpose:
Retrieves and expands Azure RBAC role assignments for all users and groups across all subscriptions.

#### Usage:
1. Login to Azure:
   ```powershell
   Connect-AzAccount
   ```
2. Run the script:
   ```powershell
   .\Get_All_users.ps1
   ```
3. Output:
   A CSV file named `expanded_role_assignments.csv` is generated with the following columns:
   - SubscriptionName
   - UPN
   - ObjectType (User or Group)
   - RoleDefinitionName
   - DisplayName
   - GroupName
   - Scope
   - Commentary

---

### Get_users_ManagementGroups
## License
This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
