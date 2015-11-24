<############################################################################################

PoshStack
Databases

    
Description
-----------
**TODO**

############################################################################################>

function Script:Get-Provider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account with -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
		[Parameter (Mandatory=$False)][string] $RegionOverride
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

	$Provider = Get-OpenStackDNSProvider -Account $Account -RegionOverride $Region -UseInternalUrl $UseInternalUrl

    Add-Member -InputObject $Provider -MemberType NoteProperty -Name Region -Value $Region
    Add-Member -InputObject $Provider -MemberType NoteProperty -Name UserInternalUrl -Value $UseInternalUrl

	Return $Provider

}

function Get-OpenStackDNSProvider {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
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
            Return New-Object net.openstack.Providers.Rackspace.CloudDnsProvider($cloudId, $Region, $UseInternalUrl, $Null)

        }
        "OpenStack" {
            $CloudIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
            $CloudIdentityWithProject.Password = $Credentials.CloudPassword
            $CloudIdentityWithProject.Username = $Credentials.CloudUsername
            $CloudIdentityWithProject.ProjectId = New-Object net.openstack.Core.Domain.ProjectId($Credentials.TenantId)
            $CloudIdentityWithProject.ProjectName = $Credentials.TenantId
            $Uri = New-Object System.Uri($Credentials.IdentityEndpointUri)
            $OpenStackIdentityProvider = New-Object net.openstack.Core.Providers.OpenStackIdentityProvider($Uri, $CloudIdentityWithProject)
            Return New-Object net.openstack.Providers.Rackspace.CloudDnsProvider($Null, $Region, $UseInternalUrl, $OpenStackIdentityProvider)
        }
    }
}

