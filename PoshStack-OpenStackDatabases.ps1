<############################################################################################

PoshStack
Databases

    
Description
-----------
**TODO**

############################################################################################>

function Get-OpenStackDatabasesProvider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride = $(throw "Please specify required Region by using the -RegionOverride parameter")
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
            Return New-Object net.openstack.Providers.Rackspace.CloudDatabasesProvider($cloudId, $Region, $Null)

        }
        "OpenStack" {
            $CloudIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
            $CloudIdentityWithProject.Password = $Credentials.CloudPassword
            $CloudIdentityWithProject.Username = $Credentials.CloudUsername
            $CloudIdentityWithProject.ProjectId = New-Object net.openstack.Core.Domain.ProjectId($Credentials.TenantId)
            $CloudIdentityWithProject.ProjectName = $Credentials.TenantId
            $Uri = New-Object System.Uri($Credentials.IdentityEndpointUri)
            $OpenStackIdentityProvider = New-Object net.openstack.Core.Providers.OpenStackIdentityProvider($Uri, $CloudIdentityWithProject)
            Return New-Object net.openstack.Providers.Rackspace.CloudDatabasesProvider($Null, $Region, $OpenStackIdentityProvider)
        }
    }
}

# Issue 135
function Confirm-OpenStackDatabaseRootEnabledStatus {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID by using the -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Confirm-OpenStackDatabaseRootEnabledStatus"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        $iid = New-Object ([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId

        $ComputeDatabasesProvider.CheckRootEnabledStatusAsync($iid, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 138
function New-OpenStackDatabaseInstance {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceName = $(throw "Please specify required Database Instance Name by using the -InstanceName parameter"),
        [Parameter (Mandatory=$True)] [string] $FlavorId = $(throw "Please specify required Database Flavor Id by using the -FlavorId parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][int]    $SizeInGB = 5,
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackDatabaseInstance"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "InstanceName..: $InstanceName"
        Write-Debug -Message "FlavorId......: $FlavorId"
        Write-Debug -Message "WaitForTask...: $WaitForTask"
        Write-Debug -Message "SizeinGB......: $SizeInGB"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        $flavorref = New-Object ([net.openstack.Providers.Rackspace.Objects.Databases.FlavorRef]) $FlavorId
        $dbVolumeConfig = New-Object ([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseVolumeConfiguration]) $SizeInGB
        $dbInstanceConfig = New-Object -Type ([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceConfiguration]) -ArgumentList @($flavorref, $dbVolumeConfig, $InstanceName)

        if($WaitForTask) {
            $ComputeDatabasesProvider.CreateDatabaseInstanceAsync($dbInstanceConfig, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $ComputeDatabasesProvider.CreateDatabaseInstanceAsync($dbInstanceConfig, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create a new database instance.

 .DESCRIPTION
 The New-OpenStackDatabaseInstance cmdlet will create a new database instance.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER InstanceName
 Use this parameter to assign a friendly name to the instance.

 .PARAMETER FlavorId
 Use this parameter to specify the size of the RAM for the database.

 .PARAMETER WaitForBuild
 Use this parameter to specify whether you want to wait for the build to complete or return control to the script immediately.

 .PARAMETER SizeInGB
 Use this parameter to specify the size of the database.
 If not specified, it will be 5 GB.
  
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> New-OpenStackDatabaseInstance -Account rackiad -InstanceName "ToBeDeleted" -FlavorId 2 -SizeInGB 5 -WaitForBuild $False

 .LINK
 http://docs.rackspace.com/cdb/api/v1.0/cdb-devguide/content/POST_createInstance__version___accountId__instances_Database_Instances.html
#>
}

function Get-OpenStackDatabase {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Database Instance Id by using the -InstanceId parameter"),
        [Parameter (Mandatory=$False)][string] $Marker = " ",
        [Parameter (Mandatory=$False)][int]    $Limit = 10000,
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDatabases"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "Marker........: $Marker"
        Write-Debug -Message "Limit.........: $Limit"
        Write-Debug -Message "RegionOverride: $RegionOverride" 


        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        $iid = New-Object ([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $mkr = New-Object ([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseName]) $Marker

        $ComputeDatabasesProvider.ListDatabasesAsync($iid, $mkr, $Limit, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get a list of databases.

 .DESCRIPTION
 The Get-OpenStackDatabase cmdlet allows you to retrieve a list of databases for a given database instance.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER InstanceId
 Use this parameter to specify the instance for which you wish to retrieve the list of databases.
 
 .PARAMETER Marker
 Use this parameter to specify the starting point for your list.
 
 .PARAMETER Limit
 Use this parameter to limit the size of the returned list. The maximum is 10,000 items. You can use paging (by using the Marker parameter) if you need to retrieve more than 10,000 items.
   
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackDatabase -Account demo -InstanceId e67b4aaf-5e6f-4fb8-968b-9a0c4727df67
 This example will retrieve the databases associated with this instance.
 
 .LINK
 http://docs.rackspace.com/cdb/api/v1.0/cdb-devguide/content/GET_getDatabases__version___accountId__instances__instanceId__databases_databases.html
#>
}

function New-OpenStackDatabase {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with the -InstanceId parameter"),
        [Parameter (Mandatory=$True)] [string] $DatabaseName = $(throw "Please specify required Database Name with the -DatabaseName parameter"),
        [Parameter (Mandatory=$False)][string] $CharacterSet = $null,
        [Parameter (Mandatory=$False)][string] $Collate = $null,
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


    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackDatabase"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "DatabaseName..: $DatabaseName"
        Write-Debug -Message "CharacterSet..: $CharacterSet"
        Write-Debug -Message "Collate.......: $Collate"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $dbname = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseName]) $DatabaseName

        if (![string]::IsNullOrEmpty($CharacterSet)) {
            $DBConfiguration = New-Object -TypeName net.openstack.Providers.Rackspace.Objects.Databases.DatabaseConfiguration -ArgumentList @($dbname, $CharacterSet, $Collate)
        } else {
            $DBConfiguration = New-Object -TypeName net.openstack.Providers.Rackspace.Objects.Databases.DatabaseConfiguration -ArgumentList @($dbname)
        }

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $ComputeDatabasesProvider.CreateDatabaseAsync($dbiid, $DBConfiguration, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create a new database.

 .DESCRIPTION
 The New-OpenStackDatabase cmdlet allows you to create a new cloud database.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER InstanceId
 Use this parameter to specify the instance that will contain this database.
 
 .PARAMETER DatabaseName
 Use this parameter to specify a user-friendly name to the database.
  
 .PARAMETER CharacterSet
 When creating a MySQL database, you can use this optional parameter to specify the character set. For more information, see http://dev.mysql.com/doc/refman/5.1/en/charset-general.html.

 .PARAMETER Collate
 When creating a MySQL database, you can use this optional parameter to specify the collating sequence. For more information, see http://dev.mysql.com/doc/refman/5.1/en/charset-general.html.
  
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> New-OpenStackDatabase -Account demo -InstanceId e67b4aaf-5e6f-4fb8-968b-9a0c4727df67 -DatabaseName "MyDatabase"
 This example creates the database "MyDatabase" in the specified instance..
 
 .LINK
 http://docs.rackspace.com/cdb/api/v1.0/cdb-devguide/content/POST_createDatabase__version___accountId__instances__instanceId__databases_databases.html
#>
}

function Get-OpenStackDatabaseInstance {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$False)][string] $InstanceId = $null,
        [Parameter (Mandatory=$False)][string] $Marker = " ",
        [Parameter (Mandatory=$False)][int]    $Limit = 10000,
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDatabases"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if (![string]::IsNullOrEmpty($InstanceId)) {
            # Get one specific instance
            $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
            $ComputeDatabasesProvider.GetDatabaseInstanceAsync($dbiid, $CancellationToken).Result
            
        } else {
            # Get the list of Instances
            $mkr = New-Object ([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $Marker
            $ComputeDatabasesProvider.ListDatabaseInstancesAsync($mkr, $Limit, $CancellationToken).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

function Get-OpenStackDatabaseFlavor {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDatabases"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        $ListOfFlavors = $ComputeDatabasesProvider.ListFlavorsAsync($CancellationToken).Result
        foreach ($dbflavor in $ListOfFlavors) {
            Add-Member -InputObject $dbflavor -MemberType NoteProperty -Name Region -Value $Region
        }
        return $ListOfFlavors

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get the cloud database flavors in a region.

 .DESCRIPTION
 The Get-OpenStackDatabaseFlavors cmdlet retrieves a list of database flavors.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackDatabaseFlavors -Account demo
 This example will get the flavors in the default region for the account "demo".

 .LINK
 http://docs.rackspace.com/cdb/api/v1.0/cdb-devguide/content/GET_getFlavors__version___accountId__flavors_flavors.html
#>
}

# Issue 144
function Get-OpenStackDatabaseUser {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $Username = $(throw "Please specify required User Name with -Username parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDatabaseUser"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "Username......: $Username"
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "Region........: $Region"



        $un = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.UserName]) $Username
        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        
        Return $ComputeDatabasesProvider.GetUserAsync($dbiid, $un, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 154 Implement Remove-OpenStackDatabase
function Remove-OpenStackDatabase {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
        [Parameter (Mandatory=$True)] [string] $DatabaseName = $(throw "Please specify required Database Name with -DatabaseName parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackDatabaseInstance"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "DatabaseName..: $DatabaseName"
        Write-Debug -Message "Region........: $Region"



        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $dbname = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseName]) $DatabaseName
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $ComputeDatabasesProvider.RemoveDatabaseAsync($dbiid, $dbname, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 155 Implement Remove-OpenStackDatabaseInstance
function Remove-OpenStackDatabaseInstance {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackDatabaseInstance"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "Region........: $Region"



        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        $AsyncCompletionOption = New-Object ([net.openstack.Core.AsyncCompletionOption])

        $ComputeDatabasesProvider.RemoveDatabaseInstanceAsync($dbiid, $AsyncCompletionOption, $CancellationToken, $null).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 156 Implement Remove-OpenStackDatabaseUser
function Remove-OpenStackDatabaseUser {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $Username = $(throw "Please specify required User Name with -Username parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackDatabaseUser"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "Username......: $Username"
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "Region........: $Region"


        $un = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.UserName]) $Username
        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        
        $ComputeDatabasesProvider.RemoveUserAsync($dbiid, $un, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 157 Implement Set-OpenStackDatabaseInstanceSize
function Set-OpenStackDatabaseInstanceSize {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $FlavorRef = $(throw "Please specify required Flavor Reference with -FlavorRef parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Set-OpenStackDatabaseInstanceSize"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "FlavorRef.....: $FlavorRef"
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "Region........: $Region"



        $Flavor = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.FlavorRef]) $FlavorRef
        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        $AsyncCompletionOption = New-Object ([net.openstack.Core.AsyncCompletionOption])
        
        $ComputeDatabasesProvider.ResizeDatabaseInstanceAsync($dbiid, $Flavor, $AsyncCompletionOption, $CancellationToken, $null).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 158
function Set-OpenStackDatabaseInstanceVolumeSize {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [int]    $VolumeSizeGB = $(throw "Please specify required Volume Size (in GB) with -VolumeSizeGB parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Set-OpenStackDatabaseInstanceSize"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "VolumeSizeGB..: $VolumeSizeGB"
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "WaitForTask...: $WaitForTask"
        Write-Debug -Message "Region........: $Region"

        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        
        if($WaitForTask) {
            $ComputeDatabasesProvider.ResizeDatabaseInstanceVolumeAsync($dbiid, $VolumeSizeGB, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $ComputeDatabasesProvider.ResizeDatabaseInstanceVolumeAsync($dbiid, $VolumeSizeGB, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 159
function Restart-OpenStackDatabaseInstance {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Update-OpenStackDatabaseUser"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "WaitForTask...: $WaitForTask"
        Write-Debug -Message "Region........: $Region"



        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        If ($WaitForTask) {
            $ComputeDatabasesProvider.RestartDatabaseInstanceAsync($dbiid, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $ComputeDatabasesProvider.RestartDatabaseInstanceAsync($dbiid, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }  
    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 160
function Revoke-OpenStackDatabaseUserAccess {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $Username = $(throw "Please specify required User Name with -Username parameter"),
        [Parameter (Mandatory=$True)] [string] $DatabaseName = $(throw "Please specify required Database Name with -DatabaseName parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Update-OpenStackDatabaseUser"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "Username......: $Username"
        Write-Debug -Message "DatabaseName..: $DatabaseName"
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "Region........: $Region"



        $un = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.UserName]) $Username
        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        
        $ComputeDatabasesProvider.SetUserPasswordAsync($dbiid, $DatabaseName, $un, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Revoke user rights to a database.

 .DESCRIPTION
 The Revoke-OpenStackDatabaseUserAccess cmdlet allows you to revoke a user's access to a database.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER Username
 The user name of the person who's access you wish to revoke.

 .PARAMETER DatabaseName
 The database from which to revoke access.

 .PARAMETER InstanceId
 The Instance ID used to identify the cloud database.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Revoke-OpenStackDatabaseUserAccess -Account rackiad -Username "myusername" -DatabaseName "MyDB" -InstanceId "e67b4aaf-5e6f-4fb8-968b-9a0cxxxxxxx" 
 This example will revoke access for user "myusername" from the database "MyDB" in the given instance.

 .LINK
 http://http://api.rackspace.com/api-ref-databases.html
#>
}
# Issue 161
function Set-OpenStackDatabaseUserPassword {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $Username = $(throw "Please specify required User Name with -Username parameter"),
        [Parameter (Mandatory=$True)] [string] $NewPassword = $(throw "Please specify required New Password with -NewPassword parameter"),
        [Parameter (Mandatory=$True)] [string] $InstanceId = $(throw "Please specify required Instance ID with -InstanceId parameter"),
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


    $ComputeDatabasesProvider = Get-OpenStackDatabasesProvider -Account $Account -RegionOverride $Region

    try {

        # DEBUGGING       
        Write-Debug -Message "Update-OpenStackDatabaseUser"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "Username......: $Username"
        Write-Debug -Message "NewPassword...: $NewPassword"
        Write-Debug -Message "InstanceId....: $InstanceId"
        Write-Debug -Message "RegionOverride: $RegionOverride" 



        $un = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.UserName]) $Username
        $dbiid = New-Object([net.openstack.Providers.Rackspace.Objects.Databases.DatabaseInstanceId]) $InstanceId
        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        
        $ComputeDatabasesProvider.SetUserPasswordAsync($dbiid, $un, $NewPassword, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Update database use.

 .DESCRIPTION
 The Set-OpenStackDatabaseUserPassword cmdlet allows you to change a user's password.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER Username
 The user name of the person who's password you wish to change.

 .PARAMETER NewPassword
 The new password to be assigned.

 .PARAMETER InstanceId
 The Instance ID used to identify the cloud database.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Update-OpenStackDatabaseUserPassword -Account rackiad -Username "myusername" -NewPassword "MyNewPa55w0rd" -InstanceId "e67b4aaf-5e6f-4fb8-968b-9a0cxxxxxxx" 
 This example will set the password for user "myusername" for the instance specified.

 .LINK
 http://http://api.rackspace.com/api-ref-databases.html
#>
}