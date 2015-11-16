#
# This example creates five Windows servers!
# FIVE!
# 
Clear
Remove-Module PoshStack
Import-Module PoshStack
$ack = Read-Host "WARNING: This example will create FIVE Windows servers. Continue? (Y/N)"
if ($ack.ToUpper -ne 'Y') {
	exit
}
$Servername = Read-Host 'What is the name of the server you wish to create?'
$Flavor = '5'
$Image = Get-OpenStackComputeServerImage -Account rackiad | WHERE {$_.Name -eq 'Windows Server 2012 R2'}

$meta = New-Object net.openstack.Core.Domain.Metadata
$meta.Add("first","1")
$meta.Add("second","2")
$i = 1
do {
    $i++
    $MyNewServer = New-OpenStackComputeServer -Account rackiad -ServerName $Servername -ImageId $Image[0].Id -FlavorId $Flavor -AttachToServiceNetwork $true -AttachToPublicNetwork $true
    $MyNewServer.AdminPassword
    }
while ($i -lt 5)
