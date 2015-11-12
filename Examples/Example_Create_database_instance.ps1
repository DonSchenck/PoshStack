Clear
Remove-Module PoshStack
Import-Module PoshStack
$NewInstance = New-OpenStackDatabaseInstance -Account rackiad -InstanceName "Microservices" -FlavorId "2" -SizeInGB 5 -WaitForTask $true
$NewDB = New-OpenStackDatabase -Account rackiad -InstanceId $NewInstance.Id -DatabaseName "MYSQL_ROR" 