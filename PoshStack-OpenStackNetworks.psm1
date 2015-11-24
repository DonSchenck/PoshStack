<############################################################################################

PoshStack
Databases

    
Description
-----------
**TODO**

############################################################################################>

function Script:Get-Provider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride = $null
    )

	$Provider = Get-OpenStackNetworkProvider -Account $Account
	
    if ($RegionOverride){
        $Global:RegionOverride = $RegionOverride
    }

    # Use Region code associated with Account, or was an override provided?
    if ($RegionOverride) {
        $Region = $Global:RegionOverride
    } else {
        $Region = $Credentials.Region
    }

    Add-Member -InputObject $Provider -MemberType NoteProperty -Name Region -Value $Region

	Return $Provider

}

function Get-OpenStackNetworkProvider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter")
    )

    # The Account comes from the file CloudAccounts.csv
    # It has information regarding credentials and the type of provider (Generic or Rackspace)

    Get-OpenStackAccount -Account $Account
    if ($RegionOverride){
        $Global:RegionOverride = $RegionOverride
    }

    # Use Region code associated with Account, or was an override provided?
    if ($RegionOverride) {
        $Region = $Global:RegionOverride
    } else {
        $Region = $Credentials.Region
    }


    # Is this Rackspace or Generic OpenStack?
    switch ($Credentials.Type)
    {
        "Rackspace" {
            # Get Identity Provider
            $cloudId    = New-Object net.openstack.Core.Domain.CloudIdentity
            $cloudId.Username = $Credentials.CloudUsername
            $cloudId.APIKey   = $Credentials.CloudAPIKey
            $Global:CloudId = New-Object net.openstack.Providers.Rackspace.CloudIdentityProvider($cloudId)
            Return New-Object net.openstack.Providers.Rackspace.CloudNetworksProvider($cloudId)

        }
        "OpenStack" {
            $CloudIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
            $CloudIdentityWithProject.Password = $Credentials.CloudPassword
            $CloudIdentityWithProject.Username = $Credentials.CloudUsername
            $CloudIdentityWithProject.ProjectId = New-Object net.openstack.Core.Domain.ProjectId($Credentials.TenantId)
            $CloudIdentityWithProject.ProjectName = $Credentials.TenantId
            $Uri = New-Object System.Uri($Credentials.IdentityEndpointUri)
            $OpenStackIdentityProvider = New-Object net.openstack.Core.Providers.OpenStackIdentityProvider($Uri, $CloudIdentityWithProject)
            Return New-Object net.openstack.Providers.Rackspace.CloudNetworksProvider($OpenStackIdentityProvider)
        }
    }
}

# Issue 20 Implement Remove-CloudNetwork
function Remove-OpenStackNetwork {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $NetworkID = $(throw "Please specify the required Network ID by using the -NetworkID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackNetwork"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "NetworkID.......................: $NetworkID"
        Write-Debug -Message "RegionOverride..................: $RegionOverride" 
        Write-Debug -Message "Region..........................: $Region" 

        $Provider.DeleteNetwork($NetworkID, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove network

 .DESCRIPTION
 The Remove-OpenStackNetwork cmdlet will remove a network.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER NetworkID
 The ID of the network to be removed.
 
  .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-networks.html
#>
}

# Issue 22 Implement New-CloudNetwork
function New-OpenStackNetwork {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $NetworkName = $(throw "Please specify the required Network Name by using the -NetworkName parameter"),
        [Parameter (Mandatory=$True)] [string] $CIDR = $(throw "Please specify the required CIDR (e.g. 10.1.0.0/24) by using the -CIDR parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackNetwork"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "NetworkName.....................: $NetworkName"
        Write-Debug -Message "CIDR............................: $CIDR"
        Write-Debug -Message "RegionOverride..................: $RegionOverride" 
        Write-Debug -Message "Region..........................: $Region" 

        $Provider.CreateNetwork($CIDR, $NetworkName, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create a network

 .DESCRIPTION
 The New-OpenStackNetwork cmdlet will create a network.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER NetworkName
 The user-friendly name to be assigned to the network.
 
 .PARAMETER CIDR
 The inter-domain routing settings, e.g. 10.1.0.0/24.
  
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-networks.html
#>
}

# Issue 23 Implement Get-CloudNetwork
function Get-OpenStackNetwork {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][string] $NetworkID = $null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackNetwork"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "NetworkID.......................: $NetworkID"
        Write-Debug -Message "RegionOverride..................: $RegionOverride" 
        Write-Debug -Message "Region..........................: $Region" 

        IF([string]::IsNullOrEmpty($NetworkID)) {    
            $Provider.ListNetworks($Provider.Region, $Null)
        } else {
            $Provider.ShowNetwork($NetworkID, $Provider.Region, $Null)
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get network

 .DESCRIPTION
 The Get-OpenStackNetwork cmdlet will retrieve one or more cloud networks.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER NetworkID
 Use this parameter if you wish to retrieve one specific network. If omitted, all networks for the region will be retrieved.
 
  .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-networks.html
#>
}


Export-ModuleMember -Function *
