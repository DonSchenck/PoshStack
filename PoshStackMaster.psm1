<############################################################################################

PoshStack
                                                       Master Module 
                                                         Version 0.1

        
Description
-----------
**TODO**


############################################################################################>

# Cloud account configuration file
#$Global:PoshStackConfigFile = $env:USERPROFILE + "\Documents\WindowsPowerShell\Modules\PoshStack\CloudAccounts.csv" 
$Global:PoshStackConfigFile = $openstackAccounts 

############################################################################################
#
# Shared cloud functions for use within module cmdlets. 
#
# This includes the central authentication cmdlets
#
############################################################################################

#function Get-OpenStackIdentityProvider {
#    [CmdletBinding()]
#    param (
#        [Parameter(Mandatory=$True)][string] $Username = $(throw "Please specify required Username with -Username parameter"),
#        [Parameter(Mandatory=$True)][string] $APIKey = $(throw "Please specify required API Key with -APIKey parameter")
#    )
#
#    # Get Identity Provider
#    $OpenStackId    = New-Object net.openstack.Core.Domain.CloudIdentity
#    $OpenStackId.Username = $Username
#    $OpenStackId.APIKey   = $APIKey
#    $cip = New-Object net.openstack.Providers.Rackspace.CloudIdentityProvider($OpenStackId)
#    Return $OpenStackId
#}

function Get-OpenStackIdentityProviderOpenStack {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)][string] $Username = $(throw "Please specify required Username with -Username parameter"),
        [Parameter(Mandatory=$True)][string] $Password = $(throw "Please specify required Password with -Password parameter"),
        [Parameter(Mandatory=$True)][net.openstack.Core.Domain.ProjectId] $ProjectId = $(throw "Please specify required ProjectId with -ProjectId parameter"),
        [Parameter(Mandatory=$True)][System.Uri] $Uri = $(throw "Please specify required Identity Endpoint Uri with -Uri parameter")
    )

    $OpenStackIdentityWithProject = New-Object net.openstack.Core.Domain.CloudIdentityWithProject
    $OpenStackIdentityWithProject.Password = $Password
    $OpenStackIdentityWithProject.Username = $Username
    $OpenStackIdentityWithProject.ProjectId = $ProjectId
            
    New-Object net.openstack.Core.Providers.CloudIdentityProvider($Uri, $OpenStackIdentityWithProject)

}

function Get-OpenStackAccount {
    <#
    Read $Global:PoshStackConfigFile then populate global account variables 
    based on value of $Global:account
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)][string] $Account = $(throw "Please specify required OpenStack Account by using the -Account parameter")
    )

    try {
        # Search $ConfigFile file for $account entry and populate temporary $conf with relevant details
        $Global:Credentials = Import-Csv $PoshStackConfigFile | Where-Object {$_.AccountName -eq $Account}

        # Raise exception if specified $account is not found in conf file
        if ($Credentials.AccountName -eq $null) {
            throw "Get-OpenStackAccount: Account `"$account`"  is not defined in the configuration (CloudAccounts.csv) file"
        }

    }
    catch {
        Invoke-Exception($_.Exception)
    }

}


function New-RandomComplexPassword ($length=12) {
    # Generate a complex password using characters from $chars

    $chars = [Char[]]"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
    $password = ($chars | Get-Random -Count $length) -join ""
    return $password
}

function Invoke-Exception {
    write-host "`nCaught an exception: $($_.Exception.Message)" -ForegroundColor Red
    write-host "Exception Type: $($_.Exception.GetType().FullName) `n" -ForegroundColor Red
    break;
}

function Show-UntestedWarning {
    Write-Host "`nWarning: This cmdlet is untested - if you proceed and find stuff not working, please provide feedback to the developers`n" -ForegroundColor Yellow
    $okToContinue = Read-Host "Are you happy to continue? (type `"yes`" to continue)"
    if ($okToContinue -ne "yes")
    {
        Write-Host "`n --- You didn't enter yes - quitting`n`n"
        break;
    }
    else
    {
        Write-Host "`n --- Excellent, hang-on to your...`n"
    }
}

function Show-OpenStackAccounts {
    Import-Csv $Global:PoshStackConfigFile | ft -AutoSize

<#
 .SYNOPSIS
 Display all configured cloud accounts that are avaialble to use.

 .DESCRIPTION
 The Show-CloudAccounts cmdlet will simply display a list of all cloud accounts, which have been configured in the $Global:PoshStackConfigFile.
 
 .EXAMPLE
 PS H:\> Show-CloudAccounts

 AccountName CloudUsername  CloudAPIKey                      CloudDDI Region
 ----------- -------------  -----------                      -------- ------
 prod        cloudProd      awefsrw2w34rf214aff46d3b9a73c6b0 11111111 LON   
 dev         cloudDev       9c2a200od18303ab763wt34gsd4bdb70 00000000 IAD 

#>
}

Export-ModuleMember -Function *