<############################################################################################

PoshStack
Cloud Queues

    
Description
-----------
**TODO**

############################################################################################>


function Script:Get-Provider {
    Param(
        [Parameter (Mandatory=$True)]  [string] $Account = $(throw "-Account parameter is required."),
        [Parameter (Mandatory=$False)] [bool]   $UseInternalUrl = $False,
		[Parameter (Mandatory=$False)] [string] $RegionOverride = $Null
        )

    if ($RegionOverride){
        $Global:RegionOverride = $RegionOverride
    }

    # Use Region code associated with Account, or was an override provided?
    if ($RegionOverride) {
        $Region = $Global:RegionOverride
    } else {
        $Region = $Credentials.Region
    }

	$MyGUID = [GUID]::NewGuid()
	$Provider = Get-OpenStackCloudQueueProvider -Account $Account -RegionOverride $Region -UseInternalUrl $UseInternalUrl -QueueGUID $MyGUID 

    Add-Member -InputObject $Provider -MemberType NoteProperty -Name Region -Value $Region
    Add-Member -InputObject $Provider -MemberType NoteProperty -Name UserInternalUrl -Value $UseInternalUrl
	Add-Member -InputObject $Provider -MemberType NoteProperty -Name GUID -Value $MyGUID 

	Return $Provider

}

function Get-OpenStackCloudQueueProvider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "-Account parameter is required."),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride = $null,
		[Parameter (Mandatory=$True)] [Guid]   $QueueGUID = $(throw "-QueueGUID parameter is required.")
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
            Return New-Object net.openstack.Providers.Rackspace.CloudQueuesProvider($cloudId, $Region, $QueueGUID, $UseInternalUrl, $Null)

        }
        "OpenStack" {
            $CloudIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
            $CloudIdentityWithProject.Password = $Credentials.CloudPassword
            $CloudIdentityWithProject.Username = $Credentials.CloudUsername
            $CloudIdentityWithProject.ProjectId = New-Object net.openstack.Core.Domain.ProjectId($Credentials.TenantId)
            $CloudIdentityWithProject.ProjectName = $Credentials.TenantId
            $Uri = New-Object System.Uri($Credentials.IdentityEndpointUri)
            $OpenStackIdentityProvider = New-Object net.openstack.Core.Providers.OpenStackIdentityProvider($Uri, $CloudIdentityWithProject)
            Return New-Object net.openstack.Providers.Rackspace.CloudQueuesProvider($Null, $Region, $QueueGUID, $UseInternalUrl, $OpenStackIdentityProvider)
        }
    }
}

# Issue 372 CreateQueueAsync is implemented
function New-OpenStackCloudQueue {
	    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "-Account parameter is required."),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride = $False,

        [Parameter (Mandatory=$True)] [string] $QueueName = $(throw "-QueueName parameter is required.")
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackCloudQueue"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "QueueName.........: $QueueName"
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $QueueName
        $Provider.CreateQueueAsync($qn, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create a new cloud queue.

 .DESCRIPTION
 The New-OpenStackCloudQueue cmdlet will create a cloud queue.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER QueueGUID
 A GUID that uniquely identifies this queue.

 .PARAMETER UseInternalUrl
 To use the endpoint's net.openstack.Core.Domain.Endpoint.InternalURL; otherwise to use the endpoint's net.openstack.Core.Domain.Endpoint.PublicURL.

 .PARAMETER QueueName
 A friendly name to be assigned to this queue.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> New-OpenStackCloudQueue -Account rackiad -QueueGUID e67b4aaf-5e6f-4fb8-968b-9a0c4727df67 -QueueName "TEST" -UseInternalUrl $False -RegionOverride "IAD"

 .LINK
 https://developer.rackspace.com/docs/cloud-queues/v1/developer-guide/#document-api-reference
#>
}

