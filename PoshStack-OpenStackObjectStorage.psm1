<############################################################################################

PoshStack
                                                    Cloud Files

    
Description
-----------
**TODO**

############################################################################################>

function Script:Get-Provider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required OpenStack Account with -Account parameter"),
		[Parameter (Mandatory=$False)][string] $RegionOverride = $Null
        )

	$Provider = Get-OpenStackObjectStorageProvider -Account $Account

	
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

function Get-OpenStackObjectStorageProvider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required OpenStack Account with -Account parameter")
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
            $Global:openstackId = New-Object net.openstack.Providers.Rackspace.CloudIdentityProvider($openstackId)
            Return New-Object net.openstack.Providers.Rackspace.CloudFilesProvider($openstackId)
        }
        "OpenStack" {
            $openstackIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
            $openstackIdentityWithProject.Password = $Credentials.CloudPassword
            $openstackIdentityWithProject.Username = $Credentials.CloudUsername
            $openstackIdentityWithProject.ProjectId = New-Object net.openstack.Core.Domain.ProjectId($Credentials.TenantId)
            $openstackIdentityWithProject.ProjectName = $Credentials.TenantId
            $Uri = New-Object System.Uri($Credentials.IdentityEndpointUri)
            $openstackIdentityProvider = New-Object net.openstack.Core.Providers.OpenStackIdentityProvider($Uri, $openstackIdentityWithProject)
            Return New-Object net.openstack.Providers.Rackspace.CloudFilesProvider($Null, $openstackIdentityProvider)
        }
    }
}

#CopyStream

