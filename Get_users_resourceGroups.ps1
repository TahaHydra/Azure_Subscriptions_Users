Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Initialize an array to hold all role assignments
$allRoleAssignments = @()

# Function to get all users in a group, including nested groups
function Get-GroupMembers($groupId, $groupName) {
    $members = Get-AzADGroupMember -GroupObjectId $groupId
    $allMembers = @()
    foreach ($member in $members) {
        if ($member.ObjectType -eq "Group" -or $member.UserPrincipalName -like "*GRP*" -or $member.DisplayName -like "*GRP*") {
            $nestedMembers = Get-GroupMembers -groupId $member.Id -groupName $groupName
            $allMembers += $nestedMembers
        } else {
            $allMembers += [PSCustomObject]@{
                UserPrincipalName = $member.UserPrincipalName
                DisplayName = $member.DisplayName
                GroupName = $groupName
            }
        }
    }
    return $allMembers
}

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    $subscriptionId = $subscription.SubscriptionId
    $subscriptionName = $subscription.Name

    # Set the context to the specified subscription
    Set-AzContext -SubscriptionId $subscriptionId

    # Define the scope at the subscription level
    $scope = "/subscriptions/$subscriptionId"

    # Get Azure RBAC role assignments at the subscription level
    $roleAssignments = Get-AzRoleAssignment -Scope $scope

    # Filter role assignments to exclude resource groups
    $filteredRoleAssignments = $roleAssignments | Where-Object { $_.Scope -notlike "/subscriptions/*/managementGroups/*" }

    # Expand groups to list all users
    foreach ($assignment in $filteredRoleAssignments) {
        if ($assignment.ObjectType -eq "Group" -or $assignment.SignInName -like "*GRP*" -or $assignment.DisplayName -like "*GRP*") {
            $groupMembers = Get-GroupMembers -groupId $assignment.ObjectId -groupName $assignment.DisplayName
            if ($groupMembers.Count -eq 0) {
                $allRoleAssignments += [PSCustomObject]@{
                    SubscriptionName = $subscriptionName
                    UPN = $assignment.SignInName
                    ObjectType = "Group"
                    RoleDefinitionName = $assignment.RoleDefinitionName
                    DisplayName = $assignment.DisplayName
                    GroupName = ""
                    Scope = "/subscriptions/$subscriptionId$($assignment.Scope)"
                    Commentary = "0 users or groups"
                }
            } else {
                foreach ($member in $groupMembers) {
                    $allRoleAssignments += [PSCustomObject]@{
                        SubscriptionName = $subscriptionName
                        UPN = $member.UserPrincipalName
                        ObjectType = "User"
                        RoleDefinitionName = $assignment.RoleDefinitionName
                        DisplayName = $member.DisplayName
                        GroupName = $member.GroupName
                        Scope = "/subscriptions/$subscriptionId$($assignment.Scope)"
                        Commentary = ""
                    }
                }
            }
        } else {
            $allRoleAssignments += [PSCustomObject]@{
                SubscriptionName = $subscriptionName
                UPN = $assignment.SignInName
                ObjectType = $assignment.ObjectType
                RoleDefinitionName = $assignment.RoleDefinitionName
                DisplayName = $assignment.DisplayName
                GroupName = ""
                Scope = "/subscriptions/$subscriptionId$($assignment.Scope)"
                Commentary = ""
            }
        }
    }
}

# Export the expanded role assignments to a CSV file
$csvFile = "expanded_role_assignments.csv"
$allRoleAssignments | Select-Object -Property SubscriptionName, UPN, ObjectType, RoleDefinitionName, DisplayName, GroupName, Scope, Commentary | Export-Csv -Path $csvFile -NoTypeInformation

Write-Output ("Expanded role assignments have been exported to " + $csvFile)