# Issue 24 Implement Add-CloudDNSPtrRecords
function Add-OpenStackDNSPtrRecord {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [string] $ServiceName = $(throw "Please specify the required Service Name by using the -ServiceName parameter"),
        [Parameter (Mandatory=$True)] [System.Uri] $DeviceResourceURI = $(throw "Please specify the required Device Resource URI by using the -DeviceResourceURI parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DnsDomainRecordConfiguration[]] $DnsDomainRecordConfigurationList = $(throw "Please specify the required list of Domain Record Configurations by using the -DnsDomainRecordConfigurationList paramter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackDNSPtrRecord"
        Write-Debug -Message "Account.......................: $Account" 
        Write-Debug -Message "UseInternalUrl..................: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "ServiceName.....................: $ServiceName"
        Write-Debug -Message "DeviceResourceURI...............: $DeviceResourceURI"
        Write-Debug -Message "DnsDomainRecordConfigurationList: $DnsDomainRecordConfigurationList"
        Write-Debug -Message "RegionOverride..................: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.AddPtrRecordsAsync($ServiceName, $DeviceResourceURI, $DnsDomainRecordConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.AddPtrRecordsAsync($ServiceName, $DeviceResourceURI, $DnsDomainRecordConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Add reverse DNS records.

 .DESCRIPTION
 The Copy-OpenStackDNSDomain cmdlet allows you to add reverse DNS records to a cloud resource in the DNS service.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER ServiceName
 The name of the service which owns the cloud resource.
        
 .PARAMETER DeviceResourceURI
 The absolute URI of the cloud resource.

 .PARAMETER DnsDomainRecordConfigurationList
 A collection of type [net.openstack.Providers.Rackspace.Objects.Dns.DnsDomainRecordConfiguration] objects describing the records to add.
         
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator> 


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 25
function Add-OpenStackDNSRecord {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainId = $(throw "Please specify the required Domain Id by using the -DomainId parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DnsDomainRecordConfiguration[]] $DNSDomainRecordConfigurationList = $(throw "Please specify the required lis of DNS Domain Record Configurations by using the -DnsDomainRecordConfigurationList parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackDNSRecord"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "UseInternalUrl..................: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "DomainId........................: $DomainId"
        Write-Debug -Message "DNSDomainRecordConfigurationList: $DNSDomainRecordConfigurationList"
        Write-Debug -Message "RegionOverride..................: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.AddRecordsAsync($DomainId, $DNSDomainRecordConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $DNSServiceProvider.AddRecordsAsync($DomainId, $DNSDomainRecordConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Add DNS records.

 .DESCRIPTION
 The Add-OpenStackDNSRecord cmdlet allows you to add records to a domain in the DNS service.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER DomainId
 This specified the domain.
        
 .PARAMETER DNSDomainRecordConfigurationList
 A collection of objects of type [net.openstack.Providers.Rackspace.Objects.Dns.DnsDomainRecordConfiguration] describing the records to add.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator> 


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 26 Implement Copy-CloudDNSDomain
function Copy-OpenStackDNSDomain {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainId = $(throw "Please specify the required Domain Id by using the -DomainId parameter"),
        [Parameter (Mandatory=$True)] [string] $DomainName = $(throw "Please specify the required Domain Name by using the -DomainName parameter"),
        [Parameter (Mandatory=$False)][bool]   $CloneSubdomains = $null,
        [Parameter (Mandatory=$False)][bool]   $ModifyRecordData = $null,
        [Parameter (Mandatory=$False)][bool]   $ModifyEmailAddress = $null,
        [Parameter (Mandatory=$False)][bool]   $ModifyComment = $null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Copy-OpenStackDNSDomain"
        Write-Debug -Message "Account...........: $Account" 
        Write-Debug -Message "UseInternalUrl....: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask.......: $WaitForTask"
        Write-Debug -Message "DomainId..........: $DomainId"
        Write-Debug -Message "DomainName........: $DomainName"
        Write-Debug -Message "CloneSubdomains...: $CloneSubdomains"
        Write-Debug -Message "ModifyRecordData..: $ModifyRecordData"
        Write-Debug -Message "ModifyEmailAddress: $ModifyEmailAddress"
        Write-Debug -Message "ModifyComment.....: $ModifyComment"
        Write-Debug -Message "RegionOverride....: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.CloneDomainAsync($DomainId, $DomainName, $CloneSubdomains, $ModifyRecordData, $ModifyEmailAddress, $ModifyComment, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.CloneDomainAsync($DomainId, $DomainName, $CloneSubdomains, $ModifyRecordData, $ModifyEmailAddress, $ModifyComment, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Clone a domain.

 .DESCRIPTION
 The Copy-OpenStackDNSDomain cmdlet allows you to clone the DNS entries for one domain to another.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER DomainId
 Use this parameter to specify the domain.

 .PARAMETER DomainName
 Use this parameter to specify the name of the cloned domain.

 .PARAMETER CloneSubdomains
 True to recursively clone subdomains; otherwise, false to only clone the top-level domain and its records. Cloned subdomain configurations are modified the same way that cloned top-level domain configurations are modified. If this is null (or not supplied), a provider-specific default value is used.

 .PARAMETER ModifyRecordData
 True to replace occurrences of the reference domain name with the new domain name in comments on the cloned (new) domain. If this is null (or not supplied), a provider-specific default value is used.

 .PARAMETER ModifyEmailAddress
 True to replace occurrences of the reference domain name with the new domain name in email addresses on the cloned (new) domain. If this is null (or not supplied), a provider-specific default value is used.

 .PARAMETER ModifyComment
 True to replace occurrences of the reference domain name with the new domain name in data fields (of records) on the cloned (new) domain. Does not affect NS records. If this is null (or not supplied), a provider-specific default value is used.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator> 


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 27 Implement New-CloudDNSDomains
function New-OpenStackDNSDomain {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DnsConfiguration] $DNSConfiguration,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "New-OpenStackDNSDomain"
        Write-Debug -Message "Account.........: $Account" 
        Write-Debug -Message "UseInternalUrl..: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask.....: $WaitForTask"
        Write-Debug -Message "DNSConfiguration: $DNSConfiguration"
        Write-Debug -Message "RegionOverride..: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.CreateDomainsAsync($DNSConfiguration, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.CreateDomainsAsync($DNSConfiguration, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Create a domain.

 .DESCRIPTION
 The New-OpenStackDNSDomain cmdlet will create a domain.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against. 
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.
 
 .PARAMETER DNSConfiguration
 This parameter is a complex, nested object of type [net.openstack.Providers.Rackspace.Object.Dns.DnsConfiguration] that contains the complete stack of DNS information for this process.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file. 

 .EXAMPLE
 PS C:\Users\Administrator> N$TTL = New-TimeSpan -Seconds 100
$DnsDomainRecordConfiguration = New-Object -Type ([net.openstack.Providers.Rackspace.Objects.Dns.DnsDomainRecordConfiguration]) -ArgumentList @([net.openstack.Providers.Rackspace.Objects.Dns.DnsRecordType]::A, "name", "data", $TTL, "comment", $null)


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 28 Implement Export-CloudDNSDomain
function Export-OpenStackDNSDomain {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainID = $(throw "Please specify the required Domain ID by using the -DomainID parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Export-OpenStackDNSDomain"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "DomainID......: $DomainID"
        Write-Debug -Message "WaitForTask...: $WaitForTask"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.ExportDomainAsync($DomainId, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.ExportDomainAsync($DomainId, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Export a domain.

 .DESCRIPTION
 The Export-OpenStackDNSDomain cmdlet will export a domain.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER DomainId
 The Domain ID.
 
 .PARAMETER WaitForTask
 This indicates whether the script should wait for this task to complete.

  .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 29 Implement Get-CloudDNSJobStatus
function Get-OpenStackDNSJobStatus {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $Details = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DnsJob] $DNSJob = $(throw "Please specify the required DNS Job by using the -DNSJob parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSJobStatus"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "Details.......: $Details"
        Write-Debug -Message "DNSJob........: $DNSJob"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.GetJobStatusAsync($DNSJob, $Details, $CancellationToken).Result
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get a job's status.

 .DESCRIPTION
 The Get-OpenStackDNSJobStatus cmdlet gets information about an asynchronous task being executed by the DNS service.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER Details
 True to include detailed information about the job; otherwise, defaults to false.

 .PARAMETER DNSJob
 The object of type [net.openstack.Providers.Rackspace.Objects.Dns.DnsJob] to query.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 30 Implement Get-CloudDNSDomainChanges
function Get-OpenStackDNSDomainChange {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainID = $(throw "Please specify the required Domain Id by using the -DomainID parameter"),
        [Parameter (Mandatory=$True)] [DateTimeOffset] $Since = $(throw "Please specify the required starting time by using the -Since parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSDomainChange"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "DomainID......: $DomainID"
        Write-Debug -Message "Since.........: $Since"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListDomainChangesAsync($DomainID, $Since, $CancellationToken).Result
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List domain changes.

 .DESCRIPTION
 The Get-OpenStackDNSJobStatus cmdlet gets information about all changes made to a domain since a specified time.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER DomainID
 The unique identifier of the domain.

 .PARAMETER Since
 The timestamp of the earliest changes to consider. If this is null, a provider-specific default value is used.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 31 Implement Get-CloudDNSDomainDetails
function Get-OpenStackDNSDomainDetail {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainID = $(throw "Please specify the required Domain ID by using the -DomainID parameter"),
        [Parameter (Mandatory=$False)][bool]   $ShowRecords = $False,
        [Parameter (Mandatory=$False)][bool]   $ShowSubdomains = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSDomainDetail"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "DomainID......: $DomainID"
        Write-Debug -Message "ShowRecords...: $ShowRecords"
        Write-Debug -Message "ShowSubdomains: $ShowSubdomains"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListDomainDetailsAsync($DomainID, $ShowRecords, $ShowSubdomains, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List domain details.

 .DESCRIPTION
 The Get-OpenStackDNSDomainDetail cmdlet gets detailed information about a specific domain..

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER DomainID
 The domain ID. This is obtained from net.openstack.Providers.Rackspace.Objects.Dns.DnsDomain.Id.

 .PARAMETER ShowRecords
 $True to populate the net.openstack.Providers.Rackspace.Objects.Dns.DnsDomain.Records property of the result; otherwise, false.

 .PARAMETER ShowSubdomains
 $True to populate the net.openstack.Providers.Rackspace.Objects.Dns.DnsDomain.Subdomains property of the result; otherwise, false.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 32 Implement Get-CloudDNSDomains
function Get-OpenStackDNSDomain {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string] $DomainName = $null,
        [Parameter (Mandatory=$False)][int]    $ListOffset = 0,
        [Parameter (Mandatory=$False)][int]    $ListLimit = 100,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSDomain"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "DomainName....: $DomainName"
        Write-Debug -Message "ListOffset...: $ListOffset"
        Write-Debug -Message "ListLimit: $ListLimit"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListDomainsAsync($DomainName, $ListOffset, $ListLimit, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Get a  domain.

 .DESCRIPTION
 The Get-OpenStackDNSDomain cmdlet gets a domain.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER DomainName
 The name of the domain to be retrieved.

 .PARAMETER ListOffset
 If retrieving a list of ptr records (-Details $false), this indicates the starting point for the retrieval.

 .PARAMETER ListLimit
 If retrieving a list of ptr records (-Details $false), this indicates the number of records to be retrieved.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 33 Implement Get-CloudDNSLimits
function Get-OpenStackDNSLimit {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][net.openstack.Providers.Rackspace.Objects.Dns.LimitType] $LimitType = $null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSLimit"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "OpenStackDNSLimit: $LimitType"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if (![string]::IsNullOrEmpty($LimitType)) {
            $Provider.ListLimitsAsync($LimitType, $CancellationToken).Result
        } else {
            $Provider.ListLimitsAsync($CancellationToken).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List domain limits.

 .DESCRIPTION
 The Get-OpenStackDNSLimit cmdlet gets information about the provider-specific limits of this service.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER LimitType
 The limit type (e.g. LimitType.DomainRecord).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 34 Implement Get-CloudDNSLimitTypes
function Get-OpenStackDNSLimitType {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSLimitType"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListLimitTypesAsync($CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List domain limit types.

 .DESCRIPTION
 The Get-OpenStackDNSLimitType cmdlet gets a list of all available Limit Types. 
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 35 Implement Get-CloudDNSPtrRecordDetails
function Get-OpenStackDNSPtrRecordDetail {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [string] $ServiceName = $(throw "Please specify the required Service Name by using the -ServiceName parameter"),
        [Parameter (Mandatory=$True)] [System.Uri] $DeviceResourceURI = $(throw "Please specify the required Device Resource URI by using the -DeviceResourceURI parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.RecordId] $RecordID = $null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSPtrRecord"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "ServiceName...: $ServiceName"
        Write-Debug -Message "DeviceResourceURI.........: $DeviceResourceURI"
        Write-Debug -Message "RecordID......: $RecordID"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListPtrRecordDetailsAsync($ServiceName, $DeviceResourceURI, $RecordID, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List DNS ptr record details.

 .DESCRIPTION
 The Get-OpenStackDNSPtrRecord cmdlet gets information about reverse DNS records currently associated with a cloud resource in the DNS service.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER ServiceName
 The name of the service being queried.

 .PARAMETER DeviceResourceURI
 The device resource URI.

 .PARAMETER RecordID
 The record ID if retrieving details (-Details $true).

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 36 Implement Get-CloudDNSPrtRecords
function Get-OpenStackDNSPtrRecord {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [string] $ServiceName = $(throw "Please specify the required Service Name by using the -ServiceName parameter"),
        [Parameter (Mandatory=$True)] [System.Uri] $DeviceResourceURI = $(throw "Please specify the required Device Resource URI by using the -DeviceResourceURI parameter"),
        [Parameter (Mandatory=$False)][int]    $ListOffset = $null,
        [Parameter (Mandatory=$False)][int]    $ListLimit = $null,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSPtrRecord"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "ServiceName...: $ServiceName"
        Write-Debug -Message "DeviceResourceURI.........: $DeviceResourceURI"
        Write-Debug -Message "ListOffset....: $ListOffset"
        Write-Debug -Message "ListLimit.....: $ListLimit"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListPtrRecordsAsync($ServiceName, $DeviceResourceURI, $ListOffset, $ListLimit, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List DNS ptr records.

 .DESCRIPTION
 The Get-OpenStackDNSPtrRecord cmdlet gets information about reverse DNS records currently associated with a cloud resource in the DNS service.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER Details
 Set to $True if you wish to retrieve the details.

 .PARAMETER ServiceName
 The name of the service being queried.

 .PARAMETER DeviceResourceURI
 The device resource URI.

 .PARAMETER ListOffset
 If retrieving a list of ptr records (-Details $false), this indicates the starting point for the retrieval.

 .PARAMETER ListLimit
 If retrieving a list of ptr records (-Details $false), this indicates the number of records to be retrieved.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 37 Implement Get-CloudDNSRecordDetails
function Get-OpenStackDNSRecordDetail {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainId = $(throw "Please specify the required Domain ID by using the -DomainId parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.RecordId] $RecordId = $(throw "Please specify the required Record ID by using the -RecordId parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSRecordDetail"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "DomainId......: $DomainId"
        Write-Debug -Message "RecordId......: $RecordId"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListRecordDetailsAsync($DomainId, $RecordId, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List domain record details.

 .DESCRIPTION
 The Get-OpenStackDNSRecordDetail cmdlet gets a list of detail information for the domain/record combination. 
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER DomainId
 The Domain ID.
 
 .PARAMETER RecordID
 The Record ID.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 38 Implement Get-CloudDNSRecords
function Get-OpenStackDNSRecord {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainId = $(throw "Please specify the required Domain ID by using the -DomainId parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DnsRecordType] $RecordType = $(throw "Please specify the required Record Type by using the -RecordType parameter"),
        [Parameter (Mandatory=$True)] [string] $RecordName = $(throw "Please specify the required Record Name by using the -RecordName parameter"),
        [Parameter (Mandatory=$True)] [string] $RecordData = $(throw "Please specify the required Record Data by using the -RecordData parameter"),
        [Parameter (Mandatory=$False)][int]    $ListOffset = $null,
        [Parameter (Mandatory=$False)][int]    $ListLimit = $null,      
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSRecord"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "DomainId......: $DomainId"
        Write-Debug -Message "RecordType....: $RecordType"
        Write-Debug -Message "RecordName....: $RecordName"
        Write-Debug -Message "RecordData....: $RecordData"
        Write-Debug -Message "ListOffset....: $ListOffset"
        Write-Debug -Message "ListLimit.....: $ListLimit"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListRecordsAsync($DomainId, $RecordType, $RecordName, $RecordData, $ListOffset, $ListLimit, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List domain records.

 .DESCRIPTION
 The Get-OpenStackDNSRecord cmdlet gets a list of records for the domain.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER DomainId
 The Domain ID.
 
 .PARAMETER RecordType
 The Record Type, e.g. A, CNAME, etc.
 
 .PARAMETER RecordName
 The Record Name.
 
 .PARAMETER RecordData
 The Record Data.
 
 .PARAMETER ListOffset
 This indicates the starting point for the retrieval.

 .PARAMETER ListLimit
 This indicates the number of records to be retrieved.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 39 Implement Get-CloudDNSSubdomains
function Get-OpenStackDNSSubdomain {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainId = $(throw "Please specify the required Domain ID by using the -DomainId parameter"),
        [Parameter (Mandatory=$False)][int]    $ListOffset = $null,
        [Parameter (Mandatory=$False)][int]    $ListLimit = $null,      
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Get-OpenStackDNSSubdomain"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "DomainId......: $DomainId"
        Write-Debug -Message "ListOffset....: $ListOffset"
        Write-Debug -Message "ListLimit.....: $ListLimit"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        $Provider.ListSubdomainsAsync($DomainId, $ListOffset, $ListLimit, $CancellationToken).Result

    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 List subdomains.

 .DESCRIPTION
 The Get-OpenStackDNSSubdomain cmdlet gets a list of subdomains.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER DomainId
 The Domain ID.
 
 .PARAMETER ListOffset
 This indicates the starting point for the retrieval.

 .PARAMETER ListLimit
 This indicates the number of records to be retrieved.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 40 Implement Remove-CloudDNSDomain
function Remove-OpenStackDNSDomain {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId[]] $ListOfDomainIDs = $(throw "Please specify the list of Domain IDs by using the -ListOfDomainIDs parameter"),
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [bool]   $DeleteSubdomain = $(throw "Please specify the option (true/false) of deleting the subdomains by using the -DeleteSubdomain parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackDNSDomain"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask...: $WaitForTask"
        Write-Debug -Message "ListOfDomainIDs: $ListOfDomainIDs"
        Write-Debug -Message "DeleteSubdomain: $DeleteSubdomain"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)


        if($WaitForTask) {
            $Provider.RemoveDomainsAsync($ListOfDomainIDs, $DeleteSubdomain, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.RemoveDomainsAsync($ListOfDomainIDs, $DeleteSubdomain, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove a domain.

 .DESCRIPTION
 The Remove-OpenStackDNSDomain cmdlet will remove one or more domains and, optionally, the subdomain records.
 
 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER ListOfDomainIDs
 The list of domain IDs to be removed.
 
 .PARAMETER WaitForTask
 This indicates whether the script should wait for this task to complete.
 
 .PARAMETER DeleteSubdomain
 Set to true, the subdomain records will be deleted.

  .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator>


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 41 Implement Remove-CloudDNSPtrRecords
function Remove-OpenStackDNSPtrRecord {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [string] $ServiceName,
        [Parameter (Mandatory=$True)] [System.Uri]    $ServiceURI,
        [Parameter (Mandatory=$True)] [System.Net.IPAddress] $IPAddress,
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackDNSPtrRecord"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask...: $WaitForTask"
        Write-Debug -Message "ServiceName...: $ServiceName"
        Write-Debug -Message "ServiceURI....: $ServiceURI"
        Write-Debug -Message "IPAddress.....: $IPAddress"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.RemovePtrRecordsAsync($ServiceName, $ServiceURI, $IPAddress, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.RemovePtrRecordsAsync($ServiceName, $ServiceURI, $IPAddress, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove Ptr record(s).

 .DESCRIPTION
 The Remove-OpenStackDNSPtrRecord cmdlet allows you to remove the Ptr record(s).

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER ServiceName
 Use this parameter to specify the name of the service.

 .PARAMETER ServiceURI
 Use this parameter to specify the URI of the service.

 .PARAMETER IPAddress
 Use this parameter to specify the IP Address.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator> 


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 42 Implement Remove-CloudDNSRecords
function Remove-OpenStackDNSRecord {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainId = $(throw "Please specify the required Domain ID by using the -DomainId parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.RecordId[]] $RecordIdList = $(throw "Please specify the required list of Record IDs by using the -RecordIdList paramter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Remove-OpenStackDNSRecord"
        Write-Debug -Message "Account.......: $Account" 
        Write-Debug -Message "UseInternalUrl: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask...: $WaitForTask"
        Write-Debug -Message "DomainId......: $DomainId"
        Write-Debug -Message "ServiceURI....: $ServiceURI"
        Write-Debug -Message "RecordIdList..: $RecordIdList"
        Write-Debug -Message "RegionOverride: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.RemoveRecordsAsync($DomainId, $RecordIdList, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.RemoveRecordsAsync($DomainId, $RecordIdList, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Remove DNS record(s).

 .DESCRIPTION
 The Remove-OpenStackDNSRecord cmdlet allows you to remove DNS record(s).

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER DomainId
 Use this parameter to specify the domain.

 .PARAMETER RecordIdList
 Use this parameter to specify the list of records to be removed.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator> 


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>}

# Issue 43 Implement Update-CloudDNSDomains
function Update-OpenStackDNSDomain {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DNSDomainUpdateConfiguration[]] $DNSDomainUpdateConfigurationList = $(throw "Please specify required list of DNS Domain update configurations by using the -DNSDomainUpdateConfigurationList parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackDNSRecord"
        Write-Debug -Message "Account.........................: $Account" 
        Write-Debug -Message "UseInternalUrl..................: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask.....................: $WaitForTask"
        Write-Debug -Message "DNSDomainUpdateConfigurationList: $DNSDomainUpdateConfigurationList"
        Write-Debug -Message "RegionOverride..................: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)


        if($WaitForTask) {
            $Provider.UpdateDomainsAsync($DNSDomainUpdateConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.UpdateDomainsAsync($DNSDomainUpdateConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Update DNS domain.

 .DESCRIPTION
 The Update-OpenStackDNSDomain cmdlet allows you to update the domain information.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER DNSDomainUpdateConfigurationList
 This parameter is a list of the complex, nested object of type [net.openstack.Providers.Rackspace.Object.Dns.DnsDomainUpdateConfiguration] that contains the DNS information for this process.
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator> 


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 44 Implement Update-CloudDNSPtrRecords
function Update-OpenStackDNSPtrRecord {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [string] $ServiceName = $(throw "Please specify the required Service Name by using the -ServiceName parameter"),
        [Parameter (Mandatory=$True)] [System.Uri] $DeviceResourceUri = $(throw "Please specify the required Device Resource URI by using the -DeviceResourceUri parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DnsDomainRecordUpdateConfiguration[]] $DNSDomainRecordUpdateConfigurationList = $(throw "Please specify the required list of DNS Domain record update configurations by using the -DNSDomainRecordUpdateConfigurationList parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Update-OpenStackDNSPtrRecord"
        Write-Debug -Message "Account...............................: $Account" 
        Write-Debug -Message "UseInternalUrl........................: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask...........................: $WaitForTask"
        Write-Debug -Message "ServiceName...........................: $ServiceName"
        Write-Debug -Message "DNSDomainRecordUpdateConfigurationList: $DNSDomainRecordUpdateConfigurationList"
        Write-Debug -Message "RegionOverride........................: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.UpdatePtrRecordsAsync($ServiceName, $DeviceResourceUri, $DNSDomainRecordUpdateConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.UpdatePtrRecordsAsync($ServiceName, $DeviceResourceUri, $DNSDomainRecordUpdateConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Update reverse DNS records.

 .DESCRIPTION
 The Add-OpenStackDNSRecord cmdlet allows you to update reverse DNS records for a cloud resource in the DNS service.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER ServiceName
 The name of the service which owns the cloud resource.
  
 .PARAMETER DeviceResourceUri
 The absolute URI of the cloud resource.
        
 .PARAMETER DNSDomainRecordConfigurationList
 A collection of objects of type [net.openstack.Providers.Rackspace.Objects.Dns.DnsDomainRecordConfiguration] describing the records to update.

 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator> 


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

# Issue 45
function Update-OpenStackDNSRecord {
    Param(
        [Parameter (Mandatory=$True)] [string] $Account = $(throw "Please specify required Cloud Account by using the -Account parameter"),
        [Parameter (Mandatory=$False)][bool]   $UseInternalUrl = $False,
        [Parameter (Mandatory=$False)][bool]   $WaitForTask = $False,
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DomainId] $DomainId = $(throw "Please specify the required Domain ID by using the -DomainId parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DnsDomainRecordUpdateConfiguration[]] $DNSDomainRecordUpdateConfigurationList = $(throw "Please specify the required list of DNS Domain record update configurations by using the -DNSDomainRecordUpdateConfigurationList parameter"),
        [Parameter (Mandatory=$True)] [net.openstack.Providers.Rackspace.Objects.Dns.DnsRecordType] $DNSRecordType = $(throw "Please specify the required Record Type by using the -DNSRecordType parameter"),
        [Parameter (Mandatory=$False)][string] $RegionOverride
    )

	$Provider = Get-Provider -Account $Account -RegionOverride $RegionOverride -UseInternalUrl $UseInternalUrl

    try {

        # DEBUGGING       
        Write-Debug -Message "Add-OpenStackDNSRecord"
        Write-Debug -Message "Account...............................: $Account" 
        Write-Debug -Message "UseInternalUrl........................: $UseInternalUrl" 
        Write-Debug -Message "WaitForTask...........................: $WaitForTask"
        Write-Debug -Message "DomainId..............................: $DomainId"
        Write-Debug -Message "DNSDomainRecordUpdateConfigurationList: $DNSDomainRecordUpdateConfigurationList"
        Write-Debug -Message "DNSRecordType.........................: $DNSRecordType"
        Write-Debug -Message "RegionOverride........................: $RegionOverride" 

        $CancellationToken = New-Object ([System.Threading.CancellationToken]::None)

        if($WaitForTask) {
            $Provider.UpdateRecordsAsync($DomainId, $DNSDomainRecordUpdateConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestCompleted, $CancellationToken, $null).Result
        } else {
            $Provider.UpdateRecordsAsync($DomainId, $DNSDomainRecordUpdateConfigurationList, [net.openstack.Core.AsyncCompletionOption]::RequestSubmitted, $CancellationToken, $null).Result
        }
    }
    catch {
        Invoke-Exception($_.Exception)
    }
<#
 .SYNOPSIS
 Update DNS record.

 .DESCRIPTION
 The Update-OpenStackDNSRecord cmdlet allows you to update the DNS records for a domain.

 .PARAMETER Account
 Use this parameter to indicate which account you would like to execute this request against.
 Valid choices are defined in PoshStack configuration file.

 .PARAMETER UseInternalUrl
 Use this parameter to specify whether or not an internal URL should be used when creating the DNS provider.

 .PARAMETER WaitForTask
 Use this parameter to specify whether you want to wait for the task to complete or return control to the script immediately.

 .PARAMETER DomainId
 The unique identifier associate with the domain.
 
 .PARAMETER DNSDomainRecordUpdateConfigurationList
 This parameter is a complex, nested object of type [net.openstack.Providers.Rackspace.Object.Dns.DnsDomainRecordUpdateConfiguration] that contains the complete stack of DNS information for this process.

 .PARAMETER DNSRecordType
 A parameter of type [net.openstack.Providers.Rackspace.Object.Dns.DnsRecordType] that specifies which record type is to be updated. For example, "Ptr" or "A".
 
 .PARAMETER RegionOverride
 This parameter will temporarily override the default region set in PoshStack configuration file.

 .EXAMPLE
 PS C:\Users\Administrator> 


 .LINK
 http://api.rackspace.com/api-ref-dns.html
#>
}

Export-ModuleMember -Function *
