<############################################################################################

PoshStack
                                                    Cloud Files

    
Description
-----------
**TODO**

############################################################################################>

function Get-Provider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
		[Parameter (Mandatory=$False)][string] $RegionOverride
        )

	$Provider = Get-OpenStackBlockStorageProvider -Account $Account
		
    if ($RegionOverride){
        $Global:RegionOverride = $RegionOverride
    }

    # Use Region code associated with Account, or was an override provided?
    if ($RegionOverride) {
        $Region = $Global:RegionOverride
    } else {
        $Region = $Credentials.Region
    }

    Add-Member -InputObject $Provider -MemberType NoteProperty -Name Region -Value $Provider.Region

	Return $Provider

}

function Get-OpenStackBlockStorageProvider {
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
            Return New-Object net.openstack.Providers.Rackspace.CloudBlockStorageProvider($OpenStackId)
        }
        "OpenStack" {
            $CloudIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
            $CloudIdentityWithProject.Password = $Credentials.CloudPassword
            $CloudIdentityWithProject.Username = $Credentials.CloudUsername
            $CloudIdentityWithProject.ProjectId = New-Object net.openstack.Core.Domain.ProjectId($Credentials.TenantId)
            $CloudIdentityWithProject.ProjectName = $Credentials.TenantId
            $Uri = New-Object System.Uri($Credentials.IdentityEndpointUri)
            $OpenStackIdentityProvider = New-Object net.openstack.Core.Providers.OpenStackIdentityProvider($Uri, $CloudIdentityWithProject)
            Return New-Object net.openstack.Providers.Rackspace.CloudBlockStorageProvider($Null, $OpenStackIdentityProvider)
        }
    }

}

#Issue #6 New-OpenStackBlockStorageSnapshot
function New-OpenStackBlockStorageSnapshot {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $VolumeId = $(throw "Please specify required Volume ID with the -VolumeId paramter"),
        [Parameter (Mandatory=$False)][bool]   $Force = $False,
        [Parameter (Mandatory=$False)][string] $DisplayName = "None",
        [Parameter (Mandatory=$False)][string] $DisplayDescription = "None",
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackBlockStorageSnapshot"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "VolumeId..........: $VolumeId"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 
        Write-Debug -Message "Force.............: $Force"
        Write-Debug -Message "DisplayName.......: $DisplayName" 
        Write-Debug -Message "DisplayDescription: $DisplayDescription" 

        $Provider.CreateSnapshot($VolumeId, $Force, $DisplayName, $DisplayDescription, $Provider.Region, $null)


    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Creates a new snapshot.

 .DESCRIPTION
 The New-OpenStackBlockStorageSnapshot cmdlet allows you to create a snapshot of an existing volume.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER VolumeId
 The unique identifier of the volume.

 .PARAMETER Force
 $True/$False, indicates whether to snapshot, even if the volume is attached. The default is $False.

 .PARAMETER DisplayName
 Name of the snapshot. The default is None. 

 .PARAMETER DisplayDescription
 Description of snapshot. The default is None. 

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> New-OpenStackBlockStorageSnapshot -Account demo -VolumeId 32233adkjaadhwoun23
 This example will create a snapshot of the volume.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/POST_createSnapshot_v1__tenant_id__snapshots_snapshots.html
#>
}

