<############################################################################################

PoshStack
Load Balancers

    
Description
-----------
**TODO**

############################################################################################>

function Get-OpenStackLBProvider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$false)] [string] $RegionOverride = $null
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
            Return New-Object net.openstack.Providers.Rackspace.CloudLoadBalancerProvider($cloudId, $Region, $null)

        }
        "OpenStack" {
            $CloudIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
            $CloudIdentityWithProject.Password = $Credentials.CloudPassword
            $CloudIdentityWithProject.Username = $Credentials.CloudUsername
            $CloudIdentityWithProject.ProjectId = New-Object net.openstack.Core.Domain.ProjectId($Credentials.TenantId)
            $CloudIdentityWithProject.ProjectName = $Credentials.TenantId
            $Uri = New-Object System.Uri($Credentials.IdentityEndpointUri)
            $OpenStackIdentityProvider = New-Object net.openstack.Core.Providers.OpenStackIdentityProvider($Uri, $CloudIdentityWithProject)
            Return New-Object net.openstack.Providers.Rackspace.CloudLoadBalancerProvider($null, $Region, $OpenStackIdentityProvider)
        }
    }
}

# Issue 49 Implement Add-CloudLoadBalancerMetadata
function Add-OpenStackLBMetadata {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [string[]] $Metadata = $(throw "Please specify the required metadata by using the -Metadata parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackLBMetadata"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Metaadata.......................: $Metadata"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.AddLoadBalancerMetadataAsync($LBID, $Metadata, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.AddLoadBalancerMetadataAsync($LBID, $Metadata, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Add metadata

 .DESCRIPTION
 The Add-OpenStackLBMetadata cmdlet will add metadata to an existing Load Balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the existing Load Balancer.
 
 .PARAMETER Metadata
 An array of key-value pairs containing the metadata.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 50 Implement Add-CloudLoadBalancerNode
function Add-OpenStackLBNode {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeConfiguration] $NodeConfig = $(throw "Please specify the required Node Configuration by using the -NodeConfig parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackLBNode"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "NodeConfig......................: $NodeConfig"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.AddNodeAsync($LBID, $NodeConfig, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.AddNodeAsync($LBID, $NodeConfig, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Add LB Node

 .DESCRIPTION
 The Add-OpenStackLBNode cmdlet will add a Node to an existing Load Balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the existing Load Balancer.
 
 .PARAMETER NodeConfig
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeConfiguration that contains configuration data for new new Node.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 51 Implement Add-CloudLoadBalancerNodeMetadata
function Add-OpenStackLBNodeMetadata {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId] $NodeID = $(throw "Please specify the required Node ID by using the -NodeID parameter"),
        [Parameter (Mandatory=$True)] [string[]] $Metadata = $(throw "Please specify the required metadata by using the -Metadata parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackLBNodeMetadatda"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "NodeID..........................: $NodeID"
        Write-Debug -Message "Metadata........................: $Metadata"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.AddNodeMetadataAsync($LBID, $NodeID, $Metadata, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.AddNodeMetadataAsync($LBID, $NodeID, $Metadata, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Add metadata to node

 .DESCRIPTION
 The New-OpenStackLBNodeMetadata cmdlet will add metadata to an existing Load Balancer Node.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId that identifies the Load Balancer.

 .PARAMETER NodeID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId that identifies the Node.

 .PARAMETER Metadata
 An array of key-value pairs that contains the metadata.
 
 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 52 Implement Add-CloudLoadBalancerNodeRange
function Add-OpenStackLBNodeRange {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeConfiguration[]] $NodeConfigurations = $(throw "Please specify the required Node Configurations by using the -NodeConfigurations parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackLBNodeRange"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "NodeConfigurations..............: $NodeConfigurations"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.AddNodeRangeAsync($LBID, $NodeConfigurations, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.AddNodeRangeAsync($LBID, $NodeConfigurations, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Add node range

 .DESCRIPTION
 The Add-OpenStackLBNodeRange cmdlet will add one or more nodes to a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId that identifies the Load Balancer.

 .PARAMETER NodeConfigurations
 An array of objects of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeConfiguration containing the nodes to be added.
 
 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 53 Implement Add-CloudLoadBalancerVirtualAddress
function Add-OpenStackLBVirtualAddress {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerVirtualAddressType] $LBVirtAddrType = $(throw "Please specify the required Load Balancer Virtual Address Type to using the -LBVirtAddrType parameter"),
        [Parameter (Mandatory=$True)] [System.Net.Sockets.AddressFamily] $AddressFamily = $(throw "Please specify the required Address Family by using the required -AddressFamily parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackLBVirtualAddress"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "LBVirtAddrType..................: $LBVirtAddrType"
        Write-Debug -Message "AddressType.....................: $AddressType"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.AddVirtualAddressAsync($LBID, $LBVirtAddrType, $AddressFamily, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.AddVirtualAddressAsync($LBID, $LBVirtAddrType, $AddressFamily, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create Load Balancer

 .DESCRIPTION
 The New-OpenStackLoadBalancer cmdlet will create a new load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBConfig
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerConfiguration that describes the new Load Balancer.
 
 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 54 Implement Clear-CloudLoadBalancerAccessList
function Clear-OpenStackLBAccessList {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Clear-OpenStackLBAccessList"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.ClearAccessListAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.ClearAccessListAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Clear the access list.

 .DESCRIPTION
 The Clear-OpenStackLBAccessList cmdlet will clear a load balancer's access list entries.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 55 Implement New-CloudLoadBalancer
function New-OpenStackLoadBalancer {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerConfiguration] $LBConfig = $(throw "Please specify the required Load Balancer Configuration by using the -LBConfig parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackLoadBalancer"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBConfig........................: $LBConfig"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.CreateLoadBalancerAsync($LBConfig, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.CreateLoadBalancerAsync($LBConfig, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create Load Balancer

 .DESCRIPTION
 The New-OpenStackLoadBalancer cmdlet will create a new load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBConfig
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerConfiguration that describes the new Load Balancer.
 
 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 56 Implement Get-CloudLoadBalancerConnectionLogging
function Get-OpenStackLBConnectionLogging {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBConnectionLogging"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.GetConnectionLoggingAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get logging status

 .DESCRIPTION
 The Get-OpenStackLBConnectionLogging cmdlet will allow you to query to see if the Load Balancer has connection logging enabled.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 57 Implement Get-CloudLoadBalancerContentCaching
function Get-OpenStackLBContentCaching {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBContentCaching"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.GetContentCachingAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get content caching status

 .DESCRIPTION
 The Get-OpenStackLBContentCaching cmdlet will allow you to query to see if the Load Balancer has content caching enabled.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 58 Implement Get-CloudLoadBalancerErrorPage
function Get-OpenStackLBErrorPage {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBErrorPage"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.GetErrorPageAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get error page

 .DESCRIPTION
 The Get-OpenStackLBErrorPage cmdlet gets the HTML content of the page which is shown to an end user who is attempting to access a load balancer node that is offline or unavailable.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 59 Implement Get-CloudLoadBalancerHealthMonitor
function Get-OpenStackLBHealthMonitor {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "c"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.GetHealthMonitorAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get health monitor

 .DESCRIPTION
 The GetHealthMonitorAsync cmdlet gets the health monitor currently configured for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>

}

# Issue 60 Implement Get-CloudLoadBalancer
# Issue 75 Implement Get-CloudLoadBalancers
function Get-OpenStackLoadBalancer {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $null,
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $Marker = $null,
        [Parameter (Mandatory=$False)][int]    $Limit = 100,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLoadBalancer"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Marker..........................: $Marker"
        Write-Debug -Message "Limit...........................: $Limit"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        IF([string]::IsNullOrEmpty($LBID)) {    
            $LBProvider.ListLoadBalancersAsync($Marker, $Limit, $CancellationToken).Result
        } else {
            $LBProvider.GetLoadBalancerAsync($LBID, $CancellationToken).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create Load Balancer

 .DESCRIPTION
 The New-OpenStackLoadBalancer cmdlet will create a new load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBConfig
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerConfiguration that describes the new Load Balancer.
 
 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 61 Implement Get-CloudLoadBalancerMetadataItem
# Issue 74 Implement Get-CloudLoadBalancerMetadata
function Get-OpenStackLBMetadata {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.MetadataId] $MetadataID = $null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBMetadata"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "MetadataID......................: $MetadataID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        IF([string]::IsNullOrEmpty($MetadataID)) {    
            $LBProvider.ListLoadBalancerMetadataAsync($LBID, $CancellationToken).Result
        } else {
            $LBProvider.GetLoadBalancerMetadataItemAsync($LBID, $MetadataID, $CancellationToken).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get metadata.

 .DESCRIPTION
 The Get-OpenStackLBMetadata cmdlet will get metadata for a Load Balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId that identifies the Load Balancer.
 
 .PARAMETER MetadataID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.MetadataId that identifies a specific Load Balancer metadata item.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 62 Implemented Get-CloudLoadBalancerNode
# Issue 77 Implemeneed Get-CloudLoadBalancerNodes
function Get-OpenStackLBNode {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeID] $NodeID = $null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBNode"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "NodeID..........................: $NodeID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        IF([string]::IsNullOrEmpty($NodeID)) {    
            $LBProvider.ListNodesAsync($LBID, $CancellationToken).Result
        } else {
            $LBProvider.GetNodeAsync($LBID, $NodeID, $CancellationToken).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get a node

 .DESCRIPTION
 The Get-OpenStackLBNode cmdlet will create one or more Load Balancer Nodes.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId that identifies the Load Balancer.
 
 .PARAMETER NodeID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId that identifies a specific Load Balancer Node.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 63 Implement Get-CloudLoadBalancerNodeMetadataItem
# Issue 76 Implement List-CloudLoadBalancerNodeMetadata
function Get-CloudLoadBalancerNodeMetadataItem {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId] $NodeID = $(throw "Please specify the required Node ID by using the -NodeID parameter"),
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.MetadataId] $MetadataID = $null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-CloudLoadBalancerNodeMetadataItem"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "NodeID..........................: $NodeID"
        Write-Debug -Message "MetadataID......................: $MetadataID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        IF([string]::IsNullOrEmpty($MetadataID)) {    
            $LBProvider.ListNodeMetadataAsync($LBID, $NodeID, $CancellationToken).Result
        } else {
            $LBProvider.GetNodeMetadataItemAsync($LBID, $NodeID, $MetadataID, $CancellationToken).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get metadata for a node.

 .DESCRIPTION
 The Get-CloudLoadBalancerNodeMetadataItem cmdlet will get metadata for a Load Balancer Node.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId that identifies the Load Balancer.
 
 .PARAMETER NodeID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId that identifies the Load Balancer Node..
 
 .PARAMETER MetadataID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.MetadataId that identifies a specific Load Balancer metadata item.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 64 Implement Get-CloudLoadBalancerSessionPersistence
function Get-OpenStackLBSessionPersistence {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBSessionPersistence"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.GetSessionPersistenceAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get session persistence

 .DESCRIPTION
 The Get-OpenStackLBSessionPersistence cmdlet gets the session persistence configuration for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 65 Implement Get-CloudLoadBalancerSslConfiguration
function Get-OpenStackLBSslConfiguration {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBSslConfiguration"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.GetSslConfigurationAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get SSL configuration

 .DESCRIPTION
 The Get-OpenStackLBSslConfiguration cmdlet gets the SSL configuration for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 66 Implement Get-CloudLoadBalancerStatistics
function Get-OpenStackLBStatistics {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBStatistics"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.GetStatisticsAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get statistics

 .DESCRIPTION
 The Get-OpenStackLBStatistics cmdlet gets detailed statistics for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}
# Issue 67 Implement Get-CloudLoadBalancerAccessList
function Get-OpenStackLBAccessList {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBAccessList"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListAccessListAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get access list.

 .DESCRIPTION
 The Get-OpenStackLBAccessList cmdlet gets the access list configuration for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 68 Implement Get-CloudLoadBalancerAccountLevelUsage
function Get-OpenStackLBAccountLevelUsage {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][DateTime] $StartTime = $Null,
        [Parameter (Mandatory=$False)][DateTime] $EndTime = $Null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBAccountLevelUsage"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "StartTime.......................: $StartTime"
        Write-Debug -Message "EndTime.........................: $EndTime"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListAccountLevelUsageAsync($StartTime, $EndTime, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get list of algorithms.

 .DESCRIPTION
 The Get-OpenStackLBAccountLevelUsage cmdlet gets a list of all possible Load Balancer algorithms.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.
 
 .PARAMETER StartTime
 The start date to consider. The time component, if any, is ignored. If the value is null, the result includes all usage prior to the specified endTime.

 .PARAMETER EndTime
 The end date to consider. The time component, if any, is ignored. If the value is null, the result includes all usage following the specified startTime.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 69 Implement Get-CloudLoadBalancerAlgorithms
function Get-OpenStackLBAlgorithmList {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBAlgorithmList"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListAlgorithmsAsync($CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get list of algorithms.

 .DESCRIPTION
 The Get-OpenStackLBAlgorithmList cmdlet gets a list of all possible Load Balancer algorithms.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 70 Implemented Get-CloudLoadBalancerAllowedDomains
function Get-OpenStackLBAllowedDomainList {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBAllowedDomainList"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListAllowedDomainsAsync($CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get list of allowed domains.

 .DESCRIPTION
 The Get-ListAllowedDomainsAsync cmdlet gets the domain name restrictions in place for adding load balancer nodes.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 71 Implemented Get-CloudLoadBalancerBillableLBs
function Get-OpenStackLBBillableLBs {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][DateTime] $StartTime = $Null,
        [Parameter (Mandatory=$False)][DateTime] $EndTime = $Null,
        [Parameter (Mandatory=$False)][int]    $Offset = 0,
        [Parameter (Mandatory=$False)][int]    $Limit = $Null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBBillableLBs"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "StartTime.......................: $StartTime"
        Write-Debug -Message "EndTime.........................: $EndTime"
        Write-Debug -Message "Offset..........................: $Offset"
        Write-Debug -Message "Limit...........................: $Limit"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListBillableLoadBalancersAsync($StartTime, $EndTime, $Offset, $Limit, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get list of algorithms.

 .DESCRIPTION
 The Get-OpenStackLBBillableLBs cmdlet gets a list of billable Load Balancers.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER StartTime
 The start date to consider. The time component, if any, is ignored. If the value is null, the result includes all usage prior to the specified endTime.

 .PARAMETER EndTime
 The end date to consider. The time component, if any, is ignored. If the value is null, the result includes all usage following the specified startTime.

 .PARAMETER Offset
 The index of the last item in the previous page of results. If the value is null, the list starts at the beginning.

 .PARAMETER Limit
 Gets the maximum number of load balancers to return in a single page of results. If the value is null, a provider-specific default value is used.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 72 Implement Get-CloudLoadBalancerCurrentUsage
function Get-OpenStackLBCurrentUsage {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBCurrentUsage"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListCurrentUsageAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get usage.

 .DESCRIPTION
 The Get-OpenStackLBCurrentUsage cmdlet lists all usage for a specific load balancer during a preceding 24 hours
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 73 Implement Get-CloudLoadBalancerHistoricalUsage
function Get-OpenStackLBHistoricalUsage {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][DateTime] $StartTime = $Null,
        [Parameter (Mandatory=$False)][DateTime] $EndTime = $Null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBHistoricalUsage"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "StartTime.......................: $StartTime"
        Write-Debug -Message "EndTime.........................: $EndTime"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListHistoricalUsageAsync($LBID, $StartTime, $EndTime, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get historical usage.

 .DESCRIPTION
 The Get-OpenStackLBHistoricalUsage cmdlet lists all usage for a specific load balancer during a specified date range.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER StartTime
 The start date to consider. The time component, if any, is ignored. If the value is null, the result includes all usage prior to the specified endTime.

 .PARAMETER EndTime
 The end date to consider. The time component, if any, is ignored. If the value is null, the result includes all usage following the specified startTime.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 78 Implemented Get-CloudLoadBalancerNodeServiceEvents
function Get-OpenStackLBNodeServiceEvent {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeServiceEventId] $MarkerID = $(throw "Please specify the required Marker ID by using the -MarkerID parameter"),
        [Parameter (Mandatory=$False)][int]    $Limit = 100,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBNodeServiceEvent"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "MarkerID........................: $MarkerID"
        Write-Debug -Message "Limit...........................: $Limit"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListNodeServiceEventsAsync($LBID, $MarkerID, $Limit, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get service events.

 .DESCRIPTION
 The Get-OpenStackLBNodeServiceEvent cmdlet lists the service events for a load balancer node
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER MarkerID
 The net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeServiceEvent.Id of the last item in the previous list. If the value is null, the list starts at the beginning.

 .PARAMETER Limit
 Indicates the maximum number of items to return. Used for . If the value is null, a provider-specific default value is used.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 79 Implemented Get-CloudLoadBalancerProtocols
function Get-OpenStackLBProtocolList {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBProtocolList"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListProtocolsAsync($CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get list of protocols.

 .DESCRIPTION
 The Get-OpenStackLBProtocolList cmdlet gets a collection of supported load balancing protocols.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue #80 Implement Get-CloudLoadBalancerThrottles
function Get-OpenStackLBThrottleList {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBThrottleList"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListThrottlesAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get throttling configuration.

 .DESCRIPTION
 The Get-OpenStackLBThrottleList cmdlet gets the connection throttling configuration for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 81 Implement Get-CloudLoadBalancerVirtualAddresses
function Get-OpenStackLBVirtualAddressList {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackLBVirtualAddressList"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.ListVirtualAddressesAsync($LBID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get virtual address list.

 .DESCRIPTION
 The Get-OpenStackLBVirtualAddressList cmdlet gets the virtual addresses for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 82 Implement Remove-CloudLoadBalancerAccessList
# Issue 83 Implement Remove-CloudLoadBalancerAccessListRange
function Remove-OpenStackLBAccessList {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.NetworkItemId] $NetworkItemID = $Null,
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.NetworkItemId[]] $ListOfNetworkItemIDs = $Null,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBAccessList"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "NetworkItemID...................: $NetworkItemID"
        Write-Debug -Message "ListOfNetworkItemIDs............: $ListOfNetworkItemIDs"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if (![string]::IsNullOrEmpty($NetworkItemID)) {
            if($WaitForTask) {
                $LBProvider.RemoveAccessListAsync($LBID, $NetworkItemID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
            } else {
                $LBProvider.RemoveAccessListAsync($LBID, $NetworkItemID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
            }
        } else {
            if($WaitForTask) {
                $LBProvider.RemoveAccessListRangeAsync($LBID, $ListOfNetworkItemIDs, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
            } else {
                $LBProvider.RemoveAccessListRangeAsync($LBID, $ListOfNetworkItemIDs, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
            }
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove access list.

 .DESCRIPTION
 The Remove-OpenStackLBAccessList cmdlet will remove a network item from the access list of a load balancer..
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER NetworkItemID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.NetworkItemId that identifies the network.

 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 84 Implement Remove-CloudLoadBalancerErrorPage
function Remove-OpenStackLBErrorPage {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBErrorPage"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.RemoveErrorPageAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.RemoveErrorPageAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove error page.

 .DESCRIPTION
 The Remove-OpenStackLBErrorPage cmdlet will remove the error page for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 85 Implement Remove-CloudLoadBalancerHealthMonitor
function Remove-OpenStackLBHealthMonitor {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBHealthMonitor"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.RemoveHealthMonitorAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.RemoveHealthMonitorAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove health monitor

 .DESCRIPTION
 The Remove-OpenStackLBHealthMonitor cmdlet will remove the health monitors for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 86 Implemented Remove-CloudLoadBalancer
# Issue 88 Implemented Remove-CloudLoadBalancerRange
function Remove-OpenStackLoadBalancer {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $null,
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId[]] $ListOfLBIDs = $null,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLoadBalancer"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "ListOfLBIDs.....................: $ListOfLBIDs"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if (![string]::IsNullOrEmpty($LBID)) {
            if($WaitForTask) {
                $LBProvider.RemoveLoadBalancerAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
            } else {
                $LBProvider.RemoveLoadBalancerAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
            }
        } else {
            if($WaitForTask) {
                $LBProvider.RemoveLoadBalancerRangeAsync($ListOfLBIDs, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
            } else {
                $LBProvider.RemoveLoadBalancerRangeAsync($ListOfLBIDs, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
            }
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove a load balancer.

 .DESCRIPTION
 The Remove-OpenStackLoadBalancer cmdlet will remove a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue #87 Implemented Remove-CloudLoadBalancerMetadataItem
function Remove-OpenStackLBMetadataItem {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.MetaDataId[]]   $ListOfMetaDataID = $(throw "Please specify the required list of Metadata IDs by using the -ListOfMetadataID parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBMetadataItem"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "ListOfMetadataID................: $ListOfMetaDataID"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.RemoveLoadBalancerMetadataItemAsync($LBID, $ListOfMetaDataID, $CancellationToken).Result
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove metadata.

 .DESCRIPTION
 The Remove-OpenStackLBMetadataItem cmdlet will remove one or more metadata items from a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.
 
 .PARAMETER ListOfMetaDataID
 A list of metadata ids that indicate which metadata items to be removed.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 89 Implemented Remove-CloudLoadBalancerNode
function Remove-OpenStackLBNode {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $null,
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId] $NodeID = $null,
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId[]] $ListOfNodeIDs = $null,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBNode"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "NodeID..........................: $NodeID"
        Write-Debug -Message "ListOfNodeIDs...................: $ListOfNodeIDs"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if (![string]::IsNullOrEmpty($NodeID)) {
            if($WaitForTask) {
                $LBProvider.RemoveNodeAsync($LBID, $NodeID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
            } else {
                $LBProvider.RemoveNodeAsync($LBID, $NodeID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
            }
        } else {
            if($WaitForTask) {
                $LBProvider.RemoveNodeRangeAsync($LBID, $ListOfNodeIDs, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
            } else {
                $LBProvider.RemoveNodeRangeAsync($LBID, $ListOfNodeIDs, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
            }
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove one or more nodes.

 .DESCRIPTION
 The Remove-OpenStackLBNode cmdlet will remove a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER NodeID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId that identifies a single node to be removed.

 .PARAMETER ListOfNodeIDs
 A list of nodes to be removed.
 
 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 90 Implement Remove-CloudLoadBalancerNodeMetadataItem
function Remove-OpenStackLBNodeMetadataItem {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId] $NodeID = $(throw "Please specify the required Node ID by using the -NodeID parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.MetadataId[]] $ListOfMetadataIDs = $(throw "Please specify the required list of Metadata IDs by using the -ListOfMetadataIDs parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBNodeMetadataItem"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "NodeID..........................: $NodeID"
        Write-Debug -Message "ListOfNodeIDs...................: $ListOfMetadataIDs"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $LBProvider.RemoveNodeMetadataItemAsync($LBID, $NodeID, $ListOfMetadataIDs, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove one or more node metadata items.

 .DESCRIPTION
 The Remove-OpenStackLBNodeMetadataItem cmdlet will remove one or more metadata items associated with a load balancer node.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER NodeID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.NodeId that identifies a the node.

 .PARAMETER ListOfMetadataIDs
 A list of metadata items to be removed.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 92 Implement Remove-CloudLoadBalancerSessionPersistence
function Remove-OpenStackLBSessionPersistence {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBSessionPersistence"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.RemoveSessionPersistenceAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.RemoveSessionPersistenceAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove session persistence.

 .DESCRIPTION
 The Remove-OpenStackLBSessionPersistence cmdlet will remove the session persistence configuration for a load balancer
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 93 Implement Remove-CloudLoadBalancerSslConfiguration
function Remove-OpenStackLBSSLConfiguration {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBSSLConfiguration"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.RemoveSslConfigurationAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.RemoveSslConfigurationAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove SSL Configuration.

 .DESCRIPTION
 The Remove-OpenStackLBSSLConfiguration cmdlet will remove the SSL configuration for a load balancer
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 94 Implement Remove-CloudLoadBalancerThrottles
function Remove-OpenStackLBThrottle {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBThrottle"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.RemoveThrottlesAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.RemoveThrottlesAsync($LBID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove SSL Configuration.

 .DESCRIPTION
 The Remove-OpenStackLBThrottle cmdlet will remove the connection throttling configuration for a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 95 Implement Remove-CloudLoadBalancerVirtualAddress
# Issue 96 Implement Remove-CloudLoadBalancerVirtualAddressRange
function Remove-OpenStackLBVirtualAddress {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $null,
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.VirtualAddressId] $VirtualAddressID = $null,
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.LoadBalancers.VirtualAddressId[]] $ListOfVirtualAddressIDs = $null,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackLBVirtualAddress"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "VirtualAddressID................: $VirtualAddressID"
        Write-Debug -Message "ListOfVirtualAddressIDs.........: $ListOfVirtualAddressIDs"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if (![string]::IsNullOrEmpty($VirtualAddressID)) {
            if($WaitForTask) {
                $LBProvider.RemoveVirtualAddressAsync($LBID, $VirtualAddressID, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
            } else {
                $LBProvider.RemoveVirtualAddressAsync($LBID, $VirtualAddressID, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
            }
        } else {
            if($WaitForTask) {
                $LBProvider.RemoveVirtualAddressRangeAsync($LBID, $ListOfVirtualAddressIDs, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
            } else {
                $LBProvider.RemoveVirtualAddressRangeAsync($LBID, $ListOfVirtualAddressIDs, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
            }
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove one or more nodes.

 .DESCRIPTION
 The Remove-OpenStackLBVirtualAddress cmdlet will remove one or more virtual addresses associated with a load balancer.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER VirtualAddressID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.VirtualAddressId that identifies a single virtual address to be removed.

 .PARAMETER ListOfVirtualAddressIDs
 A list of virtual addresses to be removed.
 
 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 97 Implement Set-CloudLoadBalancerConnectionLogging
function Set-OpenStackLBConnectionLogging {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][bool]   $Enabled = $True,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Set-OpenStackLBConnectionLogging"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Enabled.........................: $Enabled"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.SetConnectionLoggingAsync($LBID, $Enabled, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.SetConnectionLoggingAsync($LBID, $Enabled, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Enable/Disable Connection Logging.

 .DESCRIPTION
 The Set-OpenStackLBConnectionLogging cmdlet will allow you to enable or disable a load balancer's connection logging.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER Enabled
 True turns on Connection Logging, False turns it off.

 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 98 Implement Set-CloudLoadBalancerContentCaching
function Set-OpenStackLBContentCaching {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$False)][bool]   $Enabled = $True,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Set-OpenStackLBContentCaching"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Enabled.........................: $Enabled"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.SetContentCachingAsync($LBID, $Enabled, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.SetContentCachingAsync($LBID, $Enabled, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Enable/Disable content caching.

 .DESCRIPTION
 The Set-OpenStackLBContentCaching cmdlet will allow you to enable or disable a load balancer's content caching.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER Enabled
 True turns on Content Caching, False turns it off.

 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

# Issue 99 Implement Set-CloudLoadBalancerErrorPage
function Set-OpenStackLBErrorPage {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId] $LBID = $(throw "Please specify the required Load Balancer ID by using the -LBID parameter"),
        [Parameter (Mandatory=$True)] [string] $Content = $(throw "Please specify the required HTML Content for the error page by using the -Content parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

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


    $LBProvider = Get-OpenStackLBProvider -Account rackiad -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Set-OpenStackLBErrorPage"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "LBID............................: $LBID"
        Write-Debug -Message "Content.........................: $Content"
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "Region..........................: $Region" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $LBProvider.SetErrorPageAsync($LBID, $Content, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $LBProvider.SetErrorPageAsync($LBID, $Content, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Set error page HTML.

 .DESCRIPTION
 The Set-OpenStackLBErrorPage cmdlet sets the HTML content of the custom error page which is shown to an end user who is attempting to access a load balancer node that is offline or unavailable..
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER LBID
 An object of type net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerID that identifies the Load Balancer.

 .PARAMETER Content
 The HTML content of the error page.

 .PARAMETER WaitForTask
 Specifies whether the calling function will wait for this task to complete (True) or continue without waiting (False).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-load-balancers.html
#>
}

Export-ModuleMember -Function *