#DeleteObject
function Remove-OpenStackObjectStorageObject {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required OpenStack Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $ContainerName= $(throw "Please specify required Container Name with the -ContainerName paramter"),
        [Parameter (Mandatory=$True)] [string] $ObjectName = $(throw "Please specify required object to be deleted with the -ObjectName parameter"),
        [Parameter (Mandatory=$False)][array]  $Headers = $null,
        [Parameter (Mandatory=$False)][bool]   $DeleteSegments = $True,
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackObjectStorageObject"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "Container.....: $ContainerName"
        Write-Debug -Message "RegionOverride: $RegionOverride" 
        Write-Debug -Message "Headers.......: $Headers"
        Write-Debug -Message "ObjectName....: $ObjectName" 
        Write-Debug -Message "DeleteSegments: $DeleteSegments"
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 

        $Provider.DeleteObject($ContainerName, $ObjectName, $Headers, $DeleteSegments, $Provider.Region, $UseInternalUrl, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Delete an object in containers.

 .DESCRIPTION
 The Remove-OpenStackObjectStorageObject cmdlet performs a DELETE operation on an object to permanently remove the object from the storage system (data and metadata).
 Object deletion is processed immediately at the time of the request. Any subsequent GET, HEAD, POST, or DELETE operations return a 404 (Not Found) error unless object versioning is on and other versions exist.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER ContainerName
 The unique identifier of the container.

 .PARAMETER ObjectName
 The unique (within the container) identifier of the object.

 .PARAMETER Headers
 The metadata for the object.

 .PARAMETER DeleteSegments
 Indicates whether the file's segments should be deleted if any exist.

 .PARAMETER UseInternalUrl
 Use the endpoint internal URL instead of the endpoint Public URL. 

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Remove-OpenStackObjectStorageObject -Account demo -ContainerName "MyTestContainer" -ObjectName "Foo"
 This example will delete the object "Foo" in container "MyTestContainer" in the default region for the account "demo".

 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/DELETE_deleteobject_v1__account___container___object__objectServicesOperations_d1e000.html
#>
}

#BulkDelete **TODO**
function Remove-OpenStackObjectStorageObjects {
    Param(
        [Parameter (Mandatory=$True)] [string]    $Account        = $(throw "Please specify required OpenStack Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]    $ContainerName  = $(throw "Please specify required Container Name with the -ContainerName paramter"),
        [Parameter (Mandatory=$True)] [array]     $ItemsToDelete  = $(throw "Please specify required items to be deleted with the -ItemsToDelete parameter"),
        [Parameter (Mandatory=$False)][hashtable] $Headers        = @{},
        [Parameter (Mandatory=$False)][bool]      $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string]    $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackObjectStorageObjects"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "Container.....: $ContainerName"
        Write-Debug -Message "RegionOverride: $RegionOverride" 
        Write-Debug -Message "Headers.......: $Headers"
        Write-Debug -Message "ItemsToDelete.: $ItemsToDelete" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 

        # ItemsToDelete is a hashtable, with the Key being the Container Name, and the Value being an array of Object Names
        # e.g. @{"Container1" = @("Object1", "Object2", "Object4"); "Container2" = @("Object1", "ObjectX")}
        # In this example, three objects are deleted from container "Container1", and two objects are deleted from container "Container2"

        $ItemsArray = New-Object 'System.Collections.Generic.List[hashtable]'
        $hdr = New-Object 'System.Collections.Generic.Dictionary[String,String]'
        
        foreach($Item in $ItemsToDelete){
            $ContainerName
            $Item
            $ThisItem = New-Object 'System.Collections.Generic.Dictionary[String,String]'

            $ThisItem.Add($ContainerName, $Item)
            $ItemsArray.Add($ThisItem)
        }

        $Provider.BulkDelete($ItemsArray, $Headers, $Provider.Region, $UseInternalUrl, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Bulk delete of objects in containers.

 .DESCRIPTION
 The Remove-OpenStackObjectStorageObjects cmdlet allows you to bulk delete multiple objects in multiple containers.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER ContainerName
 The unique identifier of the container.

 .PARAMETER Headers
 The metadata for this container:
 X-Container-Meta-name (Optional)
 Custom container metadata. Replace name at the end of the header with the name for your metadata.

 X-Container-Read (Optional)
 Sets an access control list (ACL) that grants read access. This header can contain a comma-delimited list of users that can read the container (allows the GET method for all objects in the container).

 X-Container-Write (Optional)
 Sets an ACL that grants write access. This header can contain a comma-delimited list of users that can write to the container (allows PUT, POST, COPY, and DELETE methods for all objects in the container).

 X-Versions-Location (Optional)
 Enables versioning on this container. The value is the name of another container. You must UTF-8-encode and then URL-encode the name before you include it in the header. To disable versioning, set the header to an empty string.

 .PARAMETER UseInternalUrl
 Use the endpoint internal URL instead of the endpoint Public URL. 

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> New-CloudFileContainer -Account demo -ContainerName "MyTestContainer"
 This example will create the container "MyTestContainer" in the default region for the account "demo".

 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/PUT_createcontainer_v1__account___container__containerServicesOperations_d1e000.html
#>
}

#CopyObject **TODO**
function Copy-OpenStackObjectStorageObject {
}

#CreateContainer
function New-OpenStackObjectStorageContainer {
    Param(
        [Parameter (Mandatory=$True)] [string]    $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]    $ContainerName = $(throw "Please specify required Container Name with -ContainerName parameter"),
        [Parameter (Mandatory=$False)][hashtable] $Headers,
        [Parameter (Mandatory=$False)][bool]      $UseInternalUrl,
        [Parameter (Mandatory=$False)][string]    $RegionOverride
        )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackObjectStorageContainer"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "RegionOverride: $RegionOverride" 
        Write-Debug -Message "ContainerName.: $ContainerName" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 


        return $Provider.CreateContainer($ContainerName, $Headers, $Provider.Region, $UseInternalUrl, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create a Cloud Files Container.

 .DESCRIPTION
 The New-OpenStackObjectStorageContainer cmdlet creates a Cloud Files container. Containers are storage compartments for your data. The URL-encoded name must be no more than 256 bytes and cannot contain a forward slash character (/). You can create up to 500,000 containers in your Cloud Files account.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER ContainerName
 The unique identifier of the container.

 .PARAMETER Headers
 The metadata for this container:
 X-Container-Meta-name (Optional)
 Custom container metadata. Replace name at the end of the header with the name for your metadata.

 X-Container-Read (Optional)
 Sets an access control list (ACL) that grants read access. This header can contain a comma-delimited list of users that can read the container (allows the GET method for all objects in the container).

 X-Container-Write (Optional)
 Sets an ACL that grants write access. This header can contain a comma-delimited list of users that can write to the container (allows PUT, POST, COPY, and DELETE methods for all objects in the container).

 X-Versions-Location (Optional)
 Enables versioning on this container. The value is the name of another container. You must UTF-8-encode and then URL-encode the name before you include it in the header. To disable versioning, set the header to an empty string.

 .PARAMETER UseInternalUrl
 Use the endpoint internal URL instead of the endpoint Public URL. 

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> New-CloudFileContainer -Account demo -ContainerName "MyTestContainer"
 This example will create the container "MyTestContainer" in the default region for the account "demo".

 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/PUT_createcontainer_v1__account___container__containerServicesOperations_d1e000.html
#>
}

#CreateFormPostUri

#CreateObject **TODO**
function Add-OpenStackObjectStorageObject {
}

#CreateObjectFromFile **TODO**
function Add-OpenStackObjectStorageObjectFromFile {
    Param(
        [Parameter (Mandatory=$True)] [string]    $Account = $(throw "Please specify required OpenStack Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]    $ContainerName = $(throw "Please specify required Container Name with -ContainerName parameter"),
        [Parameter (Mandatory=$True)] [string]    $FilePath = $("Please specify required File Path with the -FilePath parameter"),
        [Parameter (Mandatory=$False)][string]    $ObjectName,
        [Parameter (Mandatory=$False)][string]    $ContentType,
        [Parameter (Mandatory=$False)][int]       $ChunkSize = 4096,
        [Parameter (Mandatory=$False)][hashtable] $Headers = $Null,
        [Parameter (Mandatory=$False)][bool]      $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string]    $RegionOverride
        )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackObjectStorageObjectFromFile"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "cloudId.......: $OpenStackId"
        Write-Debug -Message "RegionOverride: $RegionOverride" 
        Write-Debug -Message "ContainerName.: $ContainerName" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "FilePath......: $FilePath"
        Write-Debug -Message "ObjectName....: $ObjectName"
        Write-Debug -Message "ContentType...: $ContentType"
        Write-Debug -Message "ChunkSize.....: $ChunkSize"
        Write-Debug -Message "Headers.......: $Headers"

        
        $Provider.CreateObjectFromFile($ContainerName, $FilePath, $ObjectName, $ContentType, $ChunkSize, $Headers, $Provider.Region, $null, $UseInternalUrl, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }

<#
 .SYNOPSIS
 Creates or updates the content and metadata for a specified object.

 .DESCRIPTION
 The Add-OpenStackObjectStorageObjectFromFile cmdlet creates a Cloud Files object by reading and uploading the object from the given file path.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER ContainerName
 The unique identifier of the container.

 .PARAMETER FilePath
 The source file path, e.g. "C:\temp\foo.jpg".

 .PARAMETER ObjectName
 The name assigned to the object in the container. If omitted, the file name (from -FilePath) will be used.

 .PARAMETER ContentType
 The content type. If omitted, it will be automatically determined by the file name.

 .PARAMETER ChunkSize
 The buffer size to use for copying streaming data.

 .PARAMETER Headers
 The metadata information for the object.

 .PARAMETER UseInternalUrl
 Use the endpoint internal URL instead of the endpoint Public URL. 

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Add-OpenStackObjectStorageObjectFromFile -Account demo -ContainerName "MyTestContainer" -FilePath "C:\test\helloworld.jpg" -ObjectName "Hello_World.jpg"
 This example will copy the local file "C:\test\helloworld.jpg" to the container "MyTestContainer", in the default region, and rename it to "Hello_World.jpg".

 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/PUT_createobject_v1__account___container___object__objectServicesOperations_d1e000.html
#>
}

#CreateTemporaryPublicUri

#DeleteContainer **TODO**
function Remove-OpenStackObjectStorageContainer {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required OpenStack Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $ContainerName = $(throw "Please specify required Container Name with -ContainerName parameter"),
        [Parameter (Mandatory=$False)][bool]   $DeleteObjects = $False,
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
        )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackObjectStorageContainer"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "cloudId.......: $OpenStackId"
        Write-Debug -Message "RegionOverride: $RegionOverride" 
        Write-Debug -Message "ContainerName.: $ContainerName" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "DeleteObjects.: $DeleteObjects"

        
        $Provider.DeleteContainer($ContainerName, $DeleteObjects, $Provider.Region, $UseInternalUrl, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }

<#
 .SYNOPSIS
 Deletes a Container.

 .DESCRIPTION
 The Remove-OpenStackObjectStorageContainer cmdlet deletes a Cloud Files container. If a Container is not empty, you must use the -DeleteObjects parameter to delete the contents and the Container; otherwise, the Container will not be deleted if it contains objects.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER ContainerName
 The unique identifier of the container.

 .PARAMETER DeleteObjects
 This parameter allows you to delete a Container that contains objects. If this is not set to $TRUE, and if the Container contains objects, the Container will not be deleted.

 .PARAMETER UseInternalUrl
 Use the endpoint internal URL instead of the endpoint Public URL. 

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Remove-CloudFileContainer -Account demo -ContainerName "MyTestContainer"
 This example will delete the container "MyTestContainer" in the default region for the account "demo" only if the container is empty.

 PS C:\Users\Administrator> Remove-CloudFileContainer -Account demo -ContainerName "MyTestContainer" -DeleteObjects $True
 This example will delete the container "MyTestContainer" in the default region for the account "demo"; all of the objects in the container will be deleted.

 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/DELETE_deletecontainer_v1__account___container__containerServicesOperations_d1e000.html
#>
}

#DeleteContainerMetadata **TODO**
function Remove-OpenStackObjectStorageContainerMetadata {
}

#DeleteObjectMetadata **TODO**
function Remove-OpenStackObjectStorageObjectMetadata {
}

#DisableCDNOnContainer **TODO**
function Disable-OpenStackObjectStorageContainerCDN {
}

#DisableStaticWebOnContainer **TODO**
function Disable-OpenStackObjectStorageStaticWebOnContainer {
}

#EnableCDNOnContainer **TODO**
function Enable-OpenStackObjectStorageContainerCDN {
    Param(
        [Parameter (Mandatory=$True)] [string]    $Account = $(throw "Please specify required OpenStack Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string]    $ContainerName = $(throw "Please specify required Container Name with -ContainerName parameter"),
        [Parameter (Mandatory=$True)] [bool]      $LogRetention = $(throw "Please specify required Log Retention value with the -LogRetention parameter"),
        [Parameter (Mandatory=$False)][string]    $RegionOverride
        )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Enable-OpenStackObjectStorageContainerCDN"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "RegionOverride: $RegionOverride" 
        Write-Debug -Message "ContainerName.: $ContainerName" 
        Write-Debug -Message "LogRetention..: $LogRetention" 


        return $Provider.EnableCDNOnContainer($ContainerName, $LogRetention, $Provider.Region, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Enables a container for use with the CDN.

 .DESCRIPTION
 The Enable-CloudFileContainerCDN cmdlet enables a Cloud Files container for use with the CDN. It returns four URIs:
 X-Cdn-Ssl-Uri:       The URI for downloading the object over HTTPS, using SSL.
 X-Cdn-Ios-Uri:       The URI for video streaming that uses HTTP Live Streaming from Apple.
 X-Cdn-Uri:           Indicates the URI that you can combine with object names to serve objects through the CDN.
 X-Cdn-Streaming-Uri: The URI for video streaming that uses HTTP Dynamic Streaming from Adobe.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER ContainerName
 The unique identifier of the container.

 .PARAMETER LogRetention
 To enable log retention on the container.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Enable-OpenStackObjectStorageContainerCDN -Account demo -ContainerName "Container1" -RegionOverride "ORD" -LogRetention $false
 This example will enable the container "Container1" in region "ORD" for the CDN. Logs will not be retained.
 Key   : X-Cdn-Ssl-Uri
 Value : https://028bafb1829649a871c1-6a72eeb73f78514eb83f17de21d72eb7.ssl.cf2.rackcdn.com
 
 Key   : X-Cdn-Ios-Uri
 Value : http://f0aafc8ff1453a3dda4f-6a72eeb73f78514eb83f17de21d72eb7.iosr.cf2.rackcdn.com
 
 Key   : X-Cdn-Uri
 Value : http://f1e2a7f36b07f7d67f47-6a72eeb73f78514eb83f17de21d72eb7.r7.cf2.rackcdn.com
 
 Key   : X-Cdn-Streaming-Uri
 Value : http://e593f92048ccc6711871-6a72eeb73f78514eb83f17de21d72eb7.r7.stream.cf2.rackcdn.com
 
 Key   : X-Trans-Id
 Value : tx77dbefc6b52a4411a98d0-0054a6d053ord1
 
 Key   : Content-Length
 Value : 0

 Key   : Content-Type
 Value : text/html; charset=UTF-8
 
 Key   : Date
 Value : Fri, 02 Jan 2015 17:07:31 GMT

 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/PUT_enableDisableCDNcontainer_v1__account___container__CDN_Container_Services-d1e2632.html
#>
}

#EnableStaticWebOnContainer **TODO**
function Enable-OpenStackObjectStorageStaticWebOnContainer {
}

#ExtractArchive
#ExtractArchiveFromFile
#GetAccountHeaders
#GetAccountMetaData

#GetContainerCDNHeader **TODO*
function Get-OpenStackObjectStorageContainerCDNHeader {
}

#GetContainerHeader **TODO**
function Get-OpenStackObjectStorageHeader {
}

#GetContainerMetaData **TODO**
function Get-OpenStackObjectStorageContainerMetadata {
}

#GetObjectHeaders **TODO**
function Get-OpenStackObjectStorageObjectHeader {
}

#GetObjectMetaData **TODO**
function Get-OpenStackObjectStorageObjectMetadata {
}

#GetObjectSaveToFile **TODO**
function Copy-OpenStackObjectStorageObjectToFile {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required OpenStack Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $ContainerName = $(throw "Please specify required Container Name with the -ContainerName parameter"),
        [Parameter (Mandatory=$True)] [string] $SaveDirectory = $(Throw "Please specify the target file path with the -SaveDirectory parameter"),
        [Parameter (Mandatory=$True)] [string] $ObjectName = $(Throw "Please specify the object name with the -ObjectName parameter"),
        [Parameter (Mandatory=$False)][string] $FileName = $Null,
        [Parameter (Mandatory=$False)][int]    $ChunkSize = 65536,
        [Parameter (Mandatory=$False)][Array]  $Headers = $Null,
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null,
        [Parameter (Mandatory=$False)][bool]   $VerifyETag = $False,
        [Parameter (Mandatory=$False)][long]   $ProgressUpdated = $Null,
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Copy-OpenStackObjectStorageObjectToFile"
        Write-Debug -Message "Account........: $Account" 
        Write-Debug -Message "ContainerName..: $ContainerName"
        Write-Debug -Message "RegionOverride.: $RegionOverride" 
        Write-Debug -Message "SaveDirectory..: $SaveDirectory"
        Write-Debug -Message "ObjectName.....: $ObjectName"
        Write-Debug -Message "FileName.......: $FileName" 
        Write-Debug -Message "ChunkSize......: $ChunkSize" 
        Write-Debug -Message "Headers........: $Headers" 
        Write-Debug -Message "VerifyETag.....: $VerifyETag" 
        Write-Debug -Message "ProgressUpdated: $ProgressUpdated" 
        Write-Debug -Message "UseInternalUrl.: $UseInternalUrl" 

        $Provider.GetObjectSaveToFile($ContainerName, $SaveDirectory, $ObjectName, $FileName, $ChunkSize, $Headers, $Provider.Region, $VerifyETag, $ProgressUpdated, $UseInternalUrl, $Null)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Gets an object, saving the data to the specified file.

 .DESCRIPTION
 The Copy-OpenStackObjectStorageObjectToFile cmdlet will get an object from a container and save it to the local file system.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER ContainerName
 The unique identifier of the container.

 .PARAMETER SaveDirectory
 The local file system path to which to save the object.

 .PARAMETER ObjectName
 The name of the object to be retrieved.

 .PARAMETER FileName
 The name to give the object on the local file system. If omitted, the object name is used.

 .PARAMETER ChunkSize
 The buffer size to use for copying streaming data.

 .PARAMETER Headers
 A collection of custom HTTP headers to include with the request.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .PARAMETER VerifyETag
 If the object includes an ETag, the retrieved data will be verified before returning.

 .PARAMETER ProgressUpdated
 A callback for progress updates. If the value is null, no updates are reported.

 .PARAMETER UseInternalUrl
 Use the endpoint internal URL instead of the endpoint Public URL. 

 .EXAMPLE
 PS C:\Users\Administrator> Copy-OpenStackObjectStorageObjectToFile -Account demo -ContainerName "Container1" -SaveDirectory "C:\temp" -ObjectName "kittens.jpg"
 This example will get the object "kittens.jpg" from the container "Container1" and save it as "C:\temp\kittens.jpg".

 .EXAMPLE
 PS C:\Users\Administrator> Copy-OpenStackObjectStorageObjectToFile -Account demo -ContainerName "Container1" -SaveDirectory "C:\temp" -ObjectName "kittens.jpg" -FileName "kittycat.jpg"
 This example will get the object "kittens.jpg" from the container "Container1" and save it as "C:\temp\kittycat.jpg".


 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/PUT_createcontainer_v1__account___container__containerServicesOperations_d1e000.html
#>
}

#ListCDNContainers **TODO** (use -CDN switch)
#ListContainers **TODO**
function Get-OpenStackObjectStorageContainer {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required OpenStack Account with -Account parameter"),
        [Parameter (Mandatory=$False)][int]    $Limit = 100,
        [Parameter (Mandatory=$False)][string] $Marker = $null,
        [Parameter (Mandatory=$False)][string] $MarkerEnd = $Null,
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][switch] $CDN,
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackObjectStorageContainer"
        Write-Debug -Message "Limit.........: $Limit"
        Write-Debug -Message "Marker........: $Marker"
        Write-Debug -Message "MarkerEnd.....: $MarkerEnd"
        Write-Debug -Message "RegionOverride: $RegionOverride" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        
        If ($CDN) {
            Return $Provider.ListCDNContainers($Limit, $Marker, $MarkerEnd, $True, $Provider.Region, $Null)
        } else {
            Return $Provider.ListContainers($Limit, $Marker, $MarkerEnd, $Provider.Region, $UseInternalUrl, $Null)
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get the containers in a region.

 .DESCRIPTION
 The Get-OpenStackObjectStorageContainer cmdlet lists the storage containers in your account and sorts them by name. The list is limited to 10,000 containers at a time.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER Limit
 This parameter allows you to limit the number of results.

 .PARAMETER Marker
 This parameter allows you to begin the list at a specific container name.

 .PARAMETER MarkerEnd
 This parameter allows you to end the list at a specific container name.

 .PARAMETER UseInternalUrl
 Use the endpoint internal URL instead of the endpoint Public URL. 

 .PARAMETER CDN
 This parameter will return CDN-related information for each container.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackObjectStorageContainer -Account demo
 This example will get the containers in the default region for the account "demo".

 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/GET_listcontainers_v1__account__accountServicesOperations_d1e000.html
#>
}

#ListObjects **TODO**
function Get-OpenStackObjectStorageObject {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required OpenStack Account with -Account parameter"),
        [Parameter (Mandatory=$True)] [string] $ContainerName = $(throw "Please specify required Container with the -ContainerName parameter"),
        [Parameter (Mandatory=$False)][string] $ObjectName = $null,
        [Parameter (Mandatory=$False)][int]    $Limit = 10000,
        [Parameter (Mandatory=$False)][string] $Marker = $null,
        [Parameter (Mandatory=$False)][string] $MarkerEnd = $Null,
        [Parameter (Mandatory=$False)][string] $Prefix = $Null,
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackObjectStorageObjects"
        Write-Debug -Message "ContainerName.: $ContainerName"
        Write-Debug -Message "Limit.........: $Limit"
        Write-Debug -Message "Marker........: $Marker"
        Write-Debug -Message "MarkerEnd.....: $MarkerEnd"
        Write-Debug -Message "Prefix........: $Prefix"
        Write-Debug -Message "RegionOverride: $RegionOverride" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        
        $ListOfObjects = $Provider.ListObjects($ContainerName, $Limit, $Marker, $MarkerEnd, $Prefix, $Provider.Region, $UseInternalUrl, $Null)
        foreach ($obj in $ListOfObjects) {
            Add-Member -InputObject $obj -MemberType NoteProperty -Name Region -Value $Provider.Region
            Add-Member -InputObject $obj -MemberType NoteProperty -Name Container -Value $ContainerName
        }

        Return $ListOfObjects

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get the containers in a region.

 .DESCRIPTION
 The Get-OpenStackObjectStorageContainers cmdlet lists the storage containers in your account and sorts them by name. The list is limited to 10,000 containers at a time.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER Limit
 This parameter allows you to limit the number of results.

 .PARAMETER Marker
 This parameter allows you to begin the list at a specific container name.

 .PARAMETER MarkerEnd
 This parameter allows you to end the list at a specific container name.

 .PARAMETER UseInternalUrl
 Use the endpoint internal URL instead of the endpoint Public URL. 

 .PARAMETER CDN
 This parameter will return CDN-related information for each container.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> Get-OpenStackObjectStorageContainers -Account demo
 This example will get the containers in the default region for the account "demo".

 .LINK
 http://docs.rackspace.com/files/api/v1/cf-devguide/content/GET_listcontainers_v1__account__accountServicesOperations_d1e000.html
#>
}

#MoveObject **TODO**
function Move-OpenStackObjectStorageObject {
}

#PurgeObjectFromCDN **TODO**
function Clear-OpenStackObjectStorageObjectFromCDN {
}

#UpdateAccountMetadata

#UpdateContainerCdnHeaders **TODO**
function Update-OpenStackObjectStorageContainerCDNHeader {
}

#UpdateContainerMetadata **TODO**
function Update-OpenStackObjectStorageContainerMetadata {
}

#UpdateObjectMetadata **TODO**
function Update-OpenStackObjectStorageObjectMetadata {
}

#GetServiceEndpointOpenStackObjectStorage
#GetServiceEndpointOpenStackObjectStorageCDN

#VerifyContainerIsCDNEnabled **TODO**
function Test-OpenStackObjectStorageContainerCDNEnabled {
}

Export-ModuleMember -Function *