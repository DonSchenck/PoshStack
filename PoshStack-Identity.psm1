<############################################################################################

PoshStack
    Identity


Description
-----------
PowerShell v5 module for interaction with OpenStack

Identity v2.0 API reference
---------------------------
https://developer.rackspace.com/docs/cloud-identity/v2/developer-guide/

############################################################################################>


function Get-OpenStackIdentityProvider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter")
        )

    # The Account comes from the file CloudAccounts.csv
    # It has information regarding credentials and the type of provider (Generic or Rackspace)

    Get-OpenStackAccount -Account $Account

    # Is this Rackspace or Generic OpenStack?
    switch ($Credentials.Type)
    {
        "Rackspace" {
            # Get Identity Provider
            $OpenStackId    = New-Object net.openstack.Core.Domain.CloudIdentity
            $OpenStackId.Username = $Credentials.CloudUsername
            $OpenStackId.APIKey   = $Credentials.CloudAPIKey
            $Global:OpenStackId = New-Object net.openstack.Providers.Rackspace.CloudIdentityProvider($OpenStackId)
            Return $Global:OpenStackId
        }
        "OpenStack" {
            $CloudIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
            $CloudIdentityWithProject.Password = $Credentials.CloudPassword
            $CloudIdentityWithProject.Username = $Credentials.CloudUsername
            $CloudIdentityWithProject.ProjectId = New-Object net.openstack.Core.Domain.ProjectId($Credentials.TenantId)
            $CloudIdentityWithProject.ProjectName = $Credentials.TenantId
            $Uri = New-Object System.Uri($Credentials.IdentityEndpointUri)
            $OpenStackIdentityProvider = New-Object net.openstack.Core.Providers.OpenStackIdentityProvider($Uri, $CloudIdentityWithProject)
            Return $OpenStackIdentityProvider
        }
    }

}

function Get-OpenStackIdentityRole {
    param (
        [Parameter(Mandatory=$True)][string] $Account = $(throw "Please specify required Cloud Account with -Account parameter")
    )

    $OpenStackIdentityProvider = Get-OpenStackIdentityProvider $Account
    $OpenStackIdentityProvider.ListRoles($null, $null, $null, $null)

<#
 .SYNOPSIS
 Get a list of roles defined for the account.

 .DESCRIPTION
 The Get-OpenStackIdentityRoles cmdlet will display a list of roles on the cloud account together with extra details on each. 
 The list includes information about each role. This will include role id, name, wieght, propagation and description.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshNova configuration file.

 .EXAMPLE
 PS C:\> Get-OpenStackIdentityRoles prod
 This example shows how to get a list of all networks currently deployed for prod account.

 .LINK
 https://developer.rackspace.com/docs/cloud-identity/v2/developer-guide/#document-api-operations/role-operations
#>
}

function Get-OpenStackIdentityUser {
    param (
        [Parameter(Position=0,Mandatory=$False)][string] $UserID,
        [Parameter(Position=0,Mandatory=$False)][string] $UserName,
        [Parameter(Position=0,Mandatory=$False)][string] $UserEmail,
        [Parameter(Position=1,Mandatory=$True)][string] $Account = $(throw "Please specify required Cloud Account with -Account parameter")
    )

    $OpenStackIdentityProvider = Get-OpenStackIdentityProvider $Account

    if (-Not [string]::IsNullOrEmpty($UserID)) {
        return $OpenStackIdentityProvider.GetUser($UserID, $null)
    }

    if (-Not [string]::IsNullOrEmpty($UserEmail)) {
        return $OpenStackIdentityProvider.GetUsersByEmail($UserEmail, $null)
    }

    if (-Not [string]::IsNullOrEmpty($UserName)) {
        return $OpenStackIdentityProvider.GetUserByName($UserName, $null)
    }

    $OpenStackIdentityProvider.ListUsers($null)

<#
 .SYNOPSIS
 Get details of a single user, identified by ID, name or email.

 .DESCRIPTION
 The Get-OpenStackIdentityUser cmdlet will retrieve user details for a user, which can be identified by his/her ID, username or email address. 

 The details returned includes user ID, status, creation and update dates/times, default region and email address.

 .PARAMETER Account
 Use this mandatory parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshNova configuration file.

 .PARAMETER $UserID
 Use this optional parameter to identify user by his/her user ID you would like to specify. 

 .PARAMETER $UserName
 Use this optional parameter to identify user by his/her user name you would like to specify. 

 .PARAMETER $UserEmail
 Use this optional parameter to identify user by his/her email you would like to specify. 

 .EXAMPLE
 PS C:\> Get-OpenStackIdentityUser -UserName demouser -Account prod
 This example shows how to get details user demouser in prod account.

 .EXAMPLE
 PS C:\> Get-OpenStackIdentityUser -UserID 12345678 -Account prod
 This example shows how to get details user ID 12345678 in prod account.

 .EXAMPLE
 PS C:\> Get-OpenStackIdentityUser -UserEmail demouser@democorp.com -Account prod
 This example shows how to get details user with email 'demouser@democorp.com' in prod account.

 .LINK
 http://docs.rackspace.com/auth/api/v2.0/auth-client-devguide/content/User_Calls.html
#>
}