#Issue #7 New-OpenStackBlockStorageVolume
function New-OpenStackBlockStorageVolume {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [int]    $Size = $(throw "Please specify the required size (in GB, from 100 to 1000) with the -Size parameter"),
        [Parameter (Mandatory=$False)][string] $DisplayDescription,
        [Parameter (Mandatory=$False)][string] $DisplayName,
        [Parameter (Mandatory=$False)][string] $SnapshotId,
        [Parameter (Mandatory=$False)][string] $VolumeType,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackBlockStorageVolume"
        Write-Debug -Message "Size..............: $Size" 
        Write-Debug -Message "DisplayDescription: $DisplayDescription" 
        Write-Debug -Message "DisplayName.......: $DisplayName" 
        Write-Debug -Message "SnapshotId........: $SnapshotId" 
        Write-Debug -Message "VolumeType........: $VolumeType" 
        Write-Debug -Message "Region............: $Region" 

        $Provider.CreateVolume($Size, $DisplayDescription, $DisplayName, $SnapshotId, $VolumeType, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Creates a volume.

 .DESCRIPTION
 The New-OpenStackBlockStorageVolume cmdlet allows you to create a volume.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER Size
 The size (in GB) of the volume. Note: When creating a volume from a snapshot, the volume size must be greater than the snapshot size.

 .PARAMETER DisplayDescription
 A description of the volume.

 .PARAMETER DisplayName
 The name of the volume.

 .PARAMETER SnapshotId
 The snapshot from which to create a volume.

 .PARAMETER VolumeType
 The type of volume to create, either SATA or SSD. The default is SATA.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> New-OpenStackBlockStorageVolme -Account demo -Size 500
 This example will create a 500GB volume.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/POST_createVolume_v1__tenant_id__volumes_volumes.html
#>
}

#Issue #8 Remove-OpenStackBlockStorageSnapshot
function Remove-OpenStackBlockStorageSnapshot {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $SnapshotId = $(throw "Please specify the required snapshot id with the -SnapshotId parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackBlockStorageSnapshot"
        Write-Debug -Message "SnapshotId....: $SnapshotId" 
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $Provider.DeleteSnapshot($SnapshotId, $Provider.Region, $null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Deletes a snapshot.

 .DESCRIPTION
 The Remove-OpenStackBlockStorageSnapshot cmdlet allows you to mark a snapshot for deletion.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER SnapshotId
 The unique identifier of an existing snapshot.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Remove-OpenStackBlockStorageSnapshot -Account demo -SnapshotId ec9038c3-b3ce-4477-a147-55b3a7468997

 This example will remove the snapshot.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/DELETE_deleteSnapshot_v1__tenant_id__snapshots__snapshot_id__snapshots.html
#>
}

#Issue #9 Remove-OpenStackBlockStorageVolume
function Remove-OpenStackBlockStorageVolume {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $VolumeId = $(throw "Please specify the required volume id with the -VolumeId parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackBlockStorageVolume"
        Write-Debug -Message "VolumeId......: $VolumeId" 
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $Provider.DeleteVolume($VolumeId, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Deletes a volume.

 .DESCRIPTION
 The Remove-OpenStackBlockStorageVolume cmdlet allows you to mark a volume for deletion.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER VolumeId
 The unique identifier of an existing volume.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Remove-OpenStackBlockStorageVolume -Account demo -VolumeId ec9038c3-b3ce-4477-a147-55b3a7468997

 This example will remove the volume.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/DELETE_deleteVolume_v1__tenant_id__volumes__volume_id__volumes.html
#>
}

#Issue #10 Get-OpenStackBlockStorageVolumeTypeInfo
function Get-OpenStackBlockStorageVolumeTypeInfo {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $VolumeTypeId = $(throw "Please specify the required volume type id with the -VolumeTypeId parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackBlockStorageVolumeTypeInfo"
        Write-Debug -Message "VolumeTypeId..: $VolumeTypeId" 
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $Provider.DescribeVolumeType($VolumeTypeId, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Gets volume type details.

 .DESCRIPTION
 The Get-OpenStackBlockStorageVolumeTypeInfo cmdlet allows you to get the detail information about a volume type.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER VolumeTypeId
 The unique identifier of an existing volume type.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackBlockStorageVolumeTypeInfo -Account demo -VolumeTypeId ec9038c3-b3ce-4477-a147-55b3a7468997

 This example will remove the volume.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getVolumeType_v1__tenant_id__types__volume_type_id__volume_types.html
#>}

#Issue #11 Get-OpenStackBlockStorageSnapshots
function Get-OpenStackBlockStorageSnapshots {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackBlockStorageSnapshots"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $Provider.ListSnapshots($Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get snapshots (detailed).

 .DESCRIPTION
 The New-OpenStackBlockStorageSnapshot cmdlet allows you to get detailed information for all Block Storage snapshots.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackBlockStorageSnapshots -Account demo
 This example will get all of the snapshots for the default region associated with the account "demo".

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getSnapshotsDetail_v1__tenant_id__snapshots_detail_snapshots.html
#>
}

#Issue #12 Get-OpenStackBlockStorageVolumes
#Issue #13 Get-OpenStackBlockStorageVolume
function Get-OpenStackBlockStorageVolume {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$False)][string] $VolumeId = $Null,
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackBlockStorageVolume"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "VolumeId..........: $VolumeId"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        if ([string]::IsNullOrEmpty($VolumeId)) {
            $Provider.ListVolumes($Provider.Region, $Null)
        } else {
            $Provider.ShowVolume($VolumeId, $Provider.Region, $Null)
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get volumes (detailed).

 .DESCRIPTION
 The Get-OpenStackBlockStorageVolume cmdlet allows you to get a collection of volumes with detailed information for each.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER VolumeId
 This parameter will allow you to retrieve one, specific Volume.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackBlockStorageVolume -Account demo
 This example will get all of the volumes for the default region associated with the account "demo".

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getVolumesDetail_v1__tenant_id__volumes_detail_volumes.html
#>
}

#Issue #14 Watch-OpenStackBlockStorageVolumeAvailable
function Watch-OpenStackBlockStorageVolumeAvailable {
    Param(
        [Parameter (Mandatory=$True)] [string]   $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]   $VolumeId = $(throw "Please specify required Volume Id with the -VolumeId parameter"),
        [Parameter (Mandatory=$False)][int]      $RefreshCount = 10,
        [Parameter (Mandatory=$False)][timespan] $RefreshDelay = 10,
        [Parameter (Mandatory=$False)][string]   $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Watch-OpenStackBlockStorageVolumeAvailable"
        Write-Debug -Message "Account...........: $Account"
        Write-Debug -Message "VolumeId..........: $VolumeId" 
        Write-Debug -Message "RefreshCount......: $RefreshCount"
        Write-Debug -Message "RefreshDelay......: $RefreshDelay"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $Provider.WaitForVolumeAvailable($VolumeId, $RefreshCount, $RefreshDelay, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Waits for a volume to be set to VolumeState.Available status.

 .DESCRIPTION
 The Watch-OpenStackBlockStorageVolumeAvailable cmdlet allows you to wait until a volume becomes available.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER VolumeId
 The unique identifier of an existing volume.

 .PARAMETER RefreshCount
 The number of times to check the volume status before giving up. Default value is 60.

 .PARAMETER RefreshDelay
 The number of seconds between checks on the volume status. Default value is 10 seconds.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Watch-OpenStackBlockStorageVolumeAvailable -Account demo -VolumeId c569c5eb-1ccc-4702-b64f-e6252a656b66 -RefreshCount 10
 This example will watch the volume, checking every 10 seconds until 10 attempts have been completed or the volume becomes available, whichever comes first.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getVolume_v1__tenant_id__volumes__volume_id__volumes.html
#>
}

#Issue #15 Get-OpenStackBlockStorageSnapshot
function Get-OpenStackBlockStorageSnapshot {
    Param(
        [Parameter (Mandatory=$True)] [string]   $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]   $SnapshotId = $(throw "Please specify required Snapshot Id with the -SnapshotId parameter"),
        [Parameter (Mandatory=$False)][string]   $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackBlockStorageSnapshot"
        Write-Debug -Message "Account...........: $Account"
        Write-Debug -Message "SnapshotId........: $SnapshotId" 
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $Provider.ShowSnapshot($SnapshotId, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get all information about a single snapshot.

 .DESCRIPTION
 The Get-OpenStackBlockStorageSnapshot cmdlet allows you to get all the information for a single snapshot.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER SnapshotId
 The unique identifier of an existing snapshot.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackBlockStorageSnapshot -Account demo -SnapshotId c569c5eb-1ccc-4702-b64f-e6252a656b66
 This example will get the detail information for the snapshot.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getSnapshot_v1__tenant_id__snapshots__snapshot_id__snapshots.html
#>
}

#Issue #16 Get-OpenStackBlockStorageVolumeTypes
function Get-OpenStackBlockStorageVolumeType {
    Param(
        [Parameter (Mandatory=$True)] [string]   $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$False)][string]   $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackBlockStorageVolumeType"
        Write-Debug -Message "Account...........: $Account"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $Provider.ListVolumeTypes($Provider.Region, $null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get a list of volume types.

 .DESCRIPTION
 The Get-OpenStackBlockStorageVolumeType cmdlet allows you to get a list of all available volume types.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackBlockStorageVolumeType -Account demo
 This example will get the volume types for the default region associated with the account 'demo'.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getVolumeTypes_v1__tenant_id__types_volume_types.html
#>
}

#Issue #17 Watch-OpenStackBlockStorageSnapshotAvailable
function Watch-OpenStackBlockStorageSnapshotAvailable {
    Param(
        [Parameter (Mandatory=$True)] [string]   $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]   $SnapshotId = $(throw "Please specify required Snapshot Id with the -SnapshotId parameter"),
        [Parameter (Mandatory=$False)][int]      $RefreshCount = 600,
        [Parameter (Mandatory=$False)][datetime] $RefreshDelay = $Null,
        [Parameter (Mandatory=$False)][string]   $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Watch-OpenStackBlockStorageSnapshotAvailable"
        Write-Debug -Message "Account...........: $Account"
        Write-Debug -Message "SnapshotId........: $SnapshotId" 
        Write-Debug -Message "RefreshCount......: $RefreshCount"
        Write-Debug -Message "RefreshDelay......: $RefreshDelay"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $Provider.WaitForSnapshotAvailable($SnapshotId, $RefreshCount, $RefreshDelay, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Waits for a snapshot to be set to SnapshotState.Available status.

 .DESCRIPTION
 The Watch-OpenStackBlockStorageSnapshotAvailable cmdlet allows you to wait until a snapshot becomes available.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER SnapshotId
 The unique identifier of an existing snapshot.

 .PARAMETER RefreshCount
 The number of times to check the volume status before giving up. Default value is 60.

 .PARAMETER RefreshDelay
 The number of seconds between checks on the volume status. Default value is 10 seconds.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Watch-OpenStackBlockStorageSnapshotAvailable -Account demo -SnapshotId c569c5eb-1ccc-4702-b64f-e6252a656b66 -RefreshCount 10
 This example will watch the snapshot, checking every 10 seconds until 10 attempts have been completed or the snapshot becomes available, whichever comes first.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getSnapshot_v1__tenant_id__snapshots__snapshot_id__snapshots.html
#>
}

#Issue #18 Watch-OpenStackBlockStorageVolumeDeleted
function Watch-OpenStackBlockStorageVolumeDeleted {
    Param(
        [Parameter (Mandatory=$True)] [string]   $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]   $VolumeId = $(throw "Please specify required Volume Id with the -VolumeId parameter"),
        [Parameter (Mandatory=$False)][int]      $RefreshCount = 10,
        [Parameter (Mandatory=$False)][Timespan] $RefreshDelay = 10,
        [Parameter (Mandatory=$False)][string]   $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Watch-OpenStackBlockStorageVolumeDeleted"
        Write-Debug -Message "Account...........: $Account"
        Write-Debug -Message "VolumeId..........: $VolumeId" 
        Write-Debug -Message "RefreshCount......: $RefreshCount"
        Write-Debug -Message "RefreshDelay......: $RefreshDelay"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 
        
        $Provider.WaitForVolumeDeleted($VolumeId, $RefreshCount, $RefreshDelay, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Waits for a volume to be deleted.

 .DESCRIPTION
 The Watch-OpenStackBlockStorageVolumeDeleted cmdlet allows you to wait until a volume is deleted.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER VolumeId
 The unique identifier of an existing volume.

 .PARAMETER RefreshCount
 The number of times to check the volume status before giving up. Default value is 60.

 .PARAMETER RefreshDelay
 The number of seconds between checks on the volume status. Default value is 10 seconds.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Watch-OpenStackBlockStorageVolumeDeleted -Account demo -VolumeId c569c5eb-1ccc-4702-b64f-e6252a656b66 -RefreshCount 10
 This example will watch the volume, checking every 10 seconds until 10 attempts have been completed or the volume is deleted, whichever comes first.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getVolume_v1__tenant_id__volumes__volume_id__volumes.html
#>
}

#Issue #19 Watch-OpenStackBlockStorageVolumeState
function Watch-OpenStackBlockStorageVolumeState {
    Param(
        [Parameter (Mandatory=$True)] [string]   $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]   $VolumeId = $(throw "Please specify required Volume Id with the -VolumeId parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Core.Domain.VolumeState]   $ExpectedState = $(throw "Please specify required Expected State with the -ExpectedState parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Core.Domain.VolumeState[]] $ErrorStates = $(throw "Please specify required Error States with the -ErrorStates parameter"),
        [Parameter (Mandatory=$False)][int]      $RefreshCount = 10,
        [Parameter (Mandatory=$False)][timespan] $RefreshDelay = 10,
        [Parameter (Mandatory=$False)][string]   $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Watch-OpenStackBlockStorageVolumeState"
        Write-Debug -Message "Account...........: $Account"
        Write-Debug -Message "VolumeId..........: $VolumeId" 
        Write-Debug -Message "ExpectedState.....: $ExpectedState"
        Write-Debug -Message "ErrorStates.......: $ErrorStates"
        Write-Debug -Message "RefreshCount......: $RefreshCount"
        Write-Debug -Message "RefreshDelay......: $RefreshDelay"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $Provider.WaitForVolumeState($VolumeId, $ExpectedState, $ErrorStates, $RefreshCount, $RefreshDelay, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Waits for a volume to be set to a particular VolumeState.

 .DESCRIPTION
 The Watch-OpenStackBlockStorageVolumeState cmdlet allows you to wait until a volume reaches a particular state.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file. You can also view them by executing the Show-CloudAccounts cmdlet.

 .PARAMETER VolumeId
 The unique identifier of an existing volume.

 .PARAMETER ExpectedState
 The expected state for the volume.
 
 .PARAMETER ErrorStates
 The error state(s) in which to stop polling once reached.

 .PARAMETER RefreshCount
 The number of times to poll the volume. Default value is 10.

 .PARAMETER RefreshDelay
 The refresh delay. The default value is 10 seconds.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Watch-OpenStackBlockStorageVolumeState -Account demo  -RegionOverride DFW -RefreshCount 2 -RefreshDelay (New-TimeSpan -seconds 3) -VolumeId 5267a607-f51f-4340-a870-529147cd9f1a -ExpectedState ([net.openstack.Core.Domain.VolumeState]::Available) -ErrorStates ([net.openstack.Core.Domain.VolumeState]::Creating)
 This example will watch the volume, checking every 3 seconds until 2 attempts have been completed or the volume is available, whichever comes first.

 .LINK
 http://docs.rackspace.com/cbs/api/v1.0/cbs-devguide/content/GET_getVolume_v1__tenant_id__volumes__volume_id__volumes.html
#>
}

Export-ModuleMember -Function *