# Issue 384 ListQueuesAsync is implemented
function Get-OpenStackCloudQueue {
	    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "-Account parameter is required."),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride = $Null,

        [Parameter (Mandatory=$False)][string] $Marker = $Null,
        [Parameter (Mandatory=$False)][int]    $Limit = 100,
        [Parameter (Mandatory=$False)][bool]   $Detailed = $True
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackCloudQueue"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		if (!$Marker) {
	        $Provider.ListQueuesAsync($null, $Limit, $Detailed, $CancellationToken).Result
		} else {
			$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $Marker
	        $Provider.ListQueuesAsync($qn, $Limit, $Detailed, $CancellationToken).Result
		}

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 375 DeleteQueueAsync is implemented
function Remove-OpenStackCloudQueue {
	    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "-Account parameter is required."),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)] [string]$RegionOverride = $Null,

        [Parameter (Mandatory=$True)] [string] $QueueName = $(throw "-QueueName parameter is required.")
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackCloudQueue"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride"
		Write-Debug -Message "QueueName.........: $QueueName" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $QueueName
        $Provider.DeleteQueueAsync($qn, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 379 GetNodeHealthAsync is implemented
function Get-OpenStackCloudQueueNodeHealth {
	    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "-Account parameter is required."),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)] [string]$RegionOverride = $Null
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackCloudQueueNodeHealth"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride"

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
        $Provider.GetNodeHealthAsync($CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 389 SetQueueMetadataAsync is implemented
function Set-OpenStackCloudQueueMetadata {
	Param(
		[Parameter (Mandatory=$True)]  [string] $Account = $(throw "-Account parameter is required."),
		[Parameter (Mandatory=$False)] [bool]   $UseInternalUrl = $False,
		[Parameter (Mandatory=$False)] [string] $RegionOverride = $Null,

		[Parameter (Mandatory=$True)]  [string] $QueueName = $(throw "-QueueName parameter is required."),
		[Parameter (Mandatory=$True)]  [hashtable] $Metadata = $(throw "-Metadata parameter is required.")
	)

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Set-OpenStackCloudQueueMetadata"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride"

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $QueueName

		$md = New-Object ([net.openstack.Core.Domain.Metadata])
		ForEach($item in $Metadata.Keys) {
			$md.Add($item, $Metadata.Get_Item($item))
		}
	    $Provider.SetQueueMetadataAsync($qn, $md, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 380 GetQueueMetadataAsync is implemented
function Get-OpenStackCloudQueueMetadata {
	Param(
		[Parameter (Mandatory=$True)]  [string] $Account = $(throw "-Account parameter is required."),
		[Parameter (Mandatory=$False)] [bool]   $UseInternalUrl = $False,
		[Parameter (Mandatory=$False)] [string] $RegionOverride = $Null,

		[Parameter (Mandatory=$True)]  [string] $QueueName = $(throw "-QueueName parameter is required.")
	)

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenSourceCloudQueueMetadata"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride"

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $QueueName
        $md = $Provider.GetQueueMetadataAsync($qn, $CancellationToken).Result
		$ReturnedHashtable = @{}
		ForEach($item in $md) {
			ForEach($v in $item) {
				$ReturnedHashtable.Add($item.Name, $v.ToString())
			}
		}

		$ReturnedHashtable

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 385 PostMessagesAsync is implemented
function Write-OpenStackCloudQueueMessage {
	Param(
		[Parameter (Mandatory=$True)]  [string] $Account = $(throw "-Account parameter is required."),
		[Parameter (Mandatory=$False)] [bool]   $UseInternalUrl = $False,
		[Parameter (Mandatory=$False)] [string] $RegionOverride = $Null,

		[Parameter (Mandatory=$True)]  [string] $QueueName = $(throw "-QueueName parameter is required."),
		[Parameter (Mandatory=$True)]  [TimeSpan] $TTL = $(throw "-QueueName parameter is required."),
		[Parameter (Mandatory=$True)]  [Object[]] $ListOfMessages = $(throw "-ListOfMessages parameter is required.")
	)

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Write-OpenSourceCloudQueueMessage"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride"

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $QueueName

		# Build list of messages
		$msgList = New-Object ([System.Collections.ObjectModel.Collection[net.openstack.Core.Domain.Queues.Message]])
		ForEach($msg in $ListOfMessages) {
			$jo = New-Object -TypeName ([Newtonsoft.Json.Linq.JObject])
			$jv = New-Object -TypeName ([Newtonsoft.Json.Linq.JValue]) -ArgumentList $msg.ToString()
            $jo.Add("msg", $jv);
			$newmsg = New-Object ([net.openstack.core.Domain.Queues.Message]) $TTL, $jo
			$msgList.Add($newmsg)
		}

        $Provider.PostMessagesAsync($qn, $msgList, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 371 ClaimMessageAsync is implemented
function Read-OpenStackCloudQueueMessage {
	Param(
		[Parameter (Mandatory=$True)]  [string] $Account = $(throw "-Account parameter is required."),
		[Parameter (Mandatory=$False)] [bool]   $UseInternalUrl = $False,
		[Parameter (Mandatory=$False)] [string] $RegionOverride = $Null,

		[Parameter (Mandatory=$True)]  [string] $QueueName = $(throw "-QueueName parameter is required."),
		[Parameter (Mandatory=$True)]  [TimeSpan] $TTL = $(throw "-QueueName parameter is required."),
		[Parameter (Mandatory=$True)]  [TimeSpan] $GracePeriod = $(throw "-GracePeriod parameter is required."),
		[Parameter (Mandatory=$True)]  [int] $NumberToRetrieve = $(throw "-NumberToRetrieve parameter is required.")
	)

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Read-OpenSourceCloudQueueMessage"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride"

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $QueueName

        $Provider.ClaimMessageAsync($qn, $NumberToRetrieve, $TTL, $GracePeriod, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 373 DeleteMessageAsync is implemented
# Issue 374 DeleteMessagesAsync is implemented

function Remove-OpenStackCloudQueueMessage {
	Param(
		[Parameter (Mandatory=$True)]  [string] $Account = $(throw "-Account parameter is required."),
		[Parameter (Mandatory=$False)] [bool]   $UseInternalUrl = $False,
		[Parameter (Mandatory=$False)] [string] $RegionOverride = $Null,

		[Parameter (Mandatory=$True)]  [string] $QueueName = $(throw "-QueueName parameter is required."),
		[Parameter (Mandatory=$True)]  [net.openstack.Core.Domain.Queues.MessageId[]] $ListOfMessageId = $(throw "-ListOfMessageId parameter is required."),
		[Parameter (Mandatory=$True)]  [net.openstack.Core.Domain.Queues.Claim] $Claim = $(throw "-Claim parameter is required.")
	)

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackCloudQueueMessage"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride"

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $QueueName

        $Provider.cqp.DeleteMessagesAsync($qn, $ListOfMessageId, $Claim, $CancellationToken)

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}

# Issue 383 ListMessagesAsync is implemented
# Issue 377 GetMessageAsync is implemented
# Issue 378 GetMessagesAsync is implemented
function Get-OpenStackCloudQueueMessage {
    [CmdletBinding()]
	Param(
		[Parameter(ParameterSetName="List", Mandatory=$True)]
		[Parameter(ParameterSetName="Details", Mandatory=$True)]
		[string] $Account = $(throw "-Account parameter is required."),

		[Parameter(ParameterSetName="List", Mandatory=$False)]
		[Parameter(ParameterSetName="Details", Mandatory=$False)]
		[bool]   $UseInternalUrl = $False,

		[Parameter(ParameterSetName="List", Mandatory=$False)]
		[Parameter(ParameterSetName="Details", Mandatory=$False)]
		[string] $RegionOverride = $Null,

		[Parameter(ParameterSetName="List", Mandatory=$True)]
		[Parameter(ParameterSetName="Details", Mandatory=$True)]
		[string] $QueueName = $(throw "-QueueName parameter is required."),

		[Parameter(ParameterSetName="List", Mandatory=$False)]
		[net.openstack.Core.Domain.Queues.QueuedMessageListId] $Marker = $Null,

		[Parameter(ParameterSetName="Details", Mandatory=$True)]
		[net.openstack.Core.Domain.Queues.MessageId[]] $MessageIDList,

		[Parameter(ParameterSetName="List", Mandatory=$False)]
		[int] $Limit = 100,

		[Parameter(ParameterSetName="List", Mandatory=$False)]
		[bool] $Echo = $True,

		[Parameter(ParameterSetName="List", Mandatory=$False)]
		[bool] $IncludeClaimed = $True
	)

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackCloudQueueMessage"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl"
        Write-Debug -Message "RegionOverride....: $RegionOverride"

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)
		$qn = New-Object ([net.openstack.Core.Domain.Queues.QueueName]) $QueueName

		if ($MessageIDList){
			$Provider.GetMessagesAsync($qn, $MessageIDList, $CancellationToken).Result
		} else {
			if (!$Marker) {
				$Provider.ListMessagesAsync($qn, $null, $Limit, $Echo, $IncludeClaimed, $CancellationToken).Result
			} else {
				$Provider.ListMessagesAsync($qn, $Marker, $Limit, $Echo, $IncludeClaimed, $CancellationToken).Result
			}
		}

    }
    catch {
        Invoke-Exception($_.Exception)
    }
}


Export-ModuleMember -Function *