function Get-OpenStackIdentityUserRole {
    param (
        [Parameter(Position=0,Mandatory=$True)][string] $UserID = $(throw "Specify the user ID with -UserID"),
        [Parameter(Position=1,Mandatory=$True)][string] $Account = $(throw "Please specify required Cloud Account with -Account parameter")
    )


    $OpenStackIdentityProvider = Get-OpenStackIdentityProvider $Account
    $OpenStackIdentityProvider.GetRolesByUser($UserID, $null)

<#
 .SYNOPSIS
 Get a list roles which a specific user is asigned.

 .DESCRIPTION
 The Get-OpenStackIdentityUserRoles cmdlet will display a list of roles which a user is assigned.
 The list includes role id, name, , propagation and description.

 .PARAMETER Account
 Use this mandatory parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshNova configuration file.

 .PARAMETER $UserID
 Use this mandatory parameter to specify a user by his/her user ID. 

 .EXAMPLE
 PS C:\> Get-OpenStackIdentityUserRoles -UserID 12345678 -Account prod
 This example shows how to get a list of assigned roles for a specific user, identified by his/her user ID.

 .LINK
 http://docs.rackspace.com/auth/api/v2.0/auth-client-devguide/content/GET_listRoles_v2.0_OS-KSADM_roles_Role_Calls.html
#>
}

function New-OpenStackIdentityUser {
    param (
        [Parameter(Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter(Mandatory=$True)] [string] $UserName = $(throw "Specify the user name with -UserName"),
        [Parameter(Mandatory=$True)] [string] $UserEmail = $(throw "Specify the user's email with -UserEmail"),
        [Parameter(Mandatory=$False)][string] $UserPass = $null,
        [Parameter(Mandatory=$False)][bool]   $Enabled = $True
    )

    $OpenStackIdentityProvider = Get-OpenStackIdentityProvider $Account

    $user = New-Object -TypeName net.openstack.Core.Domain.NewUser -ArgumentList @($UserName,$UserEmail,$UserPass,$True)

    return $OpenStackIdentityProvider.AddUser($user, $null)

<#
 .SYNOPSIS
 Create a new cloud user.

 .DESCRIPTION
 The New-OpenStackIdentityUser cmdlet will create a new user.
 The list includes role id, name, , propagation and description.

 .PARAMETER $UserName
 Use this mandatory parameter to specify a username for the new account. 

 .PARAMETER $UserEmail
 Use this mandatory parameter to specify an email address for the new account. 

 .PARAMETER $UserPass
 Use this parameter to specify a password for the new account. 
 If you do not specify this parameter, a secure password will be set for the user and will be included as part of the cmdlet output.

 .PARAMETER $Disabled
 Use this switch parameter to disable the account as soon as it is created.

 .PARAMETER Account
 Use this mandatory parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshNova configuration file.

 .EXAMPLE
 PS C:\> Get-OpenStackIdentityUserRoles -UserID 12345678 -Account prod
 This example shows how to get a list of assigned roles for a specific user, identified by his/her user ID.

 .LINK
 http://docs.rackspace.com/auth/api/v2.0/auth-client-devguide/content/User_Calls.html
#>
}

function Remove-OpenStackIdentityUser {
    param (
        [Parameter(Mandatory=$True)][string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter(Mandatory=$True)][string] $UserID = $(throw "Specify the user ID with -UserID")
    )

    $OpenStackIdentityProvider = Get-OpenStackIdentityProvider $Account
    $OpenStackIdentityProvider.DeleteUser($UserID, $null)
    
}

function Edit-OpenStackIdentityUser {
    param (
        [Parameter(Mandatory=$True)][string]  $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter(Mandatory=$True)][string]  $UserID = $(throw "Specify the user name with -UserID"),
        [Parameter(Mandatory=$False)][string] $UserName,
        [Parameter(Mandatory=$False)][string] $UserEmail,
        [Parameter(Mandatory=$False)][bool]   $Enabled = $True,
        [Parameter(Mandatory=$False)][string] $DefaultRegion
    )

    $OpenStackIdentityProvider = Get-OpenStackIdentityProvider $Account
    $User = Get-OpenStackIdentityUser -Account $Account -UserID $UserID

    if (-Not [string]::IsNullOrEmpty($DefaultRegion)) {
        $User.DefaultRegion = $DefaultRegion
    }

    if (-Not [string]::IsNullOrEmpty($UserEmail)) {
        $User.Email = $UserEmail
    }

    if (-Not [string]::IsNullOrEmpty($UserName)) {
        $UserName = $UserName
    }

    $User.Enabled = $Enabled

    $OpenStackIdentityProvider.UpdateUser($User, $null)


<#
 .SYNOPSIS
 Edit an existing cloud user.

 .DESCRIPTION
 The Edit-OpenStackIdentityUser cmdlet will edit any attributes for an existing user, as supplied via the parameters.
 All optional parameters can be specified as part of the same command.

 .PARAMETER $UserID
 Use this mandatory parameter to identify the user you would like to edit.

 .PARAMETER $UserName
 Use this parameter to edit the username.

 .PARAMETER $UserEmail
 Use this parameter to edit an email address for the account. 

 .PARAMETER $UserPass
 Use this parameter to edit a password for and account. 

 .PARAMETER $Disabled
 Use this switch parameter to disable or enable a user account.

 .PARAMETER Account
 Use this mandatory parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshNova configuration file.

 .EXAMPLE
 PS C:\> Edit-OpenStackIdentityUser -UserID 12345678 -Account prod -UserName "new-user-name" -Disabled false
 This example shows how to change the username for a specific user at the same time as enabling it.

 .LINK
 http://docs.rackspace.com/auth/api/v2.0/auth-client-devguide/content/User_Calls.html
#>
}

