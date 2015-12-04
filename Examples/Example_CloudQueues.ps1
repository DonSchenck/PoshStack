Import-Module PoshStack

$myMetadata = @{}
$myMetadata.Add("Hello","World")
$myMetadata.Add("Foo","Bar")
#New-OpenStackCloudQueue -Account rackiad -QueueName "queuename" -RegionOverride IAD
#Get-OpenStackCloudQueue -Account rackiad -RegionOverride IAD
#Set-OpenStackCloudQueueMetadata -Account rackiad -QueueName "queuename" -Metadata $myMetadata -RegionOverride IAD
#$md = Get-OpenStackCloudQueueMetadata -Account rackiad -QueueName "queuename" -RegionOverride IAD
#ForEach($metadata in $md) {
#    Write-Host $metadata.keys
#    Write-Host $metadata.Values
#}
$TTL = New-Object ([TimeSpan]) 4,0,0
$listofmsgs = @()
$listofmsgs += "Hello world"
$listofmsgs += "Second message"
#Write-OpenStackCloudQueueMessage -Account rackiad -QueueName "queuename" -TTL $TTL -ListOfMessages $listofmsgs -RegionOverride IAD
#$readmessages = Read-OpenStackCloudQueueMessage -Account rackiad -Queuename "queuename" -TTL $TTL -GracePeriod $TTL -NumberToRetrieve 4 -RegionOverride IAD
#Write-Host $readmessages.Messages.Count
#ForEach($m in $readmessages.Messages) {
#      Write-Host "body " $m.Body.ToString()
#}
$listOfMessages = Get-OpenStackCloudQueueMessage -Account rackiad -QueueName "queuename"
ForEach($cqm in $listOfMessages) {
    Write-Host "MessageID: " $cqm.Id
}

Remove-OpenStackCloudQueueMessage -Account rackiad -QueueName "queuename" -ListOfMessageId