function Add-OpenStackIdentityRoleForUser {
    param (
        [Parameter(Position=0,Mandatory=$True)][string] $UserID = $(throw "Specify the user ID with -UserID"),
        [Parameter(Position=1,Mandatory=$True)][string] $RoleID = $(throw "Specify the role ID with -RoleID"),
        [Parameter(Position=2,Mandatory=$True)][string] $Account = $(throw "Please specify required Cloud Account with -Account")
    )

    $OpenStackIdentityProvider = Get-OpenStackIdentityProvider $Account
    $OpenStackIdentityProvider.AddRoleToUser($UserID, $RoleID, $null)

<#
 .SYNOPSIS
 Add role membership for a cloud user.

 .DESCRIPTION
 The Add-OpenStackIdentityRoleForUser cmdlet will add role membership for an existing cloud user.

 .PARAMETER $UserID
 Use this mandatory parameter to identify the user you would like to edit by his/her unique ID.

 .PARAMETER $RoleID
 Use this mandatory parameter used to specify the role ID. Use Get-OpenStackIdentityRoles to see a list of all available roles.

 .PARAMETER $Account
 Use this mandatory parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshNova configuration file.

 .EXAMPLE
 PS C:\> Add-OpenStackIdentityRoleForUser -UserID 12345678 -RoleID 12345678 -Account prod
 This example shows how to modify role assignment for a specific user.

 .LINK
 http://docs.rackspace.com/auth/api/v2.0/auth-client-devguide/content/User_Calls.html
#>
}

function Remove-OpenStackIdentityRoleFromUser {
    param (
        [Parameter(Position=0,Mandatory=$True)][string] $UserID = $(throw "Specify the user ID with -UserID"),
        [Parameter(Position=1,Mandatory=$True)][string] $RoleID = $(throw "Specify the role ID with -RoleID"),
        [Parameter(Position=2,Mandatory=$True)][string] $Account = $(throw "Please specify required Cloud Account with -Account")
    )

    $OpenStackIdentityProvider = Get-OpenStackIdentityProvider $Account
    $OpenStackIdentityProvider.DeleteRoleFromUser($UserID, $RoleID, $null)

<#
 .SYNOPSIS
 Remove role membership from a cloud user.

 .DESCRIPTION
 The Remove-OpenStackIdentityRoleForUser cmdlet will remove role membership for an existing cloud user.

 .PARAMETER $UserID
 Use this mandatory parameter to identify the user you would like to edit by his/her unique ID.

 .PARAMETER $RoleID
 Use this mandatory parameter used to specify the role ID. Use Get-OpenStackIdentityUserRoles to see a list of all currently-assigned roles for this user.

 .PARAMETER $Account
 Use this mandatory parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshNova configuration file.

 .EXAMPLE
 PS C:\> Remove-OpenStackIdentityRoleForUser -UserID 12345678 -RoleID 12345678 -Account prod
 This example shows how to modify role assignment for a specific user.

 .LINK
 http://docs.rackspace.com/auth/api/v2.0/auth-client-devguide/content/User_Calls.html
#>
}

Export-ModuleMember -